//
//  ImagePicker.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 31/03/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct accessCameraView: UIViewControllerRepresentable {
    
//    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var isPresented
    
    let sendImage: (UIImage) -> ()
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
}

// Coordinator will help to preview the selected image in the View.
class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: accessCameraView
    
    init(picker: accessCameraView) {
        self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
//        self.picker.selectedImage = selectedImage
        self.picker.isPresented.wrappedValue.dismiss()
        self.picker.sendImage(selectedImage)
    }
}

struct MediaPickerView: UIViewControllerRepresentable {
    enum MediaKind {
        case image
        case video
    }

    let sourceType: UIImagePickerController.SourceType
    let mediaKind: MediaKind
    let onImageSelected: (UIImage) -> Void
    let onVideoSelected: (URL) -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.mediaTypes = [mediaKind == .image ? UTType.image.identifier : UTType.movie.identifier]
        picker.videoMaximumDuration = 30
        picker.videoQuality = .typeHigh
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> MediaPickerCoordinator {
        MediaPickerCoordinator(parent: self)
    }
}

final class MediaPickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    private let parent: MediaPickerView

    init(parent: MediaPickerView) {
        self.parent = parent
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        parent.onDismiss()
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let image = info[.originalImage] as? UIImage {
            parent.onImageSelected(image)
        } else if let url = info[.mediaURL] as? URL {
            parent.onVideoSelected(url)
        }
        picker.dismiss(animated: true)
        parent.onDismiss()
    }
}
