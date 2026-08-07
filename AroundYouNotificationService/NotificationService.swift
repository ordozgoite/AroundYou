//
//  NotificationService.swift
//  AroundYouNotificationService
//
//  Created by Victor Ordozgoite on 07/08/25.
//

import UserNotifications
import Intents
import UIKit
import ImageIO
import OSLog

final class NotificationService: UNNotificationServiceExtension {

    private let logger = Logger(
        subsystem: "ordozgoite.WhatsGoingNearby.NotificationService",
        category: "MessageNotification"
    )

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var enrichmentTask: Task<Void, Never>?

    private let deliveryLock = NSLock()
    private var didDeliver = false

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        logger.info("Service extension executed")

        guard let mutableContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            deliver(request.content)
            return
        }
        bestAttemptContent = mutableContent

        let userInfo = request.content.userInfo
        guard MessageNotificationPayload.isMessage(userInfo) else {
            logger.info("Notification ignored: not a message")
            deliver(mutableContent)
            return
        }

        guard let payload = MessageNotificationPayload(userInfo: userInfo) else {
            logger.notice("Message payload is incomplete: delivered unchanged")
            deliver(mutableContent)
            return
        }
        logger.info("Enriching message \(payload.messageId ?? "unknown", privacy: .public)")

        // Mantém o agrupamento por conversa mesmo se o enriquecimento falhar adiante.
        mutableContent.threadIdentifier = payload.conversationId

        enrichmentTask = Task { [weak self] in
            guard let self else { return }
            let avatar = await self.avatar(for: payload)
            self.deliverAsCommunicationNotification(mutableContent, payload: payload, avatar: avatar)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        logger.notice("Service extension expired: delivering the best content available")
        enrichmentTask?.cancel()
        deliver(bestAttemptContent ?? UNMutableNotificationContent())
    }

    private func deliver(_ content: UNNotificationContent) {
        deliveryLock.lock()
        let shouldDeliver = !didDeliver
        didDeliver = true
        let handler = contentHandler
        deliveryLock.unlock()

        guard shouldDeliver, let handler else { return }
        handler(content)
    }
}

// MARK: - Communication Notification

private extension NotificationService {

    func deliverAsCommunicationNotification(
        _ content: UNMutableNotificationContent,
        payload: MessageNotificationPayload,
        avatar: INImage?
    ) {
        let handle = INPersonHandle(value: payload.senderId, type: .unknown)
        let sender = INPerson(
            personHandle: handle,
            nameComponents: nil,
            displayName: payload.senderName,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: payload.senderId,
            isMe: false,
            suggestionType: .none
        )

        // `content` fica nulo de propósito: o texto da mensagem já está no alert e não
        // precisa ser doado ao sistema.
        let intent = INSendMessageIntent(
            recipients: nil,
            outgoingMessageType: .outgoingMessageText,
            content: nil,
            speakableGroupName: nil,
            conversationIdentifier: payload.conversationId,
            serviceName: nil,
            sender: sender,
            attachments: nil
        )
        if let avatar {
            intent.setImage(avatar, forParameterNamed: \.sender)
        }
        logger.info("Communication intent created")

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate { [weak self] error in
            guard let self else { return }
            if let error {
                self.logger.error("Interaction donation failed: \(error.localizedDescription, privacy: .public)")
            }

            do {
                let enrichedContent = try content.updating(from: intent)
                self.logger.info("Enriched notification delivered")
                self.deliver(enrichedContent)
            } catch {
                self.logger.error("Communication update failed: \(error.localizedDescription, privacy: .public)")
                self.deliver(content)
            }
        }
    }
}

// MARK: - Avatar

private extension NotificationService {

    func avatar(for payload: MessageNotificationPayload) async -> INImage? {
        guard let url = payload.profileImageUrl else {
            logger.info("Sender has no profile picture: using the default avatar")
            return AvatarImage.defaultAvatar()
        }

        logger.info("Avatar download started")
        guard let data = await AvatarImage.download(from: url) else {
            logger.notice("Avatar download failed: using the default avatar")
            return AvatarImage.defaultAvatar()
        }

        guard let resized = AvatarImage.resized(data) else {
            logger.notice("Avatar could not be decoded: using the default avatar")
            return AvatarImage.defaultAvatar()
        }

        logger.info("Avatar download finished")
        return INImage(imageData: resized)
    }
}

// MARK: - Payload

private struct MessageNotificationPayload {

    let conversationId: String
    let senderId: String
    let senderName: String
    let messageId: String?
    let profileImageUrl: URL?

    static func isMessage(_ userInfo: [AnyHashable: Any]) -> Bool {
        userInfo["screenToShow"] as? String == "message"
    }

    init?(userInfo: [AnyHashable: Any]) {
        guard MessageNotificationPayload.isMessage(userInfo) else { return nil }
        guard
            let conversationId = (userInfo["chatId"] as? String)?.nonEmpty,
            let senderId = (userInfo["senderUserUid"] as? String)?.nonEmpty,
            let senderName = (userInfo["username"] as? String)?.nonEmpty
        else { return nil }

        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.messageId = (userInfo["messageId"] as? String)?.nonEmpty
        self.profileImageUrl = MessageNotificationPayload.imageUrl(from: userInfo["chatPic"])
    }

    private static func imageUrl(from value: Any?) -> URL? {
        guard
            let string = (value as? String)?.nonEmpty,
            let url = URL(string: string),
            url.scheme?.lowercased() == "https",
            url.host != nil
        else { return nil }
        return url
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Avatar Image

private enum AvatarImage {

    /// A extensão tem tempo e memória curtos: o download é limitado no tempo e no tamanho,
    /// e a imagem é reduzida ao tamanho realmente exibido pelo sistema.
    static let requestTimeout: TimeInterval = 5
    static let resourceTimeout: TimeInterval = 8
    static let maximumBytes = 5 * 1024 * 1024
    static let renderedSide: CGFloat = 128

    /// As fotos enviadas ao Firebase Storage sem `contentType` voltam como
    /// `application/octet-stream`, mesmo sendo JPEG. Por isso o header só barra resposta
    /// claramente errada — uma página de erro, um JSON — e quem decide se o formato é
    /// suportado é o decoder, logo abaixo em `downsampled(_:)`.
    static let rejectedMimePrefixes = ["text/", "application/json", "application/xml"]

    static func download(from url: URL) async -> Data? {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = resourceTimeout
        configuration.allowsCellularAccess = true
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        do {
            let (data, response) = try await session.data(from: url)
            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                isPossiblyImage(httpResponse.mimeType),
                data.count <= maximumBytes
            else { return nil }
            return data
        } catch {
            return nil
        }
    }

    private static func isPossiblyImage(_ mimeType: String?) -> Bool {
        guard let mimeType = mimeType?.lowercased() else { return true }
        return !rejectedMimePrefixes.contains { mimeType.hasPrefix($0) }
    }

    static func resized(_ data: Data) -> Data? {
        guard let image = downsampled(data) else { return nil }

        let side = renderedSide
        let scale = max(side / max(image.size.width, 1), side / max(image.size.height, 1))
        let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(
            x: (side - scaledSize.width) / 2,
            y: (side - scaledSize.height) / 2
        )

        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: side, height: side),
            format: format
        )
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
        return rendered.pngData()
    }

    /// Decodifica já reduzido: o bitmap completo nunca chega a existir, o que importa no
    /// limite de memória da extensão. Também serve de validação real do formato — o que
    /// o ImageIO não abrir, não é imagem que o sistema saiba exibir.
    private static func downsampled(_ data: Data) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(renderedSide)
        ]
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { return nil }
        return UIImage(cgImage: thumbnail)
    }

    /// Avatar genérico desenhado a partir de um símbolo nativo, com cores fixas para
    /// manter contraste tanto no modo claro quanto no escuro.
    static func defaultAvatar() -> INImage? {
        let side = renderedSide
        let background = UIColor(red: 0.68, green: 0.68, blue: 0.70, alpha: 1)
        let glyphSide = side * 0.55

        guard let glyph = UIImage(systemName: "person.fill")?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        else { return nil }

        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: side, height: side),
            format: format
        )
        let rendered = renderer.image { context in
            background.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))

            let glyphSize = aspectFitSize(for: glyph.size, in: glyphSide)
            glyph.draw(in: CGRect(
                x: (side - glyphSize.width) / 2,
                y: (side - glyphSize.height) / 2,
                width: glyphSize.width,
                height: glyphSize.height
            ))
        }
        return rendered.pngData().map(INImage.init(imageData:))
    }

    private static func aspectFitSize(for size: CGSize, in side: CGFloat) -> CGSize {
        let scale = min(side / max(size.width, 1), side / max(size.height, 1))
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
}
