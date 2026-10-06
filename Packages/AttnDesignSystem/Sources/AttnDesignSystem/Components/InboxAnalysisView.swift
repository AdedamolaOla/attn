import SwiftUI

/// A visual, post-Gmail-connection analysis state.
/// The percentage is a timed prototype and is not connected to Gmail processing.
public struct InboxAnalysisView: View {
    private let startDate: Date
    private let onContinue: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let analysisDuration: TimeInterval = 6

    public init(startDate: Date = Date(), onContinue: @escaping () -> Void = {}) {
        self.startDate = startDate
        self.onContinue = onContinue
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x009FFE), location: 0),
                    .init(color: .white, location: 0.70)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let elapsed = max(0, timeline.date.timeIntervalSince(startDate))
                let progress = min(100, 1 + Int((elapsed / analysisDuration) * 99))
                let phase = reduceMotion ? 0 : elapsed * (2 * .pi / 8.5)

                VStack(spacing: 16) {
                    analysisOrb(progress: progress, phase: phase)

                    Text("Analyzing your inbox & finding the few messages that deserve your attention.")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundStyle(Color(hex: 0x77767E))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(width: 249)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -25)
            }

            closeButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 14)
                .padding(.trailing, 24)
        }
        .preferredColorScheme(.light)
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
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Analyzing your inbox")
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
}

public struct PostConnectionAnalysisFlow: View {
    @State private var showingHome = false
    @State private var startDate = Date()

    public init() {}

    public var body: some View {
        Group {
            if showingHome {
                PriorityCardShowcase()
                    .transition(.opacity)
            } else {
                InboxAnalysisView(startDate: startDate) {
                    continueToHome()
                }
                .transition(.opacity)
            }
        }
        .task {
            guard !showingHome else { return }
            do {
                // Let 100% stay visible briefly before continuing to Home.
                try await Task.sleep(for: .seconds(6.6))
            } catch {
                return
            }
            continueToHome()
        }
    }

    private func continueToHome() {
        guard !showingHome else { return }
        withAnimation(.easeInOut(duration: 0.24)) {
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
