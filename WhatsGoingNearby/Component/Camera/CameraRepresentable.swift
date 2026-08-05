//
//  ImagePicker.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 31/03/24.
//

import Foundation
import AVFoundation
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
    enum MediaKind: Equatable {
        case image
        case video
    }

    let mediaKind: MediaKind
    let onImageSelected: (UIImage) -> Void
    let onVideoSelected: (URL) -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        if mediaKind == .video {
            return VideoCameraViewController(
                onVideoSelected: onVideoSelected,
                onDismiss: onDismiss
            )
        }

        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier]
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    static func dismantleUIViewController(_ viewController: UIViewController, coordinator: MediaPickerCoordinator) {
        if let cameraController = viewController as? VideoCameraViewController {
            cameraController.shutDown()
        } else if let picker = viewController as? UIImagePickerController {
            picker.delegate = nil
        }
    }

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
        }
        picker.dismiss(animated: true)
        parent.onDismiss()
    }
}

private final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

private final class VideoCameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    private let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "com.aroundyou.video-camera")
    private let recordingState = VideoRecordingState()
    private let onVideoSelected: (URL) -> Void
    private let onDismiss: () -> Void
    private var recordingTimer: Timer?
    private var isConfigured = false
    private var isClosing = false
    private var shouldStopAfterStarting = false
    private var discardCurrentRecording = false

    private var previewView: CameraPreviewView {
        view as! CameraPreviewView
    }

    init(onVideoSelected: @escaping (URL) -> Void, onDismiss: @escaping () -> Void) {
        self.onVideoSelected = onVideoSelected
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = CameraPreviewView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        previewView.previewLayer.session = session
        previewView.previewLayer.videoGravity = .resizeAspectFill
        installControls()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: AVCaptureSession.wasInterruptedNotification,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: AVCaptureSession.interruptionEndedNotification,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError(_:)),
            name: AVCaptureSession.runtimeErrorNotification,
            object: session
        )
        prepareSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            shutDown()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func installControls() {
        let overlay = VideoCaptureOverlay(
            state: recordingState,
            onPressBegan: { [weak self] in self?.beginPress() },
            onPressEnded: { [weak self] in self?.endPress() },
            onCancel: { [weak self] in self?.cancel() }
        )
        let controller = UIHostingController(rootView: overlay)
        controller.view.backgroundColor = .clear
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(controller)
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        controller.didMove(toParent: self)
    }

    private func prepareSession() {
        Task { [weak self] in
            guard let self else { return }
            let cameraAuthorized = await Self.requestAccess(for: .video)
            let microphoneAuthorized = await Self.requestAccess(for: .audio)
            guard cameraAuthorized else {
                self.showError("Camera access is required to record video.")
                return
            }
            guard microphoneAuthorized else {
                self.showError("Microphone access is required to record video.")
                return
            }
            self.configureAndStartSession()
        }
    }

    private static func requestAccess(for mediaType: AVMediaType) async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: mediaType)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func configureAndStartSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.isClosing else { return }
            if !self.isConfigured {
                do {
                    try self.configureSession()
                } catch {
                    self.showError(error.localizedDescription)
                    return
                }
            }
            guard !self.session.isRunning else {
                self.setSessionReady(true)
                return
            }
            self.session.startRunning()
            self.setSessionReady(self.session.isRunning)
            if !self.session.isRunning {
                self.showError("Camera could not be started.")
            }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraCaptureError.cameraUnavailable
        }
        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(videoInput) else {
            throw CameraCaptureError.videoInputUnavailable
        }
        session.addInput(videoInput)

        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            throw CameraCaptureError.microphoneUnavailable
        }
        let audioInput = try AVCaptureDeviceInput(device: microphone)
        guard session.canAddInput(audioInput) else {
            throw CameraCaptureError.audioInputUnavailable
        }
        session.addInput(audioInput)

        guard session.canAddOutput(movieOutput) else {
            throw CameraCaptureError.outputUnavailable
        }
        session.addOutput(movieOutput)
        movieOutput.maxRecordedDuration = CMTime(seconds: 15, preferredTimescale: 600)
        isConfigured = true
    }

    private func beginPress() {
        guard recordingState.isReady,
              !recordingState.isPressing,
              !recordingState.isRecording,
              !recordingState.isFinishing,
              !isClosing else { return }
        recordingState.isPressing = true
        sessionQueue.async { [weak self] in
            guard let self,
                  self.session.isRunning,
                  !self.movieOutput.isRecording,
                  !self.isClosing else {
                DispatchQueue.main.async {
                    self?.recordingState.isPressing = false
                }
                return
            }
            self.shouldStopAfterStarting = false
            self.discardCurrentRecording = false
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            if let connection = self.movieOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            self.movieOutput.startRecording(to: url, recordingDelegate: self)
        }
    }

    private func endPress() {
        recordingState.isPressing = false
        requestStopRecording()
    }

    private func requestStopRecording() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.movieOutput.isRecording {
                self.setFinishing()
                self.movieOutput.stopRecording()
            } else {
                self.shouldStopAfterStarting = true
            }
        }
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.shouldStopAfterStarting {
                self.movieOutput.stopRecording()
                return
            }
            DispatchQueue.main.async {
                self.recordingState.isRecording = true
                self.startRecordingTimer()
            }
        }
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        let recordedSuccessfully = error == nil
            || ((error as NSError?)?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool == true)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.cancelRecordingTimer()
            self.recordingState.isPressing = false
            self.recordingState.isRecording = false
            self.recordingState.isFinishing = false
            self.shouldStopAfterStarting = false
            if self.isClosing || self.discardCurrentRecording {
                self.discardCurrentRecording = false
                try? FileManager.default.removeItem(at: outputFileURL)
                return
            }
            guard recordedSuccessfully else {
                self.showError(error?.localizedDescription ?? "Video recording failed.")
                return
            }
            self.isClosing = true
            self.onVideoSelected(outputFileURL)
            self.onDismiss()
        }
    }

    private func startRecordingTimer() {
        recordingState.progress = 0
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let duration = self.movieOutput.recordedDuration.seconds
            self.recordingState.progress = min(max(duration / 15, 0), 1)
            if duration >= 15 {
                self.recordingState.progress = 1
                self.requestStopRecording()
            }
        }
    }

    private func cancel() {
        isClosing = true
        recordingState.isPressing = false
        shutDown()
        onDismiss()
    }

    func shutDown() {
        isClosing = true
        discardCurrentRecording = true
        cancelRecordingTimer()
        recordingState.isReady = false
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    @objc private func applicationDidEnterBackground() {
        recordingState.isReady = false
        discardCurrentRecording = true
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
            self.session.stopRunning()
        }
    }

    @objc private func applicationWillEnterForeground() {
        guard !isClosing else { return }
        configureAndStartSession()
    }

    @objc private func sessionWasInterrupted() {
        recordingState.isReady = false
        discardCurrentRecording = true
        sessionQueue.async { [weak self] in
            guard let self, self.movieOutput.isRecording else { return }
            self.movieOutput.stopRecording()
        }
    }

    @objc private func sessionInterruptionEnded() {
        guard !isClosing else { return }
        configureAndStartSession()
    }

    @objc private func sessionRuntimeError(_ notification: Notification) {
        let error = notification.userInfo?[AVCaptureSessionErrorKey] as? Error
        showError(error?.localizedDescription ?? "Camera session failed.")
    }

    private func setSessionReady(_ ready: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.recordingState.isReady = ready
            if ready {
                self?.recordingState.errorMessage = nil
            }
        }
    }

    private func setFinishing() {
        DispatchQueue.main.async { [weak self] in
            self?.recordingState.isFinishing = true
        }
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.recordingState.errorMessage = message
            self?.recordingState.isReady = false
        }
    }

    private func cancelRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

private enum CameraCaptureError: LocalizedError {
    case cameraUnavailable
    case videoInputUnavailable
    case microphoneUnavailable
    case audioInputUnavailable
    case outputUnavailable

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available on this device."
        case .videoInputUnavailable:
            return "Camera input could not be configured."
        case .microphoneUnavailable:
            return "Microphone is not available on this device."
        case .audioInputUnavailable:
            return "Microphone input could not be configured."
        case .outputUnavailable:
            return "Video recording could not be configured."
        }
    }
}

private final class VideoRecordingState: ObservableObject {
    @Published var isReady = false
    @Published var isPressing = false
    @Published var isRecording = false
    @Published var isFinishing = false
    @Published var progress = 0.0
    @Published var errorMessage: String?
}

private struct VideoCaptureOverlay: View {
    @ObservedObject var state: VideoRecordingState
    let onPressBegan: () -> Void
    let onPressEnded: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Color.clear
            .overlay {
                if let errorMessage = state.errorMessage {
                    Text(errorMessage)
                        .font(.body.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(20)
                        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 32)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 12) {
                    ProgressView(value: state.progress)
                        .tint(.red)
                        .padding(.horizontal, 20)
                        .opacity(state.isRecording || state.isFinishing ? 1 : 0)

                    recordingStatus
                }
                .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomControls
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .background(.black.opacity(0.45))
            }
    }

    private var bottomControls: some View {
        VStack(spacing: 10) {
            ZStack {
                captureButton
                    .zIndex(2)

                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(.black.opacity(0.55), in: Circle())
                    }

                    Spacer()

                    Color.clear
                        .frame(width: 48, height: 48)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)

            Text(instructionText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.black.opacity(0.55), in: Capsule())
                .allowsHitTesting(false)
        }
        .frame(minHeight: 127)
    }

    private var recordingStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
            Text(state.isFinishing ? "Preparing video..." : "Recording")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.black.opacity(0.55), in: Capsule())
        .opacity(state.isRecording || state.isFinishing ? 1 : 0)
    }

    private var instructionText: LocalizedStringKey {
        if state.errorMessage != nil {
            return "Camera unavailable"
        }
        if !state.isReady {
            return "Preparing camera..."
        }
        if state.isFinishing {
            return "Preparing video..."
        }
        return state.isRecording ? "Release to stop" : "Hold to record"
    }

    private var captureButton: some View {
        ZStack {
            Circle()
                .stroke(.white, lineWidth: 5)
                .frame(width: 76, height: 76)
            Circle()
                .fill(state.isRecording ? .red : .white.opacity(0.3))
                .frame(width: state.isRecording ? 54 : 62, height: state.isRecording ? 54 : 62)
        }
        .frame(width: 88, height: 88)
        .scaleEffect(state.isPressing ? 0.9 : 1)
        .animation(.easeOut(duration: 0.12), value: state.isPressing)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPressBegan() }
                .onEnded { _ in onPressEnded() }
        )
        .opacity(state.isReady ? 1 : 0.55)
        .allowsHitTesting(state.isReady && !state.isFinishing)
        .accessibilityElement()
        .accessibilityLabel("Record video")
        .accessibilityHint("Press and hold to record. Release to stop.")
        .accessibilityAddTraits(.isButton)
    }
}
