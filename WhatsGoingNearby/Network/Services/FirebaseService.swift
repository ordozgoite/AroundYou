//
//  FirebaseService.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 08/02/25.
//

import Foundation
import FirebaseStorage
import SwiftUI

enum FirebaseServiceError: Error {
    case noImageProvided
    case imageConversionFailed
    case uploadFailed
}

final class FirebaseService {
    
    static let shared = FirebaseService()
    private init() {}
    
    func storeImageAndGetUrl(_ image: UIImage) async throws -> String {
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child("post-image/\(UUID().uuidString).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FirebaseServiceError.imageConversionFailed
        }
        
        do {
            _ = try await fileRef.putDataAsync(imageData)
            let imageUrl = try await fileRef.downloadURL()
            return imageUrl.absoluteString
        } catch {
            throw FirebaseServiceError.uploadFailed
        }
    }

    func storeVideoAndThumbnail(videoURL: URL, thumbnail: UIImage) async throws -> (videoUrl: String, thumbnailUrl: String) {
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) else {
            throw FirebaseServiceError.imageConversionFailed
        }
        let identifier = UUID().uuidString
        let storageRef = Storage.storage().reference()
        let videoRef = storageRef.child("post-video/\(identifier).mp4")
        let thumbnailRef = storageRef.child("post-video-thumbnail/\(identifier).jpg")

        do {
            _ = try await videoRef.putFileAsync(from: videoURL)
            do {
                _ = try await thumbnailRef.putDataAsync(thumbnailData)
            } catch {
                try? await videoRef.delete()
                throw error
            }
            async let videoUrl = videoRef.downloadURL()
            async let thumbnailUrl = thumbnailRef.downloadURL()
            do {
                return try await (videoUrl.absoluteString, thumbnailUrl.absoluteString)
            } catch {
                try? await videoRef.delete()
                try? await thumbnailRef.delete()
                throw error
            }
        } catch {
            throw FirebaseServiceError.uploadFailed
        }
    }
}
