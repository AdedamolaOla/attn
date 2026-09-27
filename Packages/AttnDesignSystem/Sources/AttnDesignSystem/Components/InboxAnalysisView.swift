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

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
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
        let driftX = CGFloat(sin(phase * 0.72)) * 0.035
        let driftY = CGFloat(cos(phase * 0.58)) * 0.035
        let whiteStop = 0.50 + CGFloat(sin(phase * 0.43)) * 0.035

        return Circle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0xFFD600), location: 0),
                        .init(color: Color(hex: 0xFFFFFF), location: whiteStop),
                        .init(color: Color(hex: 0x009FFE), location: 1)
                    ],
                    startPoint: UnitPoint(x: 0.05 + driftX, y: 0.05 + driftY),
                    endPoint: UnitPoint(x: 0.95 + driftX, y: 0.95 + driftY)
                )
            )
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
        Button(action: onContinue) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: 0x1B1B1B).opacity(0.78))
                .frame(width: 50, height: 50)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue to Today")
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
