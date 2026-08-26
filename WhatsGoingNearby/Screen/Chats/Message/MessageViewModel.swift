//
//  MessageViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseStorage
import AVFoundation

/// Origem de uma mesclagem, usada apenas para log e para decidir o auto-scroll.
enum MessageMergeSource: String {
    case history
    case pagination
    case socket
    case local
}

@MainActor
class MessageViewModel: ObservableObject {

    private var audioPlayer: AVAudioPlayer?
    private var receivedMessageIds: Set<String> = []

    /// Uma busca de histórico por vez.
    @Published private(set) var isLoadingOlderMessages = false
    /// Falso assim que uma página volta vazia: daí em diante não há o que buscar.
    @Published private(set) var hasMoreOlderMessages = true

    /// Incrementado a cada leva do servidor que deve reposicionar a conversa no fim: a
    /// abertura da conversa e o toque numa notificação dela.
    ///
    /// A conversa nasce posicionada no fim do que estava em cache. Quando essa leva traz
    /// mensagens mais novas — o caso de quem chegou por uma notificação, com o cache parado
    /// no que havia antes dela — o fim da conversa mudou de lugar depois do posicionamento
    /// inicial, e a rolagem precisa acompanhar.
    ///
    /// É um contador, e não um sinalizador: a segunda notificação da mesma conversa é um
    /// pedido tão legítimo quanto a primeira.
    @Published private(set) var repositioningSyncCount = 0

    /// Avisado imediatamente antes de inserir uma página antiga, ainda no mesmo ciclo, para
    /// quem precisa fotografar a posição da rolagem antes do conteúdo crescer.
    var willPrependOlderMessages: (() -> Void)?

    /// Identificador desta tela junto ao `SocketService`, para registrar e remover
    /// apenas os listeners que pertencem a ela.
    let listenerOwner = "chat-\(UUID().uuidString)"

    private let messageStore: MessageStore
    private let chatStore: ChatStore

    init(messageStore: MessageStore = .shared, chatStore: ChatStore = .shared) {
        self.messageStore = messageStore
        self.chatStore = chatStore
    }

    /// Coloca na tela o que já está em cache, antes de qualquer requisição.
    ///
    /// Não é um merge: roda com a lista vazia, na abertura da conversa. Se não houver nada
    /// guardado, a tela segue exatamente como antes, esperando a rede.
    func loadCachedMessages(chatId: String) {
        guard intermediaryMessages.isEmpty else { return }

        let cached = messageStore.loadMessages(chatId: chatId)
        guard !cached.isEmpty else { return }

        intermediaryMessages = cached
        RealtimeLog.apiSync(source: "cache", pages: 0, fetched: cached.count)
    }

    @Published var formattedMessages: [FormattedMessage] = []
    @Published var intermediaryMessages: [MessageIntermediary] = [] {
        didSet {
            formatMessages()
        }
    }
    @Published var receivedMessages: [Message] = []
    @Published var messagesToBePersisted: [FormattedMessage] = []
    
    @Published var messageText: String = ""
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var repliedMessage: FormattedMessage?
    @Published var messageTimer: Timer?
    @Published var highlightedMessageId: String?
    @Published var lastMessageAdded: String?
    
    @Published var images: [UIImage] = []
    @Published var isCameraDisplayed = false
    @Published var isPhotosDisplayed = false
    
    func removeImage(fromIndex index: Int) {
        guard index < images.count else { return }
        self.images.remove(at: index)
    }

    //MARK: - Draft

    /// Uma gravação pendente por conversa: cada tecla cancela a anterior.
    private var draftSaveTask: Task<Void, Never>?

    /// Vínculo entre a imagem em memória e o arquivo já gravado para ela.
    ///
    /// É o que impede o debounce do texto de reescrever os JPEGs a cada tecla: a imagem que já tem
    /// arquivo é reaproveitada, e só entra em disco a que acabou de ser escolhida. `UIImage` é
    /// classe, então a identidade do objeto serve de chave — as instâncias que o picker cria
    /// sobrevivem intactas às operações no array.
    private var draftImageFiles: [ObjectIdentifier: String] = [:]

    /// Devolve ao composer o que ficou escrito e não foi enviado.
    ///
    /// Roda depois de `loadCachedMessages` de propósito: a citação é restaurada procurando a
    /// mensagem original entre as que já estão em tela. Se ela não estiver mais ali — apagada, ou
    /// antiga demais para o cache —, o texto volta sozinho e a citação é descartada, em vez de
    /// exibir uma prévia que aponta para o nada.
    func loadDraft(chatId: String) {
        guard messageText.isEmpty, repliedMessage == nil else { return }
        guard let draft = chatStore.loadDraft(chatId: chatId) else { return }

        if let text = draft.text {
            messageText = text
        }
        if let repliedMessageId = draft.repliedMessageId {
            repliedMessage = formattedMessages.first { $0.id == repliedMessageId }
        }
        restoreDraftImages(draft.imageFileNames, chatId: chatId)
    }

    /// Devolve ao composer os anexos do rascunho, ignorando arquivo que não abriu.
    ///
    /// O vínculo imagem↔arquivo é refeito aqui: sem ele, a primeira gravação depois de restaurar
    /// trataria toda imagem como nova e reescreveria tudo.
    private func restoreDraftImages(_ fileNames: [String], chatId: String) {
        guard images.isEmpty, !fileNames.isEmpty else { return }

        var restored: [UIImage] = []
        var files: [ObjectIdentifier: String] = [:]

        for fileName in fileNames {
            guard let image = chatStore.loadDraftImage(named: fileName, chatId: chatId) else { continue }
            restored.append(image)
            files[ObjectIdentifier(image)] = fileName
        }

        images = restored
        draftImageFiles = files
    }

    /// Agenda a gravação do rascunho, adiando enquanto o usuário ainda estiver digitando.
    ///
    /// Gravar a cada tecla seria um `save` do Core Data por caractere, na main thread. O atraso é
    /// curto o bastante para que sair da tela logo depois de digitar ainda encontre o `flushDraft`
    /// do `onDisappear`, que grava sem esperar.
    func scheduleDraftSave(chatId: String) {
        draftSaveTask?.cancel()
        draftSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            self?.persistDraft(chatId: chatId)
        }
    }

    /// Grava o rascunho agora, sem esperar o debounce.
    ///
    /// `composedText` chega preenchido quando havia ditado em andamento: o `@Published` pode estar
    /// atrás do campo, e o texto real vem do próprio `UITextInput`.
    func flushDraft(chatId: String, composedText: String? = nil) {
        draftSaveTask?.cancel()
        if let composedText {
            messageText = composedText
        }
        persistDraft(chatId: chatId)
    }

    private func persistDraft(chatId: String) {
        let draft = ChatDraft(
            text: messageText.nonEmptyOrNil(),
            repliedMessageId: repliedMessage?.id,
            imageFileNames: syncDraftImages(chatId: chatId)
        )
        chatStore.saveDraft(draft, chatId: chatId)
    }

    /// Alinha os arquivos em disco com as imagens que estão no composer agora.
    ///
    /// Grava só o que ainda não tem arquivo e apaga o que saiu do composer, devolvendo os nomes na
    /// ordem em que as imagens aparecem — é essa ordem que o rascunho precisa reproduzir.
    private func syncDraftImages(chatId: String) -> [String] {
        var fileNames: [String] = []
        var files: [ObjectIdentifier: String] = [:]

        for image in images {
            let key = ObjectIdentifier(image)
            guard let fileName = draftImageFiles[key] ?? chatStore.writeDraftImage(image, chatId: chatId) else { continue }
            fileNames.append(fileName)
            files[key] = fileName
        }

        for (key, fileName) in draftImageFiles where files[key] == nil {
            chatStore.deleteDraftImage(named: fileName, chatId: chatId)
        }

        draftImageFiles = files
        return fileNames
    }

    private func discardDraft(chatId: String) {
        draftSaveTask?.cancel()
        draftImageFiles = [:]
        chatStore.deleteDraft(chatId: chatId)
    }
    
    //MARK: - Fetch Messages

    /// Reserva a paginação de forma síncrona.
    ///
    /// O gatilho do scroll infinito vem da posição da rolagem, que é avaliada a cada quadro.
    /// Reservar antes de qualquer suspensão é o que impede que meia dúzia de quadros
    /// seguidos abram a mesma requisição.
    func beginLoadingOlderMessages() -> Bool {
        guard !isLoadingOlderMessages, hasMoreOlderMessages, !intermediaryMessages.isEmpty else {
            return false
        }
        isLoadingOlderMessages = true
        return true
    }

    /// Devolve a reserva quando a busca nem chega a sair (falha ao obter o token, por ex.).
    func cancelLoadingOlderMessages() {
        isLoadingOlderMessages = false
    }

    /// Carrega a página anterior à mensagem mais antiga já conhecida.
    /// Exige uma reserva prévia via `beginLoadingOlderMessages()`.
    func loadOlderMessages(chatId: String, token: String) async {
        defer { isLoadingOlderMessages = false }

        let result = await AYServices.shared.getMessages(chatId: chatId, timestamp: oldestKnownTimestamp(), token: token)

        switch result {
        case .success(let messages):
            // O fim do histórico é uma página vazia. O tamanho da página não serve de
            // critério: o limite é do servidor e o cliente não o conhece.
            hasMoreOlderMessages = !messages.isEmpty
            guard !messages.isEmpty else { return }

            willPrependOlderMessages?()
            let converted = convertReceivedMessages(messages)
            merge(converted, source: .pagination)
            applyServerDeletions(within: converted, chatId: chatId)
            RealtimeLog.apiSync(source: MessageMergeSource.pagination.rawValue, pages: 1, fetched: messages.count)
        case .failure:
            RealtimeLog.apiSyncFailure(source: MessageMergeSource.pagination.rawValue)
            overlayError = (true, ErrorMessage.getMessages)
        }
    }

    /// Carrega a página mais recente e a mescla ao que já está em tela.
    ///
    /// Antes esta chamada substituía o array inteiro, o que apagava as mensagens recebidas
    /// pelo socket durante a requisição e as mensagens locais ainda em envio. Agora ela é
    /// aditiva e serve também como mecanismo de reconciliação: se houver uma lacuna entre
    /// a mensagem mais nova conhecida e a página retornada — sinal de que mensagens se
    /// perderam durante uma desconexão — páginas anteriores são buscadas até fechá-la.
    func getLastMessages(chatId: String, token: String, source: String = MessageMergeSource.history.rawValue) async {
        let newestKnown = newestServerTimestamp()
        var cursor: Int? = nil
        var pages = 0
        var fetched = 0

        while pages < Constants.MAX_MESSAGE_RECONCILIATION_PAGES {
            let result = await AYServices.shared.getMessages(chatId: chatId, timestamp: cursor, token: token)

            guard case .success(let messages) = result else {
                RealtimeLog.apiSyncFailure(source: source)
                overlayError = (true, ErrorMessage.getMessages)
                return
            }

            pages += 1
            fetched += messages.count

            let converted = convertReceivedMessages(messages)
            merge(converted, source: cursor == nil ? .history : .pagination)
            applyServerDeletions(within: converted, chatId: chatId)

            guard let newestKnown,
                  let oldestFetched = converted.map({ $0.createdAt }).min(),
                  oldestFetched > newestKnown
            else { break }

            RealtimeLog.gapDetected(source: source)
            cursor = oldestFetched
        }

        RealtimeLog.apiSync(source: source, pages: pages, fetched: fetched)

        // Só a abertura da conversa e o toque numa notificação dela reposicionam a rolagem.
        // Um resync no meio da leitura usa esta mesma busca, e ali arrastar o usuário para o
        // fim seria tirá-lo de onde ele está lendo.
        if source == MessageMergeSource.history.rawValue {
            repositioningSyncCount += 1
        }
    }

    private func convertReceivedMessages(_ messages: [Message]) -> [MessageIntermediary] {
        var convertedMessages: [MessageIntermediary] = []
        for message in messages {
            let intermediaryMessage = message.convertMessageToIntermediary(forCurrentUserUid: LocalState.currentUserUid)
            convertedMessages.append(intermediaryMessage)
        }
        return convertedMessages
    }

    /// Timestamp da mensagem mais antiga conhecida, usado como cursor de paginação.
    private func oldestKnownTimestamp() -> Int? {
        return intermediaryMessages.first(where: { isServerConfirmed($0) })?.createdAt
    }

    /// Timestamp da mensagem mais nova já confirmada pelo servidor.
    ///
    /// Mensagens locais em envio não contam: elas ainda não representam nada que o
    /// servidor conheça e não podem servir de marca d'água para detectar lacunas.
    private func newestServerTimestamp() -> Int? {
        return intermediaryMessages.last(where: { isServerConfirmed($0) })?.createdAt
    }

    private func isServerConfirmed(_ message: MessageIntermediary) -> Bool {
        return message.status == nil || message.status == .sent
    }

    //MARK: - Send Message
    
    func sendMessage(forChat chatId: String, text: String?, images: [UIImage], repliedMessage: FormattedMessage?, token: String) async throws {
        resetInputs()
        // O que saiu do composer deixa de ser rascunho, mesmo que o envio ainda venha a falhar: a
        // mensagem já está na conversa, e restaurá-la no campo depois a mostraria duas vezes.
        discardDraft(chatId: chatId)
        let messagesToBeSent = getMessagesToBeSent(chatId: chatId, text: text, images: images, repliedMessage: repliedMessage)
        displayMessages(fromArray: messagesToBeSent)
        for message in messagesToBeSent {
            enqueueSend(message, token: token)
        }
    }
    
    private func resetInputs() {
        self.repliedMessage = nil
        self.messageText = ""
        self.images = []
    }
    
    func sendImage(forChat chatId: String, image: UIImage, token: String) async throws {
        let messagesToBeSent = getMessagesToBeSent(chatId: chatId, text: nil, images: [image], repliedMessage: nil)
        displayMessages(fromArray: messagesToBeSent)
        if let message = messagesToBeSent.first {
            enqueueSend(message, token: token)
        }
    }
    
    private func getMessagesToBeSent(chatId: String, text: String?, images: [UIImage], repliedMessage: FormattedMessage?) -> [MessageIntermediary] {
        var messages: [MessageIntermediary] = []
        
        // O servidor devolve `createdAt` em milissegundos (ver `Int.timeIntervalSince1970InSeconds`).
        // A mensagem local precisa usar a mesma unidade, senão ela cai fora de ordem na
        // cronologia e distorce divisores de horário e o prazo de "Undo Send".
        let now = Int(Date().timeIntervalSince1970 * 1000)

        for image in images {
            let message = MessageIntermediary(id: UUID().uuidString, chatId: chatId, text: nil, imageUrl: nil, isRead: false, createdAt: now, repliedMessageId: nil, repliedMessageText: nil, status: .sending, image: image, isCurrentUser: true)
            messages.append(message)
        }

        if let text = text {
            let message = MessageIntermediary(id: UUID().uuidString, chatId: chatId, text: text, imageUrl: nil, isRead: false, createdAt: now, repliedMessageId: nil, repliedMessageText: nil, status: .sending, image: nil, isCurrentUser: true)
            messages.append(message)
        }

        messages[0].repliedMessageId = repliedMessage?.id
        messages[0].repliedMessageText = repliedMessage?.message

        return messages
    }

    private func displayMessages(fromArray messages: [MessageIntermediary]) {
        merge(messages, source: .local)
        self.lastMessageAdded = messages.last?.id
    }

    /// Corrente de envio da conversa: cada mensagem espera a anterior terminar antes de sair.
    ///
    /// Antes, cada toque no botão de enviar abria uma task independente (e imagem e texto do
    /// mesmo toque iam num `TaskGroup`), então tudo corria em paralelo. Como o upload da imagem
    /// demora mais que um POST de texto, o texto chegava primeiro ao servidor e a conversa
    /// aparecia fora de ordem. Enfileirar aqui vale para qualquer tipo de mensagem, porque o
    /// upload da mídia acontece dentro do elo da corrente, não antes dele.
    private var sendPipeline: Task<Void, Never>?

    /// Mensagens que falharam e estão segurando a corrente até serem reenviadas ou removidas.
    private var blockedSends: [String: CheckedContinuation<Void, Never>] = [:]

    private func enqueueSend(_ message: MessageIntermediary, token: String) {
        let previous = sendPipeline
        sendPipeline = Task { [weak self] in
            await previous?.value
            await self?.send(message, token: token)
        }
    }

    private func send(_ message: MessageIntermediary, token: String) async {
        await deliver(message, token: token)
        await holdPipeline(ifFailed: message.id)
    }

    /// Sobe a foto, se houver, e entrega a mensagem à API.
    ///
    /// Separado de `send` porque o reenvio precisa exatamente disto e nada mais: ele não pode
    /// passar por `holdPipeline`, que guardaria uma segunda continuação para a mesma mensagem e
    /// deixaria a corrente presa para sempre na primeira, que ninguém mais retomaria.
    private func deliver(_ message: MessageIntermediary, token: String) async {
        do {
            let imageUrl = try await getUrl(forImage: message.image)
            await postNewMessage(withTemporaryId: message.id, chatId: message.chatId, text: message.text, imageUrl: imageUrl, repliedMessageId: message.repliedMessageId, repliedMessageText: message.repliedMessageText, token: token)
        } catch {
            updateMessage(withId: message.id, toStatus: .failed)
            overlayError = (true, ErrorMessage.sendMessage)
        }
    }

    /// Segura a corrente enquanto a mensagem estiver falha, para que as seguintes não
    /// ultrapassem uma mensagem que o usuário ainda pode reenviar. O retry continua sendo o
    /// mesmo de sempre (`resendMessage`): quando ele confirma a mensagem — ou quando ela é
    /// removida — a corrente é liberada e as próximas saem na ordem original.
    private func holdPipeline(ifFailed messageId: String) async {
        guard intermediaryMessages.contains(where: { $0.id == messageId && $0.status == .failed }) else { return }

        await withCheckedContinuation { continuation in
            blockedSends[messageId] = continuation
        }
    }

    private func releasePipeline(holdingMessageId messageId: String) {
        blockedSends.removeValue(forKey: messageId)?.resume()
    }

    private func getUrl(forImage image: UIImage?) async throws -> String? {
        if let img = image {
            do {
                return try await storeImage(img)
            } catch {
                overlayError = (true, ErrorMessage.postImageErrorMessage)
            }
        }
        return nil
    }
    
    private func storeImage(_ image: UIImage) async throws -> String? {
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child("post-image/\(UUID().uuidString).jpg")
        let imageData = image.jpegData(compressionQuality: 0.8)
        _ = try await fileRef.putDataAsync(imageData!)
        let imageUrl = try await fileRef.downloadURL()
        return imageUrl.absoluteString
    }
    
    private func postNewMessage(withTemporaryId tempId: String, chatId: String, text: String?, imageUrl: String?, repliedMessageId: String?, repliedMessageText: String?, token: String) async {
        // O id temporário é a chave de idempotência: ele nasce um UUID por mensagem e sobrevive ao
        // reenvio, então a API reconhece a segunda tentativa como a mesma mensagem e devolve a que
        // já existe, em vez de criar uma cópia.
        let result = await AYServices.shared.postNewMessage(chatId: chatId, text: text, imageUrl: imageUrl, repliedMessageId: repliedMessageId, clientMessageId: tempId, token: token)
        
        switch result {
        case .success(let message):
            playSendMessageSound()
            confirmSentMessage(withTemporaryId: tempId, as: message)
        case .failure:
            updateMessage(withId: tempId, toStatus: .failed)
            overlayError = (true, ErrorMessage.sendMessage)
        }
    }

    /// Troca a mensagem temporária pela versão confirmada pelo servidor.
    ///
    /// Se o socket já tiver entregue essa mesma mensagem antes da resposta HTTP, o id
    /// temporário já não existe e o merge apenas atualiza a entrada existente — em nenhum
    /// dos caminhos a mensagem aparece duplicada.
    private func confirmSentMessage(withTemporaryId tempId: String, as message: Message) {
        var confirmed = message.convertMessageToIntermediary(forCurrentUserUid: LocalState.currentUserUid)
        confirmed.status = .sent
        merge([confirmed], source: .local, replacingTemporaryId: tempId)
        // Um reenvio bem-sucedido é o que libera a corrente de envio parada nesta mensagem.
        releasePipeline(holdingMessageId: tempId)
    }

    private func updateMessage(withId messageId: String, toStatus newStatus: MessageStatus) {
        if let index = intermediaryMessages.firstIndex(where: { $0.id == messageId }) {
            intermediaryMessages[index].status = newStatus
            // Este caminho não passa pelo `merge`, que é quem normalmente persiste. Sem gravar
            // aqui, a mensagem que falhou voltaria do cache como se ainda estivesse saindo.
            messageStore.upsert([intermediaryMessages[index]], chatId: intermediaryMessages[index].chatId)
        } else {
            print("⚠️ Message with ID \(messageId) was not found (provavelmente já reconciliada).")
        }
    }

    private func playSendMessageSound() {
        playSound(withName: "sent-message-sound")
    }
    
    /// Tenta de novo uma mensagem que falhou.
    ///
    /// Refaz o envio inteiro, e não só o POST: uma mensagem com foto que falhou não tem `imageUrl`
    /// nenhuma para reaproveitar — o que ela tem são os bytes, e eles precisam subir antes. O id
    /// temporário é mantido, e é ele que a API reconhece como a mesma mensagem.
    func resendMessage(withTempId tempId: String, token: String) async {
        guard let message = intermediaryMessages.first(where: { $0.id == tempId }) else { return }

        updateMessage(withId: tempId, toStatus: .sending)
        await deliver(message, token: token)
    }
    
    func getMessage(withId messageId: String) -> FormattedMessage? {
        if let index = formattedMessages.firstIndex(where: { $0.id == messageId }) {
            return formattedMessages[index]
        } else {
            return nil
        }
    }
    
    //MARK: - Receive Message

    /// Trata um evento `message` vindo do socket.
    ///
    /// O handler do SocketIO já roda na main queue (`manager.handleQueue`), e este view model
    /// é `@MainActor`: fazer o `append` dentro de um `DispatchQueue.main.async`, como antes,
    /// só adiava a escrita para o próximo ciclo do run loop e abria uma janela em que a
    /// checagem de duplicidade lia um estado desatualizado.
    func processMessage(_ data: [Any], toChat chatId: String,  emitReadCommand: (String) -> ()) {
        guard let message = decodeMessage(data) else { return }

        RealtimeLog.eventReceived("message", chatId: message.chatId)

        guard message.chatId == chatId else {
            RealtimeLog.eventIgnored("message", reason: "evento de outra conversa")
            return
        }

        let result = merge([message], source: .socket)

        if result.inserted > 0 || result.reconciled > 0 {
            self.lastMessageAdded = message.id
        }

        guard !message.isCurrentUser else { return }

        notifyReceivedMessage(withId: message.id)
        emitReadCommand(message.id)
    }

    func decodeMessage(_ message: [Any]) -> MessageIntermediary? {
        guard let payload = message.first else {
            RealtimeLog.eventIgnored("message", reason: "payload vazio")
            return nil
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            let newMessage = try JSONDecoder().decode(Message.self, from: jsonData)
            return newMessage.convertMessageToIntermediary(forCurrentUserUid: LocalState.currentUserUid)
        } catch {
            print(error)
            RealtimeLog.parseFailure(event: "message", error: error)
        }
        return nil
    }

    /// Som e vibração da mensagem recebida, uma única vez por mensagem —
    /// uma reentrega do mesmo id pelo socket não avisa o usuário de novo.
    private func notifyReceivedMessage(withId messageId: String) {
        guard receivedMessageIds.insert(messageId).inserted else { return }
        playSound(withName: "received-message-sound")
        triggerHapticFeedback(style: .light)
    }

    //MARK: - Merge

    struct MergeResult {
        var inserted: Int = 0
        var updated: Int = 0
        var reconciled: Int = 0
        var duplicated: Int = 0
    }

    /// Ponto único de escrita da coleção de mensagens.
    ///
    /// É idempotente: identifica pelo id real, atualiza o que já existe, insere só o que é
    /// novo, casa mensagens locais em envio com a versão confirmada pelo servidor e mantém a
    /// ordem cronológica. Como nenhum caminho substitui o array, uma resposta HTTP atrasada
    /// nunca apaga o que o socket entregou enquanto ela estava em trânsito.
    @discardableResult
    private func merge(
        _ incoming: [MessageIntermediary],
        source: MessageMergeSource,
        replacingTemporaryId temporaryId: String? = nil
    ) -> MergeResult {
        var result = MergeResult()
        guard !incoming.isEmpty else { return result }

        var messages = intermediaryMessages
        var indexById = Dictionary(
            messages.enumerated().map { ($0.element.id, $0.offset) },
            uniquingKeysWith: { first, _ in first }
        )

        for message in incoming {
            // A confirmação do envio local resolve o id temporário para o id do servidor.
            if let temporaryId, let temporaryIndex = indexById[temporaryId], indexById[message.id] == nil {
                messages[temporaryIndex] = merging(existing: messages[temporaryIndex], incoming: message)
                indexById[temporaryId] = nil
                indexById[message.id] = temporaryIndex
                result.reconciled += 1
                continue
            }

            if let index = indexById[message.id] {
                let updatedMessage = merging(existing: messages[index], incoming: message)
                if hasVisibleChange(from: messages[index], to: updatedMessage) {
                    messages[index] = updatedMessage
                    result.updated += 1
                } else {
                    result.duplicated += 1
                }
                continue
            }

            if let twinIndex = indexOfPendingTwin(for: message, in: messages) {
                let pendingId = messages[twinIndex].id
                messages[twinIndex] = merging(existing: messages[twinIndex], incoming: message)
                indexById[pendingId] = nil
                indexById[message.id] = twinIndex
                result.reconciled += 1
                releasePipeline(holdingMessageId: pendingId)
                continue
            }

            messages.append(message)
            indexById[message.id] = messages.count - 1
            result.inserted += 1
        }

        guard result.inserted > 0 || result.updated > 0 || result.reconciled > 0 else {
            RealtimeLog.merged(source: source.rawValue, inserted: 0, updated: 0, reconciled: 0, duplicated: result.duplicated)
            return result
        }

        intermediaryMessages = sortedChronologically(messages)
        // O `merge` é por onde passam histórico, paginação, socket e confirmação de envio.
        // Persistir aqui é o que impede o cache e a memória de divergirem — não existe um
        // segundo caminho para a mensagem entrar na conversa.
        persist(incoming, replacingTemporaryId: temporaryId)
        RealtimeLog.merged(
            source: source.rawValue,
            inserted: result.inserted,
            updated: result.updated,
            reconciled: result.reconciled,
            duplicated: result.duplicated
        )
        return result
    }

    /// Remove do cache e da tela o que o servidor não devolveu dentro da janela da página.
    ///
    /// É como uma exclusão feita enquanto o app estava fora chega até aqui: o evento
    /// `message-delete` do socket só alcança quem está conectado na hora.
    private func applyServerDeletions(within page: [MessageIntermediary], chatId: String) {
        let removedIds = messageStore.reconcileDeletions(within: page, chatId: chatId)
        guard !removedIds.isEmpty else { return }

        let removed = Set(removedIds)
        intermediaryMessages.removeAll { removed.contains($0.id) }
    }

    /// Espelha no cache o que acabou de entrar na conversa.
    ///
    /// Usa o estado já mesclado, e não o payload cru: é ele que carrega a promoção de
    /// `sending` para `sent` e o `isRead` consolidado.
    private func persist(_ incoming: [MessageIntermediary], replacingTemporaryId temporaryId: String?) {
        guard let chatId = incoming.first?.chatId ?? intermediaryMessages.first?.chatId else { return }

        // O id temporário do envio local nunca chegou ao cache; some junto com a confirmação.
        if let temporaryId {
            messageStore.delete(messageId: temporaryId)
        }

        let incomingIds = Set(incoming.map { $0.id })
        let merged = intermediaryMessages.filter { incomingIds.contains($0.id) }
        messageStore.upsert(merged, chatId: chatId)
    }

    private func merging(existing: MessageIntermediary, incoming: MessageIntermediary) -> MessageIntermediary {
        var merged = incoming
        // O preview local sobrevive à confirmação do servidor: é a mesma imagem que acabou
        // de ser enviada, e mantê-la evita que a bolha pisque para recarregar pela URL.
        merged.image = incoming.image ?? existing.image
        // Uma mensagem que estava em envio (ou falhou) passa a confirmada quando o servidor a devolve.
        merged.status = incoming.status ?? (isServerConfirmed(existing) ? existing.status : .sent)
        // Uma leitura já confirmada nunca é rebaixada por um payload mais antigo.
        merged.isRead = incoming.isRead || existing.isRead
        return merged
    }

    private func hasVisibleChange(from existing: MessageIntermediary, to updated: MessageIntermediary) -> Bool {
        return existing.text != updated.text
        || existing.imageUrl != updated.imageUrl
        || existing.isRead != updated.isRead
        || existing.createdAt != updated.createdAt
        || existing.status != updated.status
        || existing.repliedMessageId != updated.repliedMessageId
        || existing.repliedMessageText != updated.repliedMessageText
    }

    /// Procura a mensagem local ainda em envio que corresponde à versão confirmada pelo servidor.
    ///
    /// Necessário porque a confirmação pode chegar pelo socket antes da resposta HTTP que
    /// carrega o id definitivo — sem isso, a mesma mensagem apareceria duas vezes.
    private func indexOfPendingTwin(for message: MessageIntermediary, in messages: [MessageIntermediary]) -> Int? {
        guard message.isCurrentUser else { return nil }

        return messages.firstIndex { candidate in
            guard candidate.isCurrentUser,
                  let status = candidate.status,
                  status != .sent,
                  candidate.text == message.text,
                  candidate.imageUrl == nil || candidate.imageUrl == message.imageUrl
            else { return false }

            let elapsed = abs(candidate.createdAt.timeIntervalSince1970InSeconds - message.createdAt.timeIntervalSince1970InSeconds)
            return elapsed <= Constants.MESSAGE_RECONCILIATION_WINDOW_SECONDS
        }
    }

    /// Ordena por data preservando a ordem relativa de mensagens com o mesmo timestamp,
    /// para que a lista não salte quando o servidor devolve várias mensagens no mesmo milissegundo.
    private func sortedChronologically(_ messages: [MessageIntermediary]) -> [MessageIntermediary] {
        return messages
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.createdAt != rhs.element.createdAt {
                    return lhs.element.createdAt < rhs.element.createdAt
                }
                return lhs.offset < rhs.offset
            }
            .map { $0.element }
    }

    //MARK: - Delete Message
    
    func deleteMessage(messageId: String, token: String) async {
        let result = await AYServices.shared.deleteMessage(messageId: messageId, token: token)
        
        switch result {
        case .success:
            removeMessage(withId: messageId)
        case .failure:
            overlayError = (true, ErrorMessage.deleteMessage)
        }
    }
    
    func removeMessage(withId messageId: String) {
        intermediaryMessages.removeAll { $0.id == messageId }
        messageStore.delete(messageId: messageId)
        releasePipeline(holdingMessageId: messageId)
    }
    
    //MARK: - Format Messages
    
    private func formatMessages() {
        // Índice montado uma vez só: a prévia da resposta precisa saber quem escreveu a
        // mensagem citada, e varrer a lista por mensagem sairia quadrático.
        let authorByMessageId = Dictionary(
            intermediaryMessages.map { ($0.id, $0.isCurrentUser) },
            uniquingKeysWith: { first, _ in first }
        )

        var messages: [FormattedMessage] = []
        for (index, message) in intermediaryMessages.enumerated() {
            let formattedMessage = message.formatMessage(
                isFirst: getTail(forMessage: message, withIndex: index),
                isGroupStart: isGroupStart(forMessage: message, withIndex: index),
                repliedMessageIsCurrentUser: message.repliedMessageId.flatMap { authorByMessageId[$0] },
                timeDivider: getTimeDivider(forMessage: message, withIndex: index)
            )
            messages.append(formattedMessage)
        }
        self.formattedMessages = messages
//        updateMessagesToBePersisted()
//        print("⚠️ messagesToBePersisted: \(messagesToBePersisted)")
    }
    
    /// A mensagem fecha o grupo quando é a última da lista, quando o remetente muda,
    /// quando a próxima é uma resposta (que ganha cabeçalho próprio) ou quando passou
    /// tempo demais entre as duas.
    private func getTail(forMessage message: MessageIntermediary, withIndex index: Int) -> Bool {
        guard index < intermediaryMessages.count - 1 else {
            return true
        }

        let nextMessage = intermediaryMessages[index + 1]
        guard nextMessage.isCurrentUser == message.isCurrentUser, !hasQuoteAboveBubble(nextMessage) else {
            return true
        }

        let timeDifferenceSec = nextMessage.createdAt.timeIntervalSince1970InSeconds - message.createdAt.timeIntervalSince1970InSeconds
        return timeDifferenceSec >= 60
    }

    /// Se a citação desta mensagem é desenhada fora da bolha.
    ///
    /// Só nesse caso ela quebra o grupo, porque a prévia precisa de uma faixa própria acima
    /// do balão — o que acontece em mídia e emoji avulso, que não têm bolha para acomodá-la.
    /// Em mensagem de texto a citação vive dentro da própria bolha, então responder no meio
    /// de uma sequência não deve separar nada: antes disso, qualquer resposta dava tail na
    /// mensagem anterior e abria espaçamento de troca de remetente.
    private func hasQuoteAboveBubble(_ message: MessageIntermediary) -> Bool {
        guard message.repliedMessageId != nil else { return false }
        return !isTextBubble(message)
    }

    private func isTextBubble(_ message: MessageIntermediary) -> Bool {
        guard message.image == nil, message.imageUrl == nil,
              let text = message.text, !text.isSingleEmoji
        else { return false }
        return true
    }

    /// Espelho de `getTail` olhando para trás: define se a mensagem abre um grupo.
    private func isGroupStart(forMessage message: MessageIntermediary, withIndex index: Int) -> Bool {
        guard index > 0, !hasQuoteAboveBubble(message) else {
            return true
        }

        let previousMessage = intermediaryMessages[index - 1]
        guard previousMessage.isCurrentUser == message.isCurrentUser else {
            return true
        }

        let timeDifferenceSec = message.createdAt.timeIntervalSince1970InSeconds - previousMessage.createdAt.timeIntervalSince1970InSeconds
        return timeDifferenceSec >= 60
    }

    private func getTimeDivider(forMessage message: MessageIntermediary, withIndex index: Int) -> Int? {
        guard index > 0 else {
            return message.createdAt
        }
        
        let previousMessage = intermediaryMessages[index - 1]
        let timeDifferenceSec = message.createdAt.timeIntervalSince1970InSeconds - previousMessage.createdAt.timeIntervalSince1970InSeconds
        return timeDifferenceSec >= 3600 ? message.createdAt : nil
    }
    
    private func updateMessagesToBePersisted() {
        guard formattedMessages.count >= 20 else {
            messagesToBePersisted = formattedMessages
            return
        }
        
        let startIndex = formattedMessages.count - 20
        let endIndex = formattedMessages.count
        messagesToBePersisted = Array(formattedMessages[startIndex..<endIndex])
    }
    
    private func playSound(withName soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = audioPlayer else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
