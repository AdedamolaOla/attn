import SwiftUI
import UserNotifications

/// First-launch experience for ATTN.
///
/// This flow intentionally keeps the product promise ahead of the implementation:
/// understand → trust → permission → proof → habit. Each surface follows the
/// annotated motion guidance from the Figma source and has a Reduce Motion path.
public struct OnboardingFlowView: View {
    @State private var step: OnboardingStep = .welcome
    private let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            switch step {
            case .welcome:
                OnboardingWelcomeScreen {
                    advance(to: .confirming)
                }
            case .confirming:
                OnboardingConfirmScreen(
                    onConfirm: { advance(to: .analyzing) },
                    onDisconnect: { advance(to: .welcome) }
                )
            case .analyzing:
                OnboardingAnalysisScreen {
                    advance(to: .results)
                }
            case .results:
                OnboardingResultsScreen {
                    onComplete()
                }
            }
        }
        .id(step)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.24), value: step)
        .preferredColorScheme(.dark)
    }

    private func advance(to next: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.24)) {
            step = next
        }
    }

    private enum OnboardingStep: Hashable {
        case welcome
        case confirming
        case analyzing
        case results
    }
}

private let attnBlue = Color(red: 0.0, green: 159.0 / 255.0, blue: 1.0)
private let attnCream = Color(red: 249.0 / 255.0, green: 251.0 / 255.0, blue: 227.0 / 255.0)
private let attnInk = Color(red: 20.0 / 255.0, green: 22.0 / 255.0, blue: 28.0 / 255.0)

private struct OnboardingWelcomeScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [attnBlue, attnCream],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 36)

                OnboardingMailStack(isVisible: isVisible, reduceMotion: reduceMotion)
                    .frame(height: 262)

                VStack(spacing: 12) {
                    Text("Know what deserves\nyour attention.")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .tracking(-1.1)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .opacity(reduceMotion || isVisible ? 1 : 0)
                        .offset(y: reduceMotion || isVisible ? 0 : 10)
                        .animation(.easeOut(duration: 0.34).delay(0.28), value: isVisible)

                    Text("attn quietly finds important emails\nbefore they become problems.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.86))
                        .opacity(reduceMotion || isVisible ? 1 : 0)
                        .offset(y: reduceMotion || isVisible ? 0 : 8)
                        .animation(.easeOut(duration: 0.32).delay(0.36), value: isVisible)
                }

                Spacer(minLength: 28)
            }
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 12) {
                OnboardingPrimaryButton("Connect your mail", systemImage: "envelope.fill", action: onContinue)
                    .accessibilityLabel("Connect Gmail")

                Text("Read-only access. Disconnect anytime.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(attnInk.opacity(0.56))
                    .frame(maxWidth: .infinity)
                    .opacity(reduceMotion || isVisible ? 1 : 0)
                    .offset(y: reduceMotion || isVisible ? 0 : 8)
                    .animation(.easeOut(duration: 0.3).delay(0.48), value: isVisible)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 12)
            .background(.white)
        }
        .onAppear {
            guard !reduceMotion else {
                isVisible = true
                return
            }
            withAnimation(.spring(response: 0.56, dampingFraction: 0.82).delay(0.06)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct OnboardingMailStack: View {
    let isVisible: Bool
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            InboxPreviewCard(
                title: "Payment due",
                timing: "Today · 11:59 PM",
                source: "RBC Mastercard",
                tint: Color.white.opacity(0.88),
                rotation: -9,
                offset: CGSize(width: -52, height: 30),
                entrance: CGSize(width: -84, height: 44),
                visible: isVisible,
                reduceMotion: reduceMotion,
                delay: 0.02
            )
            InboxPreviewCard(
                title: "Flight check-in",
                timing: "Opens in 3 hours",
                source: "Air Canada",
                tint: Color.white.opacity(0.94),
                rotation: 5,
                offset: CGSize(width: 46, height: 6),
                entrance: CGSize(width: 80, height: 34),
                visible: isVisible,
                reduceMotion: reduceMotion,
                delay: 0.08
            )
            InboxPreviewCard(
                title: "Interview",
                timing: "Tomorrow · 9:30 AM",
                source: "Google Meet",
                tint: .white,
                rotation: -1,
                offset: .zero,
                entrance: CGSize(width: 0, height: 52),
                visible: isVisible,
                reduceMotion: reduceMotion,
                delay: 0.14
            )
        }
        .accessibilityHidden(true)
    }
}

private struct InboxPreviewCard: View {
    let title: String
    let timing: String
    let source: String
    let tint: Color
    let rotation: Double
    let offset: CGSize
    let entrance: CGSize
    let visible: Bool
    let reduceMotion: Bool
    let delay: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(attnBlue)
                    .frame(width: 28, height: 28)
                    .background(attnBlue.opacity(0.11), in: RoundedRectangle(cornerRadius: 9))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(attnInk.opacity(0.42))
            }
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(attnInk)
            Text(timing)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(attnInk.opacity(0.62))
            Text(source)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(attnInk.opacity(0.44))
        }
        .padding(18)
        .frame(width: 228, height: 164, alignment: .topLeading)
        .background(tint, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 22, y: 12)
        .rotationEffect(.degrees(rotation))
        .offset(
            x: reduceMotion || visible ? offset.width : offset.width + entrance.width,
            y: reduceMotion || visible ? offset.height : offset.height + entrance.height
        )
        .scaleEffect(reduceMotion || visible ? 1 : 0.92)
        .opacity(reduceMotion || visible ? 1 : 0)
        .animation(
            .spring(response: 0.56, dampingFraction: 0.78).delay(delay),
            value: visible
        )
    }
}

private struct OnboardingConfirmScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onConfirm: () -> Void
    let onDisconnect: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [attnBlue, .white],
                stops: [0, 0.70],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    CloseControl(action: onDisconnect)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer(minLength: 24)

                VStack(spacing: 12) {
                    Text("Confirm your Gmail account")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("Make sure this is the inbox you want attn to monitor.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.84))
                        .padding(.horizontal, 28)
                }

                Spacer(minLength: 22)

                IdentityFloat(reduceMotion: reduceMotion)
                    .frame(maxWidth: .infinity)
                    .frame(height: 224)

                Spacer(minLength: 20)

                VStack(spacing: 12) {
                    OnboardingPrimaryButton("Confirm email", systemImage: "checkmark", action: {
                        AttnHaptics.impactLight()
                        onConfirm()
                    })
                    OnboardingSecondaryButton("Disconnect", systemImage: "xmark", action: onDisconnect)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
    }
}

private struct IdentityFloat: View {
    let reduceMotion: Bool

    var body: some View {
        Group {
            if reduceMotion {
                identityContent(offset: .zero, scale: 1)
            } else {
                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let phase = t.truncatingRemainder(dividingBy: 7.6) / 7.6 * Double.pi * 2
                    identityContent(
                        offset: CGSize(width: sin(phase) * 2.5, height: cos(phase * 0.82) * 2.2),
                        scale: 1.004 + sin(phase * 0.5) * 0.002
                    )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Liam Oliver, Liamoliver@gmail.com")
    }

    @ViewBuilder
    private func identityContent(offset: CGSize, scale: Double) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.60)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 126, height: 126)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.55), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.10), radius: 18, y: 10)

                Image(systemName: "person.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(attnBlue.opacity(0.78))
            }

            VStack(spacing: 5) {
                Text("Liam Oliver")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(attnInk)
                Text("Liamoliver@gmail.com")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(attnInk.opacity(0.58))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.white.opacity(0.76), in: Capsule())
        }
        .offset(offset)
        .scaleEffect(scale)
    }
}

private struct OnboardingAnalysisScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress = 1
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [attnBlue, .white],
                stops: [0, 0.70],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    CloseControl(action: {})
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                AnalysisOrb(progress: progress, reduceMotion: reduceMotion)
                    .frame(width: 210, height: 210)

                Text("Analyzing your inbox & finding the few messages that deserve your attention.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(attnInk.opacity(0.68))
                    .padding(.horizontal, 42)

                Spacer()
                Spacer(minLength: 28)
            }
        }
        .task {
            let stages: [(Int, UInt64)] = [
                (18, 280_000_000),
                (42, 420_000_000),
                (68, 650_000_000),
                (84, 800_000_000),
                (94, 760_000_000)
            ]
            for stage in stages {
                try? await Task.sleep(nanoseconds: stage.1)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.28)) {
                    progress = stage.0
                }
            }
            try? await Task.sleep(nanoseconds: 560_000_000)
            guard !Task.isCancelled else { return }
            onComplete()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Analyzing your inbox")
    }
}

private struct AnalysisOrb: View {
    let progress: Int
    let reduceMotion: Bool

    var body: some View {
        Group {
            if reduceMotion {
                orbContent(time: 0)
            } else {
                TimelineView(.animation) { context in
                    orbContent(time: context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Inbox analysis, \(progress) percent")
    }

    @ViewBuilder
    private func orbContent(time: TimeInterval) -> some View {
        let phaseA = time / 8.5
        let phaseB = time / 10.5
        let phaseC = time / 13.0
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.92), attnBlue.opacity(0.72), Color.white.opacity(0.35)],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 150
                    )
                )
                .blur(radius: 0.5)

            Circle()
                .fill(Color(red: 0.25, green: 0.84, blue: 1.0).opacity(0.54))
                .frame(width: 134, height: 134)
                .blur(radius: 25)
                .offset(x: CGFloat(sin(phaseA) * 24), y: CGFloat(cos(phaseA * 0.9) * 19))

            Circle()
                .fill(Color(red: 0.98, green: 0.58, blue: 0.32).opacity(0.42))
                .frame(width: 118, height: 118)
                .blur(radius: 29)
                .offset(x: CGFloat(cos(phaseB) * 20), y: CGFloat(sin(phaseB * 0.82) * 24))

            Circle()
                .fill(Color.white.opacity(0.62))
                .frame(width: 106, height: 106)
                .blur(radius: 24)
                .offset(x: CGFloat(sin(phaseC * 0.76) * 26), y: CGFloat(cos(phaseC) * 17))

            VStack(spacing: 4) {
                Text("\(progress)%")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("finding priorities")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
            }
        }
        .clipShape(Circle())
        .overlay {
            Circle().stroke(.white.opacity(0.48), lineWidth: 1)
        }
        .shadow(color: attnBlue.opacity(0.26), radius: 22, y: 12)
    }
}

private struct OnboardingResultsScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var didHaptic = false
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [attnBlue.opacity(0.96), .white],
                stops: [0, 0.80],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 54)

                VStack(spacing: 10) {
                    Text("14 emails")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Text("Need your attention")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.88))
                }
                .opacity(reduceMotion || isVisible ? 1 : 0)
                .offset(y: reduceMotion || isVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.32).delay(0.20), value: isVisible)

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.25))
                        .frame(height: 288)
                        .rotationEffect(.degrees(-4))
                        .offset(y: reduceMotion || isVisible ? 30 : 58)
                        .opacity(reduceMotion || isVisible ? 0.46 : 0)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.34))
                        .frame(height: 288)
                        .rotationEffect(.degrees(3))
                        .offset(y: reduceMotion || isVisible ? 16 : 46)
                        .opacity(reduceMotion || isVisible ? 0.62 : 0)
                    ResultsSummaryCard()
                        .offset(y: reduceMotion || isVisible ? 0 : 50)
                        .scaleEffect(reduceMotion || isVisible ? 1 : 0.965)
                        .opacity(reduceMotion || isVisible ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .animation(.spring(response: 0.48, dampingFraction: 0.86).delay(0.18), value: isVisible)

                Spacer(minLength: 20)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 12) {
                OnboardingPrimaryButton("View Priority Inbox", systemImage: "arrow.right", action: onContinue)
                    .accessibilityHint("See the priorities ATTN found in your inbox.")
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 12)
            .background(.white)
        }
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.easeOut(duration: 0.32)) {
                    isVisible = true
                }
            }
            guard !didHaptic else { return }
            didHaptic = true
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.62)) {
                AttnHaptics.success()
            }
        }
    }
}

private struct ResultsSummaryCard: View {
    var body: some View {
        VStack(spacing: 0) {
            ResultsSummaryRow(
                count: "3 emails due today",
                title: "Action needed today",
                symbol: "exclamationmark.circle.fill",
                color: .orange
            )
            DashedResultsDivider()
            ResultsSummaryRow(
                count: "2 emails due this week",
                title: "Calendar follow-ups",
                symbol: "calendar",
                color: attnBlue
            )
            DashedResultsDivider()
            ResultsSummaryRow(
                count: "2 FYI / low priority",
                title: "No immediate action",
                symbol: "checkmark.circle.fill",
                color: .green
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 24, y: 14)
    }
}

private struct ResultsSummaryRow: View {
    let count: String
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(count)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(attnInk)
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(attnInk.opacity(0.56))
            }
            Spacer()
        }
        .padding(.vertical, 14)
    }
}

private struct DashedResultsDivider: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: proxy.size.width, y: 0.5))
            }
            .stroke(attnInk.opacity(0.14), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 5]))
        }
        .frame(height: 1)
    }
}

private struct CloseControl: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(attnInk.opacity(0.76))
                .frame(width: 50, height: 50)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.38), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }
}

private struct OnboardingPrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.glassProminent)
        .tint(attnInk)
        .accessibilityAddTraits(.isButton)
    }
}

private struct OnboardingSecondaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.glass)
        .foregroundStyle(attnInk.opacity(0.82))
    }
}

/// Optional post-results teaching surface. It is intentionally reusable so the
/// app can present it after the first result or from Settings without duplicating
/// the widget education experience.
public struct WidgetSetupView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    private let onAdd: () -> Void
    private let onSkip: () -> Void

    public init(onAdd: @escaping () -> Void = {}, onSkip: @escaping () -> Void = {}) {
        self.onAdd = onAdd
        self.onSkip = onSkip
    }

    public var body: some View {
        ZStack {
            Color(red: 25.0 / 255.0, green: 26.0 / 255.0, blue: 31.0 / 255.0)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 36)
                Image("attn-widget", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .opacity(reduceMotion || isVisible ? 1 : 0)
                    .offset(y: reduceMotion || isVisible ? 0 : 12)
                    .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Keep what matters within reach")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    Text("Add the widget to your Home Screen to see your most important priorities without opening the app.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.68))
                        .padding(.horizontal, 28)
                }
                Spacer()
                VStack(spacing: 12) {
                    OnboardingPrimaryButton("Add Widget", systemImage: "plus", action: {
                        AttnHaptics.success()
                        onAdd()
                    })
                    OnboardingSecondaryButton("Maybe later", action: onSkip)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.easeOut(duration: 0.26)) {
                    isVisible = true
                }
            }
        }
    }
}

/// Optional post-results permission education. We explain the value before
/// invoking the system sheet and only request authorization in response to the
/// explicit action.
public struct NotificationSetupView: View {
    private let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            Color(red: 25.0 / 255.0, green: 26.0 / 255.0, blue: 31.0 / 255.0)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 44)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 116, height: 116)
                    .background(attnBlue.opacity(0.24), in: Circle())
                    .overlay { Circle().stroke(.white.opacity(0.12), lineWidth: 1) }
                    .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Stay ahead of what matters")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    Text("Turn on notifications and attn will let you know when something important needs your attention.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.68))
                        .padding(.horizontal, 22)
                }
                Spacer()
                VStack(spacing: 12) {
                    OnboardingPrimaryButton("Turn On Notifications", systemImage: "bell.fill", action: requestNotifications)
                    OnboardingSecondaryButton("Maybe later", action: onComplete)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func requestNotifications() {
        AttnHaptics.impactLight()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            DispatchQueue.main.async {
                onComplete()
            }
        }
    }
}
