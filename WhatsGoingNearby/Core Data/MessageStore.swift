//
//  MessageStore.swift
//  WhatsGoingNearby
//
//  Cache local das mensagens de cada conversa.
//

import Foundation
import CoreData

/// Cache local das mensagens.
///
/// Só persiste mensagens já confirmadas pelo servidor. Envios em andamento e falhos vivem
/// apenas em memória: guardá-los seria o começo de uma fila de envio offline, que está
/// fora deste escopo, e traria de volta ids temporários no cache.
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

    //MARK: - Escrita

    /// Insere ou atualiza mensagens, deduplicando pelo id.
    ///
    /// Serve a todos os caminhos — histórico, paginação, socket e confirmação de envio —
    /// porque é chamado de dentro do funil único do view model.
    func upsert(_ messages: [MessageIntermediary], chatId: String) {
        let confirmed = messages.filter { $0.status == nil || $0.status == .sent }
        guard !confirmed.isEmpty else { return }

        let context = persistence.viewContext
        let chat = fetchChat(chatId: chatId, in: context)
        var byId = existingMessages(withIds: confirmed.map { $0.id }, in: context)

        for message in confirmed {
            let entity = byId[message.id] ?? CDMessage(context: context)
            entity.apply(message)
            // O relacionamento é o que faz apagar a conversa levar as mensagens junto.
            entity.chat = chat
            byId[message.id] = entity
        }

        persistence.save()
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
        request.predicate = NSPredicate(
            format: "chatId == %@ AND createdAt >= %lld AND createdAt <= %lld",
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
            // Vindo do cache, a mensagem já está confirmada pelo servidor.
            status: .sent,
            image: nil,
            isCurrentUser: self.isCurrentUser
        )
    }
}
