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
}
