//
//  ChatStore.swift
//  WhatsGoingNearby
//
//  Cache local da lista de conversas.
//

import Foundation
import CoreData

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

    //MARK: - Private

    private func fetchAll(in context: NSManagedObjectContext) -> [CDChat] {
        (try? context.fetch(CDChat.fetchRequest())) ?? []
    }

    private func fetch(chatId: String, in context: NSManagedObjectContext) -> CDChat? {
        let request = CDChat.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", chatId)
        request.fetchLimit = 1

        return (try? context.fetch(request))?.first
    }
}

//MARK: - Conversão

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
