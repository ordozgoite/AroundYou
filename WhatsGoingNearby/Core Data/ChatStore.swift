//
//  ChatStore.swift
//  WhatsGoingNearby
//
//  Cache local da lista de conversas.
//

import Foundation
import CoreData
import UIKit

/// O que o usuário escreveu numa conversa e ainda não enviou.
struct ChatDraft: Equatable {
    var text: String?
    var repliedMessageId: String?
    /// Nomes dos arquivos das imagens anexadas, na ordem em que aparecem no composer.
    ///
    /// Só os nomes: os bytes ficam em disco, fora do Core Data. Guardá-los na mesma base das
    /// mensagens incharia o store e obrigaria a converter `Data` na main thread a cada leitura.
    var imageFileNames: [String] = []

    var isEmpty: Bool {
        return text == nil && repliedMessageId == nil && imageFileNames.isEmpty
    }
}

/// Cache local das conversas.
///
/// O servidor segue sendo a fonte autoritativa; isto aqui é a fonte *imediata*, para a tela
/// ter o que mostrar antes de qualquer resposta de rede.
@MainActor
final class ChatStore {

    static let shared = ChatStore()

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    //MARK: - Leitura

    /// Conversas em cache, já na ordem em que a tela as exibe.
    func loadChats() -> [FormattedChat] {
        let request = CDChat.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDChat.lastMessageAt, ascending: false)]

        do {
            return try persistence.viewContext.fetch(request).map { $0.toFormattedChat() }
        } catch {
            print("❌ Não foi possível ler as conversas em cache: \(error)")
            return []
        }
    }

    //MARK: - Escrita

    /// Reconcilia o cache com a lista que o servidor devolveu.
    ///
    /// O endpoint entrega a lista completa do usuário, então a ausência de um chat é
    /// informação: ele foi apagado e sai do cache. As mensagens dele vão junto, por cascade.
    ///
    /// Não é apagar tudo e reinserir — os que continuam existindo são atualizados no lugar,
    /// preservando as mensagens já persistidas e os `NSManagedObjectID`.
    func reconcile(with chats: [FormattedChat]) {
        let context = persistence.viewContext
        let existing = fetchAll(in: context)
        var byId = Dictionary(existing.map { ($0.id ?? "", $0) }, uniquingKeysWith: { first, _ in first })

        for chat in chats {
            let entity = byId.removeValue(forKey: chat.id) ?? CDChat(context: context)
            entity.apply(chat)
        }

        // O que sobrou não veio do servidor: não existe mais.
        for orphan in byId.values {
            context.delete(orphan)
        }

        pruneDrafts(keeping: Set(chats.map { $0.id }), in: context)

        persistence.save()
    }

    /// Atualiza um único chat sem tocar no resto — usado por mute/unmute, que respondem
    /// só por aquele registro e não devem provocar uma reconciliação inteira.
    func update(chatId: String, isMuted: Bool) {
        let context = persistence.viewContext
        guard let entity = fetch(chatId: chatId, in: context) else { return }

        entity.isMuted = isMuted
        persistence.save()
    }

    func delete(chatId: String) {
        let context = persistence.viewContext
        guard let entity = fetch(chatId: chatId, in: context) else { return }

        context.delete(entity)
        persistence.save()
    }

    //MARK: - Rascunho

    /// O que o usuário estava escrevendo numa conversa e ainda não enviou.
    ///
    /// Vive em entidade própria, e não como atributo de `CDChat`, porque a conversa pode ser aberta
    /// antes de existir no cache: quem chega pelo Discover ou por uma notificação abre a tela sem a
    /// lista de conversas ter sincronizado, e o rascunho não teria onde ser gravado.
    func loadDraft(chatId: String) -> ChatDraft? {
        guard let entity = fetchDraft(chatId: chatId, in: persistence.viewContext) else { return nil }

        return entity.toDraft()
    }

    /// Todos os rascunhos, indexados por conversa.
    ///
    /// Uma consulta só: a lista de conversas precisa deles de uma vez, e perguntar por conversa
    /// custaria uma ida ao Core Data por linha desenhada.
    func loadDrafts() -> [String: ChatDraft] {
        let drafts = (try? persistence.viewContext.fetch(CDDraft.fetchRequest())) ?? []

        return Dictionary(
            drafts.compactMap { entity -> (String, ChatDraft)? in
                guard let chatId = entity.chatId else { return nil }
                return (chatId, entity.toDraft())
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// Grava o rascunho, ou apaga o registro quando não sobrou nada para guardar.
    func saveDraft(_ draft: ChatDraft, chatId: String) {
        let context = persistence.viewContext
        let existing = fetchDraft(chatId: chatId, in: context)

        guard !draft.isEmpty else {
            guard let existing else { return }
            context.delete(existing)
            persistence.save()
            return
        }

        let entity = existing ?? CDDraft(context: context)
        entity.chatId = chatId
        entity.text = draft.text
        entity.repliedMessageId = draft.repliedMessageId
        entity.imageFileNames = draft.imageFileNames.isEmpty ? nil : draft.imageFileNames.joined(separator: Self.imageNameSeparator)
        entity.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)

        persistence.save()
    }

    func deleteDraft(chatId: String) {
        deleteDraftImages(chatId: chatId)

        let context = persistence.viewContext
        guard let entity = fetchDraft(chatId: chatId, in: context) else { return }

        context.delete(entity)
        persistence.save()
    }

    //MARK: - Imagens do rascunho

    /// Separador dos nomes de arquivo. Os nomes são UUIDs, então nunca contêm este caractere.
    fileprivate static let imageNameSeparator = ","

    /// Grava a imagem e devolve o nome do arquivo, ou `nil` se não foi possível escrever.
    ///
    /// A mesma compressão usada no envio: o rascunho não deve guardar uma imagem melhor do que a
    /// que seria enviada a partir dele.
    func writeDraftImage(_ image: UIImage, chatId: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8),
              let directory = draftImageDirectory(chatId: chatId, creatingIfNeeded: true)
        else { return nil }

        let fileName = "\(UUID().uuidString).jpg"

        do {
            try data.write(to: directory.appendingPathComponent(fileName), options: .completeFileProtectionUntilFirstUserAuthentication)
            return fileName
        } catch {
            print("❌ Não foi possível gravar a imagem do rascunho: \(error)")
            return nil
        }
    }

    func loadDraftImage(named fileName: String, chatId: String) -> UIImage? {
        guard let directory = draftImageDirectory(chatId: chatId, creatingIfNeeded: false),
              let data = try? Data(contentsOf: directory.appendingPathComponent(fileName))
        else { return nil }

        return UIImage(data: data)
    }

    func deleteDraftImage(named fileName: String, chatId: String) {
        guard let directory = draftImageDirectory(chatId: chatId, creatingIfNeeded: false) else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
    }

    func deleteDraftImages(chatId: String) {
        guard let directory = draftImageDirectory(chatId: chatId, creatingIfNeeded: false) else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    //MARK: - Private

    /// Descarta rascunhos de conversas que o servidor não devolveu mais.
    ///
    /// O `Cascade` de `CDChat` não alcança o rascunho, que é uma entidade solta de propósito — sem
    /// esta varredura, apagar uma conversa deixaria o rascunho dela para trás para sempre.
    private func pruneDrafts(keeping chatIds: Set<String>, in context: NSManagedObjectContext) {
        let request = CDDraft.fetchRequest()
        let drafts = (try? context.fetch(request)) ?? []

        for draft in drafts where !chatIds.contains(draft.chatId ?? "") {
            if let chatId = draft.chatId {
                deleteDraftImages(chatId: chatId)
            }
            context.delete(draft)
        }
    }

    /// Pasta das imagens do rascunho desta conversa.
    ///
    /// Fica em Application Support, e não em Caches, que o sistema pode esvaziar a qualquer
    /// momento — um rascunho que some sozinho é pior do que rascunho nenhum. Como o conteúdo é
    /// transitório e reproduzível pelo usuário, é excluído do backup do iCloud.
    private func draftImageDirectory(chatId: String, creatingIfNeeded: Bool) -> URL? {
        guard let support = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ) else { return nil }

        var directory = support.appendingPathComponent("ChatDrafts", isDirectory: true)
            .appendingPathComponent(chatId, isDirectory: true)

        guard creatingIfNeeded else {
            return FileManager.default.fileExists(atPath: directory.path) ? directory : nil
        }

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? directory.setResourceValues(resourceValues)
            return directory
        } catch {
            print("❌ Não foi possível criar a pasta do rascunho: \(error)")
            return nil
        }
    }

    private func fetchAll(in context: NSManagedObjectContext) -> [CDChat] {
        (try? context.fetch(CDChat.fetchRequest())) ?? []
    }

    private func fetch(chatId: String, in context: NSManagedObjectContext) -> CDChat? {
        let request = CDChat.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", chatId)
        request.fetchLimit = 1

        return (try? context.fetch(request))?.first
    }

    private func fetchDraft(chatId: String, in context: NSManagedObjectContext) -> CDDraft? {
        let request = CDDraft.fetchRequest()
        request.predicate = NSPredicate(format: "chatId == %@", chatId)
        request.fetchLimit = 1

        return (try? context.fetch(request))?.first
    }
}

//MARK: - Conversão

extension CDDraft {

    func toDraft() -> ChatDraft {
        ChatDraft(
            text: self.text,
            repliedMessageId: self.repliedMessageId,
            imageFileNames: self.imageFileNames?
                .components(separatedBy: ChatStore.imageNameSeparator)
                .filter { !$0.isEmpty } ?? []
        )
    }
}

extension CDChat {

    func apply(_ chat: FormattedChat) {
        self.id = chat.id
        self.chatName = chat.chatName
        self.otherUserUid = chat.otherUserUid
        self.chatPic = chat.chatPic
        self.lastMessage = chat.lastMessage
        // Zero representa "sem mensagem": guardar Int64 opcional obrigaria a NSNumber e a
        // desempacotar em todo lugar, sem ganho nenhum.
        self.lastMessageAt = Int64(chat.lastMessageAt ?? 0)
        self.hasUnreadMessages = chat.hasUnreadMessages
        self.isMuted = chat.isMuted
        self.isLocked = chat.isLocked
    }

    func toFormattedChat() -> FormattedChat {
        FormattedChat(
            id: self.id ?? "",
            chatName: self.chatName ?? "",
            otherUserUid: self.otherUserUid ?? "",
            chatPic: self.chatPic,
            lastMessageAt: self.lastMessageAt == 0 ? nil : Int(self.lastMessageAt),
            hasUnreadMessages: self.hasUnreadMessages,
            lastMessage: self.lastMessage,
            isMuted: self.isMuted,
            isLocked: self.isLocked
        )
    }
}
