import SwiftUI

/// Identity returned by the future Gmail authorization step.
public struct GmailAccountIdentity: Equatable, Sendable {
    public let name: String
    public let email: String

    public init(name: String, email: String) {
        self.name = name
        self.email = email
    }

    /// Figma identity used while the Google authorization flow is still mocked.
    public static let prototype = GmailAccountIdentity(
        name: "Liam Oliver",
        email: "liamoliver@gmail.com"
    )
}

/// Lets a user verify which Gmail account will be analyzed.
@MainActor
public struct ConfirmAccountView: View {
    private let identity: GmailAccountIdentity
    private let onConfirm: () -> Void
    private let onDisconnect: () -> Void
    private let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 14

    @State private var identityVisible = false
    @State private var identityFloating = false
    @State private var isConfirming = false

    public init(
        identity: GmailAccountIdentity,
        onConfirm: @escaping () -> Void,
        onDisconnect: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.identity = identity
        self.onConfirm = onConfirm
        self.onDisconnect = onDisconnect
        self.onCancel = onCancel
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                OnboardingGradientBackground(
                    bottomColor: .white,
                    bottomColorLocation: 0.698
                )

                confirmationCopy(width: size.width)
                    .position(x: size.width / 2, y: size.height * 0.255)

                identityMotion
                    .frame(width: 147, height: 147)
                    .opacity(identityVisible ? 1 : 0)
                    .scaleEffect(identityVisible ? 1 : 0.96)
                    .position(x: size.width / 2, y: size.height * 0.5)
                    .animation(.easeOut(duration: 0.32), value: identityVisible)

                actionButtons(width: max(0, size.width - 40))
                    .frame(width: max(0, size.width - 40), height: 112)
                    .position(x: size.width / 2, y: size.height - 86)

                closeButton
                    .position(x: size.width - 45, y: size.height * (99.0 / 852.0))
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .task {
            await revealIdentity()
        }
    }

    private func confirmationCopy(width: CGFloat) -> some View {
        VStack(spacing: 9) {
            Text("Confirm your Gmail account")
                .font(.system(size: titleSize, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("Make sure this is the inbox you want attn to monitor.")
                .font(.system(size: bodySize, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: min(width - 48, 310))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: min(width - 40, 360))
    }

    @ViewBuilder
    private var identityMotion: some View {
        if identityFloating && !reduceMotion && !isConfirming {
            KeyframeAnimator(initialValue: IdentityFloatValues(), repeating: true) { value in
                identityArtwork
                    .offset(x: value.x, y: value.y)
                    .scaleEffect(value.scale)
                    .rotationEffect(.degrees(Double(value.rotation)))
            } keyframes: { _ in
                KeyframeTrack(\.x) {
                    CubicKeyframe(2.5, duration: 1.5)
                    CubicKeyframe(-1.5, duration: 1.7)
                    CubicKeyframe(-3, duration: 1.7)
                    CubicKeyframe(0, duration: 2.6)
                }
                KeyframeTrack(\.y) {
                    CubicKeyframe(-2, duration: 1.5)
                    CubicKeyframe(-3, duration: 1.7)
                    CubicKeyframe(1.5, duration: 1.7)
                    CubicKeyframe(0, duration: 2.6)
                }
                KeyframeTrack(\.scale) {
                    CubicKeyframe(1.004, duration: 1.5)
                    CubicKeyframe(1.006, duration: 1.7)
                    CubicKeyframe(1.003, duration: 1.7)
                    CubicKeyframe(1, duration: 2.6)
                }
                KeyframeTrack(\.rotation) {
                    CubicKeyframe(0.25, duration: 1.5)
                    CubicKeyframe(-0.3, duration: 1.7)
                    CubicKeyframe(0.2, duration: 1.7)
                    CubicKeyframe(0, duration: 2.6)
                }
            }
        } else {
            identityArtwork
        }
    }

    private var identityArtwork: some View {
        ZStack(alignment: .topLeading) {
            avatarPlaceholder
                .frame(width: 147, height: 147)
                .position(x: 73.5, y: 73.5)

            identityBadge(identity.name)
                .position(x: 0, y: 31)

            identityBadge(identity.email)
                .position(x: 144, y: 122)
        }
        .frame(width: 147, height: 147)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Connected account, \(identity.name), \(identity.email)")
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 47 / 255, green: 40 / 255, blue: 142 / 255),
                        Color(red: 132 / 255, green: 31 / 255, blue: 170 / 255),
                        Color(red: 17 / 255, green: 133 / 255, blue: 225 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 74, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
                    .offset(y: 10)
                    .accessibilityHidden(true)
            }
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            }
            .overlay {
                Circle()
                    .stroke(Color(red: 89 / 255, green: 89 / 255, blue: 89 / 255).opacity(0.25), lineWidth: 8)
                    .blur(radius: 6.5)
                    .offset(y: 1)
                    .clipShape(Circle())
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            }
            .clipShape(Circle())
    }

    private func identityBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(red: 145 / 255, green: 145 / 255, blue: 145 / 255))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.white, in: Capsule())
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
            .accessibilityHidden(true)
    }

    private func actionButtons(width: CGFloat) -> some View {
        VStack(spacing: 10) {
            OnboardingActionButton(title: "Confirm email", tone: .primary) {
                confirmAccount()
            }
            OnboardingActionButton(title: "Disconnect", tone: .destructive, height: 50, action: onDisconnect)
        }
        .frame(width: width)
        .accessibilityElement(children: .contain)
    }

    private var closeButton: some View {
        Button(action: onCancel) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(red: 27 / 255, green: 27 / 255, blue: 27 / 255).opacity(0.82))
                .frame(width: 50, height: 50)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .environment(\.colorScheme, .light)
        .accessibilityLabel("Cancel account confirmation")
        .accessibilityHint("Returns to connect your mail.")
    }

    private func confirmAccount() {
        guard !isConfirming else { return }
        AttnHaptics.selection()
        withAnimation(.easeOut(duration: 0.2)) {
            isConfirming = true
            identityFloating = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            onConfirm()
        }
    }

    private func revealIdentity() async {
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            identityVisible = true
        }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled, !reduceMotion else { return }
        identityFloating = true
    }
}

private struct IdentityFloatValues: Animatable {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var scale: CGFloat = 1
    var rotation: CGFloat = 0

    var animatableData: AnimatablePair<
        CGFloat,
        AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>
    > {
        get {
            AnimatablePair(x, AnimatablePair(y, AnimatablePair(scale, rotation)))
        }
        set {
            x = newValue.first
            y = newValue.second.first
            scale = newValue.second.second.first
            rotation = newValue.second.second.second
        }
    }
}

#Preview("Confirm account") {
    ConfirmAccountView(
        identity: .prototype,
        onConfirm: {},
        onDisconnect: {},
        onCancel: {}
    )
}
