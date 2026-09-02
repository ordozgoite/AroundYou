//
//  PendingPostUploadView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 06/05/26.
//

import SwiftUI

enum PendingPostStatus: Equatable {
    case queued
    case uploadingImage
    case uploadingVideo
    case creatingPost
    case completed
    case limitReached
    case failed(message: String)
    case cancelled
}

struct PendingPost {
    let text: String
    let tag: PostTag
    let image: UIImage?
    let video: SelectedPostVideo?
    let isLocationVisible: Bool
    var status: PendingPostStatus = .queued
    var progress: Double = 0
}

struct PendingPostUploadView: View {
    @Binding var post: PendingPost

    let onRetry: () -> Void
    let onCancel: () -> Void
    let onViewActivePublication: () -> Void
    let canRetryAfterLimit: Bool

    @State private var smoothingTimer: Timer? = nil

    private func progressRange(for status: PendingPostStatus) -> (start: Double, end: Double) {
        switch status {
        case .queued:
            return (0.0, 0.1)
        case .uploadingImage, .uploadingVideo:
            return (0.1, 0.6)
        case .creatingPost:
            return (0.6, 0.95)
        case .completed:
            return (0.95, 1.0)
        case .limitReached, .failed, .cancelled:
            return (post.progress, post.progress)
        }
    }

    private func startSmoothing() {
        stopSmoothing()
        let range = progressRange(for: post.status)
        // Se já está além do teto (por um update real), não anima
        guard post.progress < range.end else { return }

        smoothingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            let step = 0.005 // 0.5% por tick
            let range = progressRange(for: post.status)
            let next = min(post.progress + step, range.end)
            if next == post.progress || next >= range.end {
                stopSmoothing()
            }
            withAnimation(.linear(duration: 0.05)) {
                post.progress = next
            }
        }
    }

    private func stopSmoothing() {
        smoothingTimer?.invalidate()
        smoothingTimer = nil
    }

    private func snapToPhaseStartIfNeeded(newStatus: PendingPostStatus) {
        let range = progressRange(for: newStatus)
        withAnimation(.easeInOut(duration: 0.15)) {
            post.progress = max(post.progress, range.start)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(statusTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(hasStoppedWithError ? .red : .primary)

                    Spacer()
                }

                ProgressView(value: post.progress)
                    .progressViewStyle(.linear)

                if case .limitReached = post.status {
                    Text("Finish an active publication or wait until it expires before publishing this draft.")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(3)

                    HStack(spacing: 16) {
                        if canRetryAfterLimit {
                            Button("Publish draft") {
                                onRetry()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                        } else {
                            Button("View active publication") {
                                onViewActivePublication()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                        }

                        Button("Discard") {
                            onCancel()
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                } else if case .failed(let message) = post.status {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)

                    HStack(spacing: 16) {
                        Button("Retry") {
                            onRetry()
                        }
                        .font(.caption)
                        .fontWeight(.semibold)

                        Button("Cancel") {
                            onCancel()
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                } else {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if !hasStoppedWithError {
                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 4, y: 2)
        .padding(.horizontal)
        .animation(.easeInOut, value: post.status)
        .animation(.easeInOut, value: post.progress)
        .onAppear {
            snapToPhaseStartIfNeeded(newStatus: post.status)
            startSmoothing()
        }
        .onChange(of: post.status) { newStatus in
            switch newStatus {
            case .completed:
                stopSmoothing()
                withAnimation(.easeInOut(duration: 0.3)) {
                    post.progress = 1.0
                }
            case .limitReached, .failed, .cancelled:
                stopSmoothing()
            default:
                snapToPhaseStartIfNeeded(newStatus: newStatus)
                startSmoothing()
            }
        }
        .onDisappear {
            stopSmoothing()
        }
    }

    private var thumbnail: some View {
        Group {
            if let image = post.image ?? post.video?.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "text.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .background(Color.secondary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var subtitle: LocalizedStringKey {
        switch post.status {
        case .queued:
            return "Preparing post..."

        case .uploadingImage:
            return "Storing image..."

        case .uploadingVideo:
            return "Storing video..."

        case .creatingPost:
            return "Creating post..."

        case .completed:
            return "Completed"

        case .limitReached:
            return "Publication limit reached"

        case .failed:
            return "Failed"

        case .cancelled:
            return "Post cancelled"
        }
    }

    private var hasStoppedWithError: Bool {
        if case .limitReached = post.status {
            return true
        }

        if case .failed = post.status {
            return true
        }

        return false
    }

    private var statusTitle: LocalizedStringKey {
        switch post.status {
        case .limitReached:
            return "Publication limit reached"
        case .failed:
            return "Failed"
        default:
            return "Sending..."
        }
    }
}
//
//#Preview {
//    PendingPostUploadView(
//        post: PendingPost(
//            text: "Teste",
//            tag: .chilling,
//            image: nil,
//            isLocationVisible: true
//        ),
//        onRetry: {},
//        onCancel: {}
//    )
//}
