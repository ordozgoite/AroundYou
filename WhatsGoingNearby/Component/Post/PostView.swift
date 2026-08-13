//
//  PostView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI
import CoreLocation
import AVKit
import FirebaseAuth

protocol PostViewActionHandler {
    func postViewDidLikePublication(_ content: FormattedPost)
    func postViewDidUnlikePublication(_ content: FormattedPost)
    func postViewDidDeletePublication(_ content: FormattedPost)
    func postViewDidDeleteLostItem(_ content: FormattedPost)
    func postViewDidDeleteReport(_ content: FormattedPost)
    func postViewDidFollow(_ content: FormattedPost)
    func postViewDidUnfollow(_ content: FormattedPost)
    func postViewDidMarkAsCompleted(_ content: FormattedPost)
}

@MainActor
final class PublicationViewTracker {
    static let shared = PublicationViewTracker()

    private var visibleSince: [String: Date] = [:]
    private var pending = Set<String>()
    private var registeredThisSession = Set<String>()
    private var flushTask: Task<Void, Never>?
    private var samplingTask: Task<Void, Never>?
    private var isForeground = true
    private var failedAttempts = 0
    private var observers: [NSObjectProtocol] = []

    private init() {
        observers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isForeground = false
                self?.visibleSince.removeAll()
                await self?.flush()
            }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isForeground = true }
        })
        samplingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                self?.collectQualifiedViews()
            }
        }
    }

    func updateVisibility(publicationId: String, isAuthor: Bool, visibleFraction: CGFloat) {
        guard isForeground, !isAuthor, !registeredThisSession.contains(publicationId), visibleFraction >= 0.5 else {
            visibleSince.removeValue(forKey: publicationId)
            return
        }
        if visibleSince[publicationId] == nil { visibleSince[publicationId] = Date() }
    }

    func updateVisiblePublications(_ publications: [PublicationVisibilityCandidate]) {
        let visibleIds = Set(publications.filter(\.isSufficientlyVisible).map(\.publicationId))
        visibleSince.keys.filter { !visibleIds.contains($0) }.forEach {
            visibleSince.removeValue(forKey: $0)
        }
        publications.forEach {
            updateVisibility(
                publicationId: $0.publicationId,
                isAuthor: $0.isAuthor,
                visibleFraction: $0.isSufficientlyVisible ? 1 : 0
            )
        }
    }

    func flushWhenLeavingFeed() {
        visibleSince.removeAll()
        Task { await flush() }
    }

    func clearSession() {
        visibleSince.removeAll()
        pending.removeAll()
        registeredThisSession.removeAll()
        flushTask?.cancel()
        failedAttempts = 0
    }

    private func collectQualifiedViews() {
        guard isForeground else { return }
        let now = Date()
        let qualified = visibleSince.compactMap { now.timeIntervalSince($0.value) >= 1 ? $0.key : nil }
        guard !qualified.isEmpty else { return }
        qualified.forEach {
            visibleSince.removeValue(forKey: $0)
            pending.insert($0)
            registeredThisSession.insert($0)
        }
        failedAttempts = 0
        if pending.count >= 5 {
            Task { await flush() }
        } else {
            scheduleFlush()
        }
    }

    private func scheduleFlush() {
        guard flushTask == nil else { return }
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await self?.flush()
        }
    }

    private func flush() async {
        flushTask?.cancel()
        flushTask = nil
        guard !pending.isEmpty, failedAttempts < 2,
              let token = try? await Auth.auth().currentUser?.getIDToken() else { return }
        let batch = Array(pending.prefix(50))
        switch await AYServices.shared.registerPublicationViews(batch, token: token) {
        case .success(let response):
            response.processedPublicationIds.forEach { pending.remove($0) }
            failedAttempts = 0
            if !pending.isEmpty { scheduleFlush() }
        case .failure:
            failedAttempts += 1
            if failedAttempts < 2 { scheduleFlush() }
        }
    }
}

struct PublicationVisibilityCandidate: Equatable {
    let publicationId: String
    let isAuthor: Bool
    let isSufficientlyVisible: Bool
}

@MainActor
private final class PublicationViewersViewModel: ObservableObject {
    @Published var viewers: [PublicationViewer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasHiddenViewers = false
    private var page = 0
    private var totalPages = 1
    private let publicationId: String

    init(publicationId: String) { self.publicationId = publicationId }

    func load(reset: Bool = false) async {
        guard !isLoading, reset || page < totalPages else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let requestedPage = reset ? 1 : page + 1
        guard let token = try? await Auth.auth().currentUser?.getIDToken() else {
            errorMessage = "Unable to restore your session."
            return
        }
        switch await AYServices.shared.getPublicationViewers(publicationId: publicationId, page: requestedPage, token: token) {
        case .success(let response):
            viewers = reset ? response.viewers : viewers + response.viewers
            hasHiddenViewers = response.hasHiddenViewers
            page = response.pagination.page
            totalPages = response.pagination.totalPages
        case .failure:
            errorMessage = "Unable to load viewers."
        }
    }
}

private struct PublicationViewersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PublicationViewersViewModel

    init(publicationId: String) {
        _viewModel = StateObject(wrappedValue: PublicationViewersViewModel(publicationId: publicationId))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.viewers.isEmpty {
                    ProgressView()
                } else if let error = viewModel.errorMessage, viewModel.viewers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                        Text(error)
                        Button("Try again") { Task { await viewModel.load(reset: true) } }
                    }
                } else if viewModel.viewers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "eye.slash")
                        Text("No viewers yet")
                    }
                } else {
                    List {
                        ForEach(viewModel.viewers) { viewer in
                            HStack(spacing: 12) {
                                ProfilePicView(profilePic: viewer.profileImageUrl)
                                    .frame(width: 44, height: 44)
                                VStack(alignment: .leading) {
                                    Text("\(viewer.username)").fontWeight(.semibold)
                                }
                            }
                            .onAppear {
                                if viewer.id == viewModel.viewers.last?.id {
                                    Task { await viewModel.load() }
                                }
                            }
                        }
                        if viewModel.hasHiddenViewers {
                            Text("The total may include people who chose to keep their view private.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .refreshable { await viewModel.load(reset: true) }
                }
            }
            .navigationTitle("Views")
            .toolbar { Button("Done") { dismiss() } }
        }
        .task { await viewModel.load(reset: true) }
    }

    private func formattedViewDate(_ value: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: value) else { return value }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

struct PostView: View {
    @State var post: FormattedPost
    var delegate: PostViewActionHandler?
    let isClickable: Bool
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var socket: SocketService
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var postVM = PostViewModel()
    @State private var isViewersPresented = false
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 8) {
                ProfilePic()
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        HeaderView()
                        
                        Tag()
                    }
                    
                    TextView()
                    
                    MediaPreview()
                    
                    Footer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleOnTapGesture()
            }
        }
        .sheet(isPresented: $isViewersPresented) {
            PublicationViewersSheet(publicationId: post.id)
        }
    }
    
    //MARK: - ProfilePic
    
    @ViewBuilder
    private func ProfilePic() -> some View {
        VStack {
            ProfilePicView(profilePic: post.userProfilePic)
                .onTapGesture {
                    navCoordinator.navigate(to: .userProfile(post.userUid))
                }
        }
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func HeaderView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Username()
                
                TimeInfo()
                
                Spacer()
                
                OptionsButton()
            }
        }
    }
    
    // MARK: - Username
    
    @ViewBuilder
    private func Username() -> some View {
        NavigationLink(destination: UserProfileScreen(userUid: post.userUid)) {
            HStack(spacing: 0) {
                Text(post.username)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Image("pioneer-icon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: 24)
                    .clipped()
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Time Info
    
    @ViewBuilder
    private func TimeInfo() -> some View {
        if postVM.isActivePublication(post) {
            CircleTimerView(
                postDate: post.timestamp.timeIntervalSince1970InSeconds,
                expirationDate: post.expirationDate.timeIntervalSince1970InSeconds
            )
            .popover(isPresented: $postVM.isTimeLeftPopoverDisplayed) {
                Text(postVM.getTimeLeftText(forPost: post))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding([.leading, .trailing], 10)
                    .presentationCompactAdaptation(.popover)
            }
            .onTapGesture {
                postVM.isTimeLeftPopoverDisplayed = true
            }
        } else {
            Text(post.timestamp.convertTimestampToDate().formatDatetoPost())
                .foregroundStyle(.gray)
                .font(.caption)
        }
    }
    
    // MARK: - Options Button
    
    @ViewBuilder
    private func OptionsButton() -> some View {
        Image(systemName: "ellipsis")
            .foregroundStyle(.gray)
            .popover(isPresented: $postVM.isOptionsPopoverDisplayed) {
                Options()
            }
            .onTapGesture {
                postVM.isOptionsPopoverDisplayed = true
            }
    }
    
    //MARK: - Options
    
    @ViewBuilder
    private func Options() -> some View {
        VStack {
            if post.isFromRecipientUser {
                if postVM.isActivePublication(post) {
                    EditPostButton()
                    
                    FinishPostButton()
                }
                
                switch post.postSource {
                case .publication:
                    DeletePostButton()
                case .lostItem:
                    DeleteLostItemButton()
                case .report:
                    DeleteReportButton()
                }
            } else if post.postSource == .publication {
                if let isSubscribed = post.isSubscribed {
                    if isSubscribed {
                        DisableNotificationsButton()
                    } else {
                        EnableNotificationsButton()
                    }
                }
                
                Divider()
                
                ReportPostButton()
            }
        }
        .presentationCompactAdaptation(.popover)
    }
    
    // MARK: - Edit Post
    
    @ViewBuilder
    private func EditPostButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            navCoordinator.navigate(to: .editPost(post))
        } label: {
            Text("Edit Post")
            Image(systemName: "pencil")
        }
        .foregroundStyle(.gray)
        .padding()
    }
    
    // MARK: - Finish Post
    
    @ViewBuilder
    private func FinishPostButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            finishPost()
        } label: {
            Text("Finish Post")
            Image(systemName: "clock.arrow.circlepath")
        }
        .foregroundStyle(.gray)
        .padding(.horizontal)
    }
    
    // MARK: - Delete Post
    
    @ViewBuilder
    private func DeletePostButton() -> some View {
        Button(role: .destructive) {
            deletePost()
        } label: {
            Text("Delete Post")
            Image(systemName: "trash")
        }
        .padding()
    }
    
    // MARK: - Delete Lost Item
    
    @ViewBuilder
    private func DeleteLostItemButton() -> some View {
        Button(role: .destructive) {
            deleteLostItem()
        } label: {
            Text("Delete Lost Item")
            Image(systemName: "trash")
        }
        .padding()
    }
    
    // MARK: - Delete Report
    
    @ViewBuilder
    private func DeleteReportButton() -> some View {
        Button(role: .destructive) {
            deleteReport()
        } label: {
            Text("Delete Report")
            Image(systemName: "trash")
        }
        .padding()
    }
    
    // MARK: - Disable Notifications
    
    @ViewBuilder
    private func DisableNotificationsButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            unsubscribeFromPost()
        } label: {
            Text("Disable notifications")
                .foregroundStyle(.gray)
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(.gray)
        }
        .padding()
    }
    
    // MARK: - Enable Notifications
    
    @ViewBuilder
    private func EnableNotificationsButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            subscribeToPost()
        } label: {
            Text("Enable notifications")
                .foregroundStyle(.gray)
            Image(systemName: "bell.and.waves.left.and.right")
                .foregroundStyle(.gray)
        }
        .padding()
    }
    
    // MARK: - Report Post
    
    @ViewBuilder
    private func ReportPostButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            navCoordinator.navigate(to: .reportIssue(post))
        } label: {
            Text("Report Post")
                .foregroundStyle(.gray)
            Image(systemName: "exclamationmark.bubble")
                .foregroundStyle(.gray)
        }
        .padding()
    }
    
    //MARK: - Tag
    
    @ViewBuilder
    private func Tag() -> some View {
        if let postTag = post.postTag {
            HStack(spacing: 2) {
                Image(systemName: postTag.iconName)
                    .scaleEffect(0.8)
                
                Text(postTag.title)
                    .font(.caption)
            }
            .foregroundStyle(.gray)
        } else if post.postSource == .lostItem {
            HStack(spacing: 2) {
                Image(systemName: "magnifyingglass")
                    .scaleEffect(0.8)
                
                Text("Lost Something")
                    .font(.caption)
            }
            .foregroundStyle(.red)
        } else if post.postSource == .report {
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.bubble")
                    .scaleEffect(0.8)
                
                Text("Incident Report")
                    .font(.caption)
            }
            .foregroundStyle(.red)
        }
    }
    
    //MARK: - Text
    
    @ViewBuilder
    private func TextView() -> some View {
        VStack(alignment: .leading) {
            if post.wasFound == false {
                Text("Help me to find my... ")
                    .font(.callout)
                    .foregroundStyle(.gray)
            }
            
            if let text = post.text {
                Text(LocalizedStringKey(text))
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            handleOnTapGesture()
        }
    }
    
    //MARK: - Image Preview
    
    @ViewBuilder
    private func MediaPreview() -> some View {
        if let url = post.videoUrl {
            PostVideoView(
                postId: post.id,
                videoURL: url,
                thumbnailURL: post.videoThumbnailUrl
            )
            .frame(maxWidth: .infinity)
            .cornerRadius(8)
        } else if let url = post.imageUrl {
            PostImageView(imageURL: url, usesFeedLayout: true)
                .frame(maxWidth: .infinity)
                .cornerRadius(8)
        }
    }
    
    //MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        if post.postSource == .publication {
            RealPostFooter()
        } else {
            NotRealPostFooter()
        }
    }
    
    // MARK: - Post Footer
    
    @ViewBuilder
    private func RealPostFooter() -> some View {
        HStack(spacing: 24) {
            Likes()
            
            Comments()

            Views()
            
            Map()
            
            Spacer()
        }
    }

    @ViewBuilder
    private func Views() -> some View {
        let label = HStack(spacing: 5) {
            Image(systemName: "eye")
            Text(String(post.resolvedUniqueViewCount))
                .font(.subheadline)
        }
        .foregroundStyle(.gray)

        if post.isFromRecipientUser {
            Button { isViewersPresented = true } label: { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }
    
    // MARK: - Likes
    
    @ViewBuilder
    private func Likes() -> some View {
        HStack {
            HeartView(isLiked:  Binding(
                get: { post.didLike ?? false },
                set: { post.didLike = $0 }
            )) {
                handleLikeButtonTapGesture()
            }
            
            Text(String(post.likes ?? 0))
                .font(.subheadline)
                .foregroundColor(.gray)
                .onTapGesture {
                    navCoordinator.navigate(to: .like(post))
                }
        }
    }
    
    // MARK: - Comments
    
    @ViewBuilder
    private func Comments() -> some View {
        HStack {
            Image(systemName: "bubble.left")
                .foregroundColor(.gray)
            
            Text(String(post.comment ?? 0))
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Map
    
    @ViewBuilder
    private func Map() -> some View {
        if post.isLocationVisible ?? false, let distance = post.formattedDistanceToMe {
            HStack {
                Image(systemName: "map")
                    .foregroundStyle(.gray)
                
                Text(distance)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .onTapGesture {
                navCoordinator.navigate(to: .postMap(post))
            }
        }
    }
    
    // MARK: - Not Real Post Footer
    
    @ViewBuilder
    private func NotRealPostFooter() -> some View {
        HStack {
            if post.wasFound == true {
                ItemFound()
            } else {
                SeeDetails()
            }
            
            Spacer()
        }
    }
    
    // MARK: - See Details
    
    @ViewBuilder
    private func SeeDetails() -> some View {
        Button {
            displayDetails()
        } label: {
            HStack {
                Text("See Details")
                Image(systemName: "chevron.forward")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 12)
            }
        }
    }
    
    // MARK: - Item Found
    
    @ViewBuilder
    private func ItemFound() -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
            
            Text("Item Found")
                .font(.subheadline)
                .foregroundColor(.green)
                .bold()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.green.opacity(0.2)))
        
    }
}

@MainActor
final class FeedVideoPlaybackCoordinator: ObservableObject {
    static let shared = FeedVideoPlaybackCoordinator()
    @Published var activePostId: String?
    @Published var isMuted = true
    /// Prevents fullscreen mute/unmute from overwriting the feed mute preference.
    var ignoresPlayerMuteUpdates = false

    func resetMutePreference() {
        isMuted = true
    }
}

private struct PostVideoView: View {
    let postId: String
    let videoURL: String
    let thumbnailURL: String?

    @StateObject private var playback = FeedVideoPlaybackCoordinator.shared
    @State private var player: AVPlayer?
    @State private var isReady = false
    @State private var didFail = false
    @State private var isFullScreen = false
    @State private var mediaAspectRatio: CGFloat = 16 / 9
    @State private var statusObservation: NSKeyValueObservation?
    @State private var muteObservation: NSKeyValueObservation?
    @State private var endObserver: NSObjectProtocol?
    @State private var foregroundRetryAvailable = false
    @State private var shouldResumeWhenReady = false
    @State private var preservedTime: CMTime = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if !isReady || didFail {
                thumbnail
            }

            if let player, isReady, !didFail {
                NativeVideoPlayer(
                    player: isFullScreen ? nil : player,
                    showsPlaybackControls: false,
                    videoGravity: usesConstrainedAspectRatio ? .resizeAspectFill : .resizeAspect
                )
            }

            if isReady && !didFail && !isFullScreen {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isFullScreen = true
                    }
            }

            if !isReady && !didFail {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if didFail {
                VStack(spacing: 8) {
                    Label("Video unavailable", systemImage: "exclamationmark.triangle")
                    Button("Try again") {
                        foregroundRetryAvailable = false
                        shouldResumeWhenReady = playback.activePostId == postId
                        rebuildPlayer(preservingPlayback: true)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .font(.caption)
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if isReady && !didFail && !isFullScreen {
                Button {
                    playback.isMuted.toggle()
                    player?.isMuted = playback.isMuted
                } label: {
                    Image(systemName: playback.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.55), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(displayAspectRatio, contentMode: .fit)
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.frame(in: .global)) { frame in
                        updatePlayback(for: frame)
                    }
                    .onAppear {
                        updatePlayback(for: geometry.frame(in: .global))
                    }
            }
        }
        .background(.black)
        .task(id: thumbnailURL) {
            await loadThumbnailAspectRatio()
        }
        .onAppear {
            configurePlayer()
        }
        .onChange(of: playback.activePostId) { activeId in
            guard !isFullScreen else { return }
            if activeId == postId {
                if isReady {
                    player?.play()
                } else {
                    shouldResumeWhenReady = true
                }
            } else {
                player?.pause()
                shouldResumeWhenReady = false
            }
        }
        .onChange(of: playback.isMuted) { muted in
            guard !isFullScreen else { return }
            if player?.isMuted != muted {
                player?.isMuted = muted
            }
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            if let player {
                FeedFullScreenVideoPlayer(player: player)
            }
        }
        .onChange(of: isFullScreen) { fullScreen in
            if fullScreen {
                playback.activePostId = postId
                playback.ignoresPlayerMuteUpdates = true
                player?.isMuted = false
                player?.play()
            } else {
                player?.isMuted = playback.isMuted
                playback.ignoresPlayerMuteUpdates = false
                if playback.activePostId == postId {
                    player?.play()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            shouldResumeWhenReady = player?.rate ?? 0 > 0
            player?.pause()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            foregroundRetryAvailable = true
            validatePlayerAfterForeground()
        }
        .onDisappear {
            guard !isFullScreen else { return }
            player?.pause()
            if playback.activePostId == postId { playback.activePostId = nil }
            statusObservation = nil
            muteObservation = nil
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
            endObserver = nil
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let thumbnailURL, let url = URL(string: thumbnailURL) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.25)
            }
        } else {
            Color.gray.opacity(0.25)
        }
    }

    private func configurePlayer() {
        if let player, let item = player.currentItem {
            if statusObservation == nil {
                observe(item, on: player)
            }
            return
        }
        guard let url = URL(string: videoURL) else {
            didFail = true
            return
        }
        let newPlayer = AVPlayer()
        newPlayer.isMuted = playback.isMuted
        player = newPlayer
        installItem(AVPlayerItem(url: url), on: newPlayer)
    }

    private func rebuildPlayer(preservingPlayback: Bool) {
        guard let url = URL(string: videoURL) else {
            didFail = true
            return
        }
        let currentPlayer = player ?? AVPlayer()
        if player == nil { player = currentPlayer }
        currentPlayer.isMuted = isFullScreen ? false : playback.isMuted
        preservedTime = preservingPlayback ? currentPlayer.currentTime() : .zero
        shouldResumeWhenReady = preservingPlayback
            && playback.activePostId == postId
            && (currentPlayer.rate > 0 || shouldResumeWhenReady)
        isReady = false
        didFail = false
        installItem(AVPlayerItem(url: url), on: currentPlayer)
    }

    private func installItem(_ item: AVPlayerItem, on currentPlayer: AVPlayer) {
        statusObservation = nil
        muteObservation = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        currentPlayer.replaceCurrentItem(with: item)
        observe(item, on: currentPlayer)
    }

    private func observe(_ item: AVPlayerItem, on currentPlayer: AVPlayer) {
        statusObservation = item.observe(\.status, options: [.initial, .new]) { item, _ in
            DispatchQueue.main.async {
                isReady = item.status == .readyToPlay
                didFail = item.status == .failed
                if item.presentationSize.height > 0 {
                    mediaAspectRatio = item.presentationSize.width / item.presentationSize.height
                }
                if item.status == .readyToPlay {
                    foregroundRetryAvailable = false
                    if preservedTime.isValid && preservedTime.seconds.isFinite && preservedTime.seconds > 0 {
                        currentPlayer.seek(to: preservedTime)
                        preservedTime = .zero
                    }
                    if playback.activePostId == postId && shouldResumeWhenReady {
                        currentPlayer.play()
                    }
                    shouldResumeWhenReady = false
                } else if item.status == .failed && foregroundRetryAvailable {
                    foregroundRetryAvailable = false
                    rebuildPlayer(preservingPlayback: true)
                }
            }
        }
        muteObservation = currentPlayer.observe(\.isMuted, options: [.new]) { player, _ in
            DispatchQueue.main.async {
                let coordinator = FeedVideoPlaybackCoordinator.shared
                guard !coordinator.ignoresPlayerMuteUpdates else { return }
                let muted = player.isMuted
                if coordinator.isMuted != muted {
                    coordinator.isMuted = muted
                }
            }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            currentPlayer.seek(to: .zero)
            Task { @MainActor in
                if playback.activePostId == postId { currentPlayer.play() }
            }
        }
    }

    private func validatePlayerAfterForeground() {
        guard let item = player?.currentItem else {
            guard foregroundRetryAvailable else { return }
            foregroundRetryAvailable = false
            rebuildPlayer(preservingPlayback: true)
            return
        }

        if item.status == .failed || item.error != nil {
            guard foregroundRetryAvailable else { return }
            foregroundRetryAvailable = false
            rebuildPlayer(preservingPlayback: true)
        } else if item.status == .readyToPlay,
                  shouldResumeWhenReady,
                  playback.activePostId == postId {
            player?.play()
            shouldResumeWhenReady = false
        }
    }

    private func updatePlayback(for frame: CGRect) {
        guard !isFullScreen else { return }
        let visibleHeight = frame.intersection(UIScreen.main.bounds).height
        let requiredHeight = min(frame.height * 0.6, UIScreen.main.bounds.height * 0.35)
        let isVisible = frame.height > 0 && visibleHeight >= requiredHeight
        if isVisible {
            if playback.activePostId != postId { playback.activePostId = postId }
        } else if playback.activePostId == postId {
            playback.activePostId = nil
        }
    }

    private var displayAspectRatio: CGFloat {
        PostMediaLayout.constrainedAspectRatio(mediaAspectRatio)
    }

    private var usesConstrainedAspectRatio: Bool {
        abs(displayAspectRatio - mediaAspectRatio) > 0.001
    }

    private func loadThumbnailAspectRatio() async {
        guard let thumbnailURL, let url = URL(string: thumbnailURL) else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data),
              image.size.height > 0 else { return }
        mediaAspectRatio = image.size.width / image.size.height
    }
}

private struct FeedFullScreenVideoPlayer: View {
    let player: AVPlayer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DragToDismissContainer(onDismiss: { dismiss() }) {
            NativeVideoPlayer(
                player: player,
                showsPlaybackControls: true,
                videoGravity: .resizeAspect
            )
            .ignoresSafeArea()
        }
    }
}

private struct NativeVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer?
    let showsPlaybackControls: Bool
    let videoGravity: AVLayerVideoGravity

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = showsPlaybackControls
        controller.videoGravity = videoGravity
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.showsPlaybackControls = showsPlaybackControls
        controller.videoGravity = videoGravity
        if controller.player !== player {
            controller.player = player
        }
    }
}

//MARK: - Auxiliary Methods

extension PostView {
    private func handleOnTapGesture() {
        if isClickable {
            switch self.post.postSource {
            case .publication:
                print("⚠️ Clicou numa publicação!")
                navCoordinator.navigate(to: .comment(post))
            case .lostItem:
                navCoordinator.navigate(to: .lostItemDetail(post))
            case .report:
                navCoordinator.navigate(to: .reportDetail(post))
            }
        }
    }
    
    private func finishPost() {
        Task {
            do {
                let token = try await authVM.getFirebaseToken()
                try await postVM
                    .finishPublication(postId: post.id, token: token)
                delegate?.postViewDidMarkAsCompleted(post)
            } catch {
                print("❌ Error trying to finish publication.")
            }
        }
    }
    
    private func deletePost() {
        Task {
            do {
                let token = try await authVM.getFirebaseToken()
                try await postVM.deletePost(postId: post.id, token: token)
                delegate?.postViewDidDeletePublication(post)
            } catch {
                print("❌ Error trying to delete publication.")
            }
        }
    }
    
    private func deleteReport() {
        Task {
            do {
                let token = try await authVM.getFirebaseToken()
                try await postVM.deleteReport(reportId: post.id,token: token)
                delegate?.postViewDidDeleteReport(post)
            } catch {
                print("❌ Error trying to delete report.")
            }
        }
    }
    
    private func deleteLostItem() {
        Task {
            do {
                let token = try await authVM.getFirebaseToken()
                try await postVM
                    .deleteLostItem(lostItemId: post.id, token: token)
                delegate?.postViewDidDeleteLostItem(post)
            } catch {
                print("❌ Error trying to delete lost item.")
            }
        }
    }
    
    private func subscribeToPost() {
        Task {
            do {
                let token = try await authVM.getFirebaseToken()
                try await postVM.followPost(postId: self.post.id, token: token)
                delegate?.postViewDidFollow(post)
            } catch {
                print("❌ Error trying to follow post")
            }
        }
    }
    
    private func unsubscribeFromPost() {
        Task {
            do {
                let token = try await authVM.getFirebaseToken()
                try await postVM
                    .unfollowPost(postId: self.post.id, token: token)
                delegate?.postViewDidUnfollow(post)
            } catch {
                print("❌ Error trying to unfollow post")
            }
        }
    }
    
    private func displayDetails() {
        if post.postSource == .lostItem {
            navCoordinator.navigate(to: .lostItemDetail(post))
        } else if post.postSource == .report {
            navCoordinator.navigate(to: .reportDetail(post))
        }
    }
    
    private func handleLikeButtonTapGesture() {
        Task {
            if post.didLike ?? false {
                try await handleUnlikePost()
            } else {
                try await handleLikePost()
            }
        }
    }
    
    private func handleLikePost() async throws {
        do {
            try await attemptLikePost()
        } catch {
            print("❌ Error trying to like post.")
        }
    }
    
    private func attemptLikePost() async throws {
        let token = try await authVM.getFirebaseToken()
        hapticFeedback()
        post.didLike = true
        post.likes = (post.likes ?? 0) + 1
        try await postVM.likePublication(publicationId: post.id, token: token)
        delegate?.postViewDidLikePublication(post)
    }
    
    private func handleUnlikePost() async throws {
        do {
            try await attemptUnlikePost()
        } catch {
            print("❌ Error trying to unlike post.")
        }
    }
    
    private func attemptUnlikePost() async throws {
        let token = try await authVM.getFirebaseToken()
        post.didLike = false
        post.likes = (post.likes ?? 1) - 1
        try await postVM.unlikePublication(publicationId: post.id, token: token)
        delegate?.postViewDidUnlikePublication(post)
    }
}

//#Preview {
//    PostView(
//        post: .constant(FormattedPost(
//            id: "680006cd9c7c5a27d55e6a34",
//            userUid: "ntDPci9E8ZURHYcqFfektUSFWw53",
//            userProfilePic: "https://www.apple.com/leadership/images/bio/tim-cook_image.png.og.png?1736784653666",
//            username: "ordozgoite",
//            timestamp: 1744832205133,
//            expirationDate: 1744918605133,
//            text: "AirPods Pro 2ª geração",
//            likes: nil,
//            didLike: nil,
//            comment: nil,
//            latitude: -60.022406872388324,
//            longitude: -3.1263690427109263,
//            distanceToMe: nil,
//            isFromRecipientUser: false,
//            isLocationVisible: false,
//            tag: nil,
//            imageUrl: "https://m.media-amazon.com/images/I/51OoKCakCfL._AC_UF350,350_QL80_.jpg",
//            isOwnerFarAway: nil,
//            isFinished: nil,
//            duration: nil,
//            isSubscribed: nil,
//            source: "lostItem"
//        )),
//        isClickable: false, deletePost: {},
//        toggleFeedUpdate: { _ in }
//    )
//    .environmentObject(AuthenticationViewModel())
//}

//"https:\/\/firebasestorage.googleapis.com:443\/v0\/b\/aroundyou-b8364.appspot.com\/o\/post-image%2F32A37A97-A770-4103-80BF-4614736B2706.jpg?alt=media&token=d4d6ac06-73a9-4805-8a48-7218f8a334dc"

//"https:\/\/firebasestorage.googleapis.com:443\/v0\/b\/aroundyou-b8364.appspot.com\/o\/post-image%2F6014DE96-A1DF-485D-BC5F-A1D1AC35CF71.jpg?alt=media&token=cafbcd10-81bf-48af-9e25-39e06d05143a"
