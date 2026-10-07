import SwiftUI

/// A visual, post-Gmail-connection analysis state.
/// The percentage is a timed prototype and is not connected to Gmail processing.
public struct InboxAnalysisView: View {
    private let startDate: Date
    private let onContinue: () -> Void
    private let onAnalysisFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingCompletion = false
    @State private var analysisSceneVisible = true

    private let analysisDuration: TimeInterval = 6

    public init(
        startDate: Date = Date(),
        onContinue: @escaping () -> Void = {},
        onAnalysisFinished: @escaping () -> Void = {}
    ) {
        self.startDate = startDate
        self.onContinue = onContinue
        self.onAnalysisFinished = onAnalysisFinished
    }

    public var body: some View {
        ZStack {
            InboxAnalysisBackground()

            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let elapsed = max(0, timeline.date.timeIntervalSince(startDate))
                let progress = showingCompletion
                    ? 100
                    : min(99, 1 + Int((min(elapsed, analysisDuration) / analysisDuration) * 98))
                let phase = reduceMotion ? 0 : elapsed * (2 * .pi / 8.5)

                VStack(spacing: 16) {
                    analysisOrb(progress: progress, phase: phase)

                    Text("Analyzing your inbox & finding the few\nmessages that deserve your attn.")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundStyle(Color(hex: 0x77767E))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(width: 280)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -25)
                .opacity(analysisSceneVisible ? 1 : 0)
                .scaleEffect(analysisSceneVisible ? 1 : 0.96)
                .animation(
                    reduceMotion ? .easeOut(duration: 0.12) : .easeOut(duration: 0.22),
                    value: analysisSceneVisible
                )
            }

            closeButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 14)
                .padding(.trailing, 24)
                .opacity(analysisSceneVisible ? 1 : 0)
                .animation(
                    reduceMotion ? .easeOut(duration: 0.12) : .easeOut(duration: 0.22),
                    value: analysisSceneVisible
                )
        }
        .preferredColorScheme(.light)
        .task(id: startDate) {
            await finishAnalysis()
        }
    }

    private func analysisOrb(progress: Int, phase: TimeInterval) -> some View {
        GeometryReader { geometry in
            let size = geometry.size
            // The glass bulb stays still. Only its three soft color fields drift.
            let yellowX = 0.35 + 0.16 * CGFloat(sin(phase * 0.78))
            let yellowY = 0.36 + 0.12 * CGFloat(cos(phase * 0.64))
            let blueX = 0.67 + 0.15 * CGFloat(sin(phase * 0.71 + 2.2))
            let blueY = 0.65 + 0.14 * CGFloat(cos(phase * 0.83 + 1.2))
            let whiteX = 0.50 + 0.11 * CGFloat(sin(phase * 0.53 + 4.3))
            let whiteY = 0.49 + 0.10 * CGFloat(cos(phase * 0.62 + 2.8))

            ZStack {
                Circle()
                    .fill(Color.white)

                blurredColorCircle(
                    Color(hex: 0xFFD600),
                    diameter: 142,
                    blur: 42,
                    opacity: 1,
                    size: size,
                    x: yellowX,
                    y: yellowY
                )

                blurredColorCircle(
                    Color(hex: 0x009FFE),
                    diameter: 142,
                    blur: 42,
                    opacity: 1,
                    size: size,
                    x: blueX,
                    y: blueY
                )

                blurredColorCircle(
                    .white,
                    diameter: 84,
                    blur: 30,
                    opacity: 0.78,
                    size: size,
                    x: whiteX,
                    y: whiteY
                )
            }
            .frame(width: size.width, height: size.height)
            .clipShape(Circle())
            // Keep the existing inner shadow fixed to the outer bulb.
            .overlay {
                Circle()
                    .stroke(Color(hex: 0x595959).opacity(0.25), lineWidth: 8)
                    .blur(radius: 6.5)
                    .offset(x: 0, y: -1)
                    .clipShape(Circle())
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            }
            .compositingGroup()
            .overlay {
                Text(String(progress) + "%")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundStyle(Color(hex: 0x1B1B1B))
                    .contentTransition(.numericText())
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Analyzing your inbox, \(progress) percent")
        }
        .frame(width: 203, height: 203)
    }

    private func blurredColorCircle(
        _ color: Color,
        diameter: CGFloat,
        blur: CGFloat,
        opacity: Double,
        size: CGSize,
        x: CGFloat,
        y: CGFloat
    ) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .blur(radius: blur)
            .opacity(opacity)
            .position(x: size.width * x, y: size.height * y)
            .allowsHitTesting(false)
    }

    private var closeButton: some View {
        OnboardingCloseButton(
            accessibilityLabel: "Continue to Today",
            action: onContinue
        )
    }

    @MainActor
    private func finishAnalysis() async {
        let elapsed = max(0, Date().timeIntervalSince(startDate))
        let remaining = max(0, analysisDuration - elapsed)

        if remaining > 0 {
            try? await Task.sleep(for: .seconds(remaining))
        }
        guard !Task.isCancelled else { return }

        if reduceMotion {
            showingCompletion = true
        } else {
            withAnimation(.easeOut(duration: 0.28)) {
                showingCompletion = true
            }
        }

        // Hold 100% briefly so the completed count reads before the orb exits.
        try? await Task.sleep(for: .milliseconds(190))
        guard !Task.isCancelled else { return }

        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .easeOut(duration: 0.22)) {
            analysisSceneVisible = false
        }

        // The results begin during the orb's exit, keeping this as one transition.
        try? await Task.sleep(for: .milliseconds(100))
        guard !Task.isCancelled else { return }
        onAnalysisFinished()
    }
}

/// Background shared across the analysis and its result screen.
struct InboxAnalysisBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x009FFE), location: 0),
                .init(color: .white, location: 0.70)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

public struct PostConnectionAnalysisFlow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingResults = false
    @State private var showingHome = false
    @State private var startDate = Date()

    public init() {}

    public var body: some View {
        Group {
            if showingHome {
                PriorityCardShowcase()
                    .transition(.opacity)
            } else {
                ZStack {
                    InboxAnalysisView(
                        startDate: startDate,
                        onContinue: continueToHome,
                        onAnalysisFinished: presentResults
                    )
                    .zIndex(0)

                    if showingResults {
                        OnboardingAnalysisResultsView(
                            showsBackground: false,
                            onViewPriorityInbox: continueToHome
                        )
                        .transition(.opacity)
                        .zIndex(1)
                    }
                }
                .animation(
                    reduceMotion ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.22),
                    value: showingResults
                )
            }
        }
        .animation(
            reduceMotion ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.24),
            value: showingHome
        )
    }

    private func presentResults() {
        guard !showingResults, !showingHome else { return }
        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.22)) {
            showingResults = true
        }
    }

    private func continueToHome() {
        guard !showingHome else { return }
        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.24)) {
            showingHome = true
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

#Preview("Analysis") {
    InboxAnalysisView()
}

#Preview("Post connection") {
    PostConnectionAnalysisFlow()
}
