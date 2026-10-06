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
                let phase = reduceMotion ? 0 : elapsed * (2 * .pi / 7.5)

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
        let yellow = Color(hex: 0xFFD600)
        let blue = Color(hex: 0x009FFE)
        let yellowCenter = UnitPoint(
            x: 0.5 + 0.18 * CGFloat(sin(phase)),
            y: 0.5 + 0.16 * CGFloat(cos(phase * 0.82))
        )

        return Circle()
            .fill(blue)
            .overlay {
                // A saturated yellow field drifts over the blue base to create
                // a calm, continuous loading motion without a white wash.
                RadialGradient(
                    stops: [
                        .init(color: yellow, location: 0),
                        .init(color: yellow, location: 0.34),
                        .init(color: yellow.opacity(0.88), location: 0.53),
                        .init(color: yellow.opacity(0), location: 1)
                    ],
                    center: yellowCenter,
                    startRadius: 0,
                    endRadius: 170
                )
            }
            // Keep the shadow on the orb's inner edge and clip it to the ellipse.
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
            .frame(width: 203, height: 203)
            .clipShape(Circle())
            .overlay {
                Text(String(progress) + "%")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundStyle(Color(hex: 0x1B1B1B))
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Analyzing your inbox")
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
