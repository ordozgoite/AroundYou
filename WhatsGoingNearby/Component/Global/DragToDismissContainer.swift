//
//  DragToDismissContainer.swift
//  WhatsGoingNearby
//

import SwiftUI
import UIKit

struct DragToDismissContainer<Content: View, Chrome: View>: View {
    var isEnabled: Bool = true
    let onDismiss: () -> Void
    @ViewBuilder var content: () -> Content
    @ViewBuilder var chrome: () -> Chrome

    @State private var chromeOpacity: CGFloat = 1

    var body: some View {
        ZStack {
            DragToDismissRepresentable(
                isEnabled: isEnabled,
                onDismiss: onDismiss,
                onProgressChanged: { progress in
                    chromeOpacity = 1 - progress
                },
                content: content
            )
            .ignoresSafeArea()

            chrome()
                .opacity(chromeOpacity)
        }
        .presentationBackground(.clear)
    }
}

extension DragToDismissContainer where Chrome == EmptyView {
    init(
        isEnabled: Bool = true,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            isEnabled: isEnabled,
            onDismiss: onDismiss,
            content: content,
            chrome: { EmptyView() }
        )
    }
}

private struct DragToDismissRepresentable<Content: View>: UIViewControllerRepresentable {
    let isEnabled: Bool
    let onDismiss: () -> Void
    let onProgressChanged: (CGFloat) -> Void
    let content: () -> Content

    func makeUIViewController(context: Context) -> DragToDismissHostController<Content> {
        let controller = DragToDismissHostController(rootView: content())
        controller.isDismissEnabled = isEnabled
        controller.onDismiss = onDismiss
        controller.onProgressChanged = onProgressChanged
        return controller
    }

    func updateUIViewController(_ controller: DragToDismissHostController<Content>, context: Context) {
        controller.isDismissEnabled = isEnabled
        controller.onDismiss = onDismiss
        controller.onProgressChanged = onProgressChanged
        controller.updateRootView(content())
    }
}

private final class DragToDismissHostController<Content: View>: UIViewController, UIGestureRecognizerDelegate {
    private let dimmingView = UIView()
    private let contentContainer = UIView()
    private var hostingController: UIHostingController<Content>
    private var panGesture: UIPanGestureRecognizer!
    private var isDismissing = false

    var isDismissEnabled = true
    var onDismiss: (() -> Void)?
    var onProgressChanged: ((CGFloat) -> Void)?

    private let dismissDistance: CGFloat = 120
    private let dismissVelocity: CGFloat = 900

    init(rootView: Content) {
        hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateRootView(_ rootView: Content) {
        hostingController.rootView = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.clipsToBounds = true

        dimmingView.backgroundColor = .black
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmingView)

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.backgroundColor = .clear
        view.addSubview(contentContainer)

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        contentContainer.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            hostingController.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor)
        ])

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isDismissEnabled, !isDismissing else { return false }
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: view)
        return abs(velocity.y) > abs(velocity.x)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UIControl)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            panGesture.cancelsTouchesInView = true

        case .changed:
            applyDrag(offsetY: translation.y)

        case .ended, .cancelled, .failed:
            panGesture.cancelsTouchesInView = false
            if shouldDismiss(offset: translation.y, velocity: velocity.y) {
                finishDismiss(currentY: translation.y, velocityY: velocity.y)
            } else {
                springBack()
            }

        default:
            break
        }
    }

    private func progress(for offset: CGFloat) -> CGFloat {
        let height = max(view.bounds.height, 1)
        return min(abs(offset) / (height * 0.28), 1)
    }

    private func applyDrag(offsetY: CGFloat) {
        let progress = progress(for: offsetY)
        let scale = 1 - progress * 0.1
        contentContainer.transform = CGAffineTransform(translationX: 0, y: offsetY)
            .scaledBy(x: scale, y: scale)
        dimmingView.alpha = 1 - progress * 0.85
        onProgressChanged?(progress)
    }

    private func shouldDismiss(offset: CGFloat, velocity: CGFloat) -> Bool {
        abs(offset) > dismissDistance || abs(velocity) > dismissVelocity
    }

    private func springBack() {
        UIView.animate(
            withDuration: 0.38,
            delay: 0,
            usingSpringWithDamping: 0.84,
            initialSpringVelocity: 0.35,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.contentContainer.transform = .identity
            self.dimmingView.alpha = 1
        } completion: { _ in
            self.onProgressChanged?(0)
        }
    }

    private func finishDismiss(currentY: CGFloat, velocityY: CGFloat) {
        guard !isDismissing else { return }
        isDismissing = true

        let direction: CGFloat
        if abs(currentY) > 1 {
            direction = currentY >= 0 ? 1 : -1
        } else {
            direction = velocityY >= 0 ? 1 : -1
        }

        let targetY = direction * (view.bounds.height + contentContainer.bounds.height * 0.15)
        let distance = abs(targetY - currentY)
        let speed = max(abs(velocityY), 700)
        let duration = min(max(TimeInterval(distance / speed), 0.18), 0.32)

        onProgressChanged?(1)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseIn, .beginFromCurrentState]
        ) {
            self.contentContainer.transform = CGAffineTransform(translationX: 0, y: targetY)
            self.dimmingView.alpha = 0
        } completion: { _ in
            self.onDismiss?()
        }
    }
}
