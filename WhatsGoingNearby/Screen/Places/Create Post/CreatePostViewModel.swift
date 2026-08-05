//
//  NewPostViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation
import SwiftUI
import FirebaseStorage
import AVFoundation

struct SelectedPostVideo {
    let url: URL
    let thumbnail: UIImage
    let duration: TimeInterval
}

enum PostVideoProcessingError: Error {
    case durationExceeded
    case exportFailed
}

@MainActor
class CreatePostViewModel: ObservableObject {
    
    @Published var postText: String = ""
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var isLocationVisible: Bool = false
    @Published var selectedPostTag: PostTag = .chilling
    @Published var isShareLocationAlertDisplayed: Bool = false
    @Published var isSettingsExpanded: Bool = false
    
    @Published var image: UIImage?
    @Published var isCameraDisplayed = false
    @Published var selectedVideo: SelectedPostVideo?
    @Published var isMediaPickerDisplayed = false
    @Published var mediaPickerSource: UIImagePickerController.SourceType = .photoLibrary
    @Published var mediaPickerKind: MediaPickerView.MediaKind = .image
    @Published var isProcessingVideo = false

    func selectImage(_ image: UIImage) {
        removeSelectedVideo()
        self.image = image
    }

    func selectVideo(at url: URL) {
        image = nil
        isProcessingVideo = true
        Task {
            defer { isProcessingVideo = false }
            do {
                let processedVideo = try await processVideo(at: url)
                removeSelectedVideo()
                selectedVideo = processedVideo
            } catch PostVideoProcessingError.durationExceeded {
                overlayError = (true, "Videos can be up to 30 seconds long.")
            } catch {
                overlayError = (true, "The video could not be prepared. Please try another video.")
            }
        }
    }

    func removeSelectedVideo() {
        if let url = selectedVideo?.url {
            try? FileManager.default.removeItem(at: url)
        }
        selectedVideo = nil
    }

    func presentPicker(kind: MediaPickerView.MediaKind, source: UIImagePickerController.SourceType) {
        mediaPickerKind = kind
        mediaPickerSource = source
        isMediaPickerDisplayed = true
    }

    private func processVideo(at sourceURL: URL) async throws -> SelectedPostVideo {
        let asset = AVURLAsset(url: sourceURL)
        let duration = try await asset.load(.duration).seconds
        guard duration <= 30.1 else { throw PostVideoProcessingError.durationExceeded }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("post-video-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw PostVideoProcessingError.exportFailed
        }
        exporter.outputURL = outputURL
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        await exporter.export()
        guard exporter.status == .completed else { throw PostVideoProcessingError.exportFailed }

        do {
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: outputURL))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 1280, height: 1280)
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return SelectedPostVideo(url: outputURL, thumbnail: UIImage(cgImage: cgImage), duration: duration)
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            throw error
        }
    }
    
    func createNewPost(latitude: Double, longitude: Double, token: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let imageURL = image == nil ? nil : await storeImage()
        let result = await AYServices.shared.postNewPublication(
            text: postText.nonEmptyOrNil(),
            tag: selectedPostTag.rawValue,
            imageUrl: imageURL,
            videoUrl: nil,
            videoThumbnailUrl: nil,
            latitude: latitude,
            longitude: longitude,
            isLocationVisible: isLocationVisible,
            token: token
        )
        try handleCreateNewPostResult(result)
    }
    
    private func handleCreateNewPostResult(_ result: Result<Post, RequestError>) throws {
        switch result {
        case .success:
            print("✅ Post successfully created.")
        case .failure(let error):
            if error == .forbidden {
                overlayError = (true, ErrorMessage.publicationLimitExceededErrorMessage)
            } else {
                overlayError = (true, ErrorMessage.createPostErrorMessage)
            }
            throw error
        }
    }
    
    private func storeImage() async -> String? {
        do {
            return try await FirebaseService.shared.storeImageAndGetUrl(self.image!)
        } catch {
            overlayError = (true, ErrorMessage.postImageErrorMessage)
            isLoading = false
            return nil
        }
    }
}
