//
//  MessageStore.swift
//  WhatsGoingNearby
//
//  Cache local das mensagens de cada conversa.
//

import Foundation
import CoreData
import UIKit

/// Cache local das mensagens.
///
/// Guarda também o que ainda não foi confirmado pelo servidor: a mensagem que falhou continua na
/// conversa depois de fechar o app, com a opção de reenviar, em vez de desaparecer sem aviso.
/// Mensagem não confirmada carrega id temporário — quem reconcilia precisa saber disso, porque o
/// servidor nunca vai devolver esse id.
@MainActor
final class MessageStore {

    static let shared = MessageStore()

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    //MARK: - Leitura

    /// Mensagens em cache da conversa, em ordem cronológica — a mesma que a tela espera.
    func loadMessages(chatId: String) -> [MessageIntermediary] {
        let request = CDMessage.fetchRequest()
        request.predicate = NSPredicate(format: "chatId == %@", chatId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMessage.createdAt, ascending: true)]

        do {
            return try persistence.viewContext.fetch(request).map { $0.toIntermediary() }
        } catch {
            print("❌ Não foi possível ler as mensagens em cache: \(error)")
            return []
        }
    }

    /// Mensagens que não chegaram ao servidor, em ordem cronológica.
    ///
    /// Sem `chatId`, varre todas as conversas — é assim que a retomada encontra o que ficou para
    /// trás sem precisar que a tela de cada conversa tenha sido aberta.
    func loadFailedMessages(chatId: String? = nil) -> [MessageIntermediary] {
        let request = CDMessage.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMessage.createdAt, ascending: true)]
        request.predicate = chatId.map {
            NSPredicate(format: "chatId == %@ AND status == %@", $0, MessageStatus.failed.rawValue)
        } ?? NSPredicate(format: "status == %@", MessageStatus.failed.rawValue)

        return ((try? persistence.viewContext.fetch(request)) ?? []).map { $0.toIntermediary() }
    }

    func status(ofMessageWithId messageId: String) -> MessageStatus? {
        let request = CDMessage.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", messageId)
        request.fetchLimit = 1

        guard let entity = (try? persistence.viewContext.fetch(request))?.first else { return nil }
        return entity.status.flatMap { MessageStatus(rawValue: $0) }
    }

    //MARK: - Escrita

    /// Insere ou atualiza mensagens, deduplicando pelo id.
    ///
    /// Serve a todos os caminhos — histórico, paginação, socket e confirmação de envio —
    /// porque é chamado de dentro do funil único do view model.
    func upsert(_ messages: [MessageIntermediary], chatId: String) {
        guard !messages.isEmpty else { return }

        let context = persistence.viewContext
        let chat = fetchChat(chatId: chatId, in: context)
        var byId = existingMessages(withIds: messages.map { $0.id }, in: context)

        for message in messages {
            let entity = byId[message.id] ?? CDMessage(context: context)
            entity.apply(message)
            entity.pendingImageFileName = persistedImageName(for: message, existing: entity.pendingImageFileName, chatId: chatId)
            // O relacionamento é o que faz apagar a conversa levar as mensagens junto.
            entity.chat = chat
            byId[message.id] = entity
        }

        persistence.save()
    }

    /// Nome do arquivo da foto de uma mensagem que ainda não foi enviada.
    ///
    /// Só mensagem não confirmada precisa dos bytes: assim que o servidor devolve a `imageUrl`, a
    /// foto passa a vir da rede com o cache de disco do Kingfisher, e o arquivo local vira peso
    /// morto. Gravar é feito uma vez só — a mensagem já guardada reaproveita o arquivo, senão cada
    /// mudança de status reescreveria o JPEG.
    private func persistedImageName(for message: MessageIntermediary, existing: String?, chatId: String) -> String? {
        let isConfirmed = message.status == nil || message.status == .sent

        guard !isConfirmed, let image = message.image else {
            if let existing {
                LocalImageStore.pendingMessages.delete(named: existing, chatId: chatId)
            }
            return nil
        }

        return existing ?? LocalImageStore.pendingMessages.write(image, chatId: chatId)
    }

    /// Reconcilia as exclusões feitas no servidor enquanto o app estava fora.
    ///
    /// A API devolve uma janela contígua do histórico, então a página é a verdade completa
    /// para o intervalo entre a mais antiga e a mais nova que vieram nela. O que está em
    /// cache dentro desse intervalo e não veio na página foi apagado no servidor.
    ///
    /// É o que substitui um endpoint de tombstones, que a API não tem.
    /// Devolve os ids removidos, para quem chamou tirá-los também da lista em memória —
    /// senão a mensagem sumiria do cache mas continuaria na tela até reabrir a conversa.
    @discardableResult
    func reconcileDeletions(within page: [MessageIntermediary], chatId: String) -> [String] {
        let timestamps = page.map { $0.createdAt }
        guard let oldest = timestamps.min(), let newest = timestamps.max() else { return [] }

        let context = persistence.viewContext
        let request = CDMessage.fetchRequest()
        // `status == nil` é a mensagem confirmada: só ela pode ser comparada com a página. As não
        // confirmadas têm id temporário, que o servidor nunca devolve — sem este filtro, toda
        // mensagem por enviar seria tomada por apagada e varrida na primeira sincronização.
        request.predicate = NSPredicate(
            format: "chatId == %@ AND createdAt >= %lld AND createdAt <= %lld AND status == nil",
            chatId, Int64(oldest), Int64(newest)
        )

        let survivingIds = Set(page.map { $0.id })
        let cached = (try? context.fetch(request)) ?? []

        var removedIds: [String] = []
        for entity in cached where !survivingIds.contains(entity.id ?? "") {
            removedIds.append(entity.id ?? "")
            context.delete(entity)
        }

        guard !removedIds.isEmpty else { return [] }
        persistence.save()
        return removedIds
    }

    func delete(messageId: String) {
        let context = persistence.viewContext
        let request = CDMessage.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", messageId)
        request.fetchLimit = 1

        guard let entity = (try? context.fetch(request))?.first else { return }

        if let fileName = entity.pendingImageFileName, let chatId = entity.chatId {
            LocalImageStore.pendingMessages.delete(named: fileName, chatId: chatId)
        }

        context.delete(entity)
        persistence.save()
    }


    //MARK: - Private

    private func fetchChat(chatId: String, in context: NSManagedObjectContext) -> CDChat? {
        let request = CDChat.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", chatId)
        request.fetchLimit = 1

        return (try? context.fetch(request))?.first
    }

    /// Busca em lote as mensagens que já existem, para o upsert não fazer uma consulta por
    /// mensagem ao inserir uma página inteira.
    private func existingMessages(withIds ids: [String], in context: NSManagedObjectContext) -> [String: CDMessage] {
        let request = CDMessage.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)

        let found = (try? context.fetch(request)) ?? []
        return Dictionary(found.map { ($0.id ?? "", $0) }, uniquingKeysWith: { first, _ in first })
    }
}

//MARK: - Conversão

extension CDMessage {

    func apply(_ message: MessageIntermediary) {
        self.id = message.id
        self.chatId = message.chatId
        self.text = message.text
        // Só a URL: os bytes ficam com o Kingfisher, que já tem cache em disco.
        self.imageUrl = message.imageUrl
        self.isRead = message.isRead
        self.createdAt = Int64(message.createdAt)
        self.repliedMessageId = message.repliedMessageId
        self.repliedMessageText = message.repliedMessageText
        self.isCurrentUser = message.isCurrentUser
        // Confirmada não guarda status: é o valor ausente que a distingue no filtro da
        // reconciliação de exclusões, e o que mantém compatível a mensagem já em cache.
        let isConfirmed = message.status == nil || message.status == .sent
        self.status = isConfirmed ? nil : message.status?.rawValue
    }

    func toIntermediary() -> MessageIntermediary {
        MessageIntermediary(
            id: self.id ?? "",
            chatId: self.chatId ?? "",
            text: self.text,
            imageUrl: self.imageUrl,
            isRead: self.isRead,
            createdAt: Int(self.createdAt),
            repliedMessageId: self.repliedMessageId,
            repliedMessageText: self.repliedMessageText,
            // Sem status guardado, a mensagem veio confirmada do servidor. Com status, ela ficou
            // pelo caminho — e volta como falha, nunca como `sending`: o envio que a acompanhava
            // morreu junto com o processo, então mostrar um progresso que ninguém está tocando
            // deixaria o usuário esperando por algo que não vai acontecer.
            status: self.status == nil ? .sent : .failed,
            image: pendingImage(),
            isCurrentUser: self.isCurrentUser
        )
    }

    private func pendingImage() -> UIImage? {
        guard let fileName = self.pendingImageFileName, let chatId = self.chatId else { return nil }
        return LocalImageStore.pendingMessages.load(named: fileName, chatId: chatId)
    }
}
