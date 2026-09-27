import SwiftUI

/// A visual, post-Gmail-connection analysis state.
/// This is a mock phase: the percentage and sample timing are not tied to Gmail processing.
public struct InboxAnalysisView: View {
    private let onContinue: () -> Void

    public init(onContinue: @escaping () -> Void = {}) {
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

            VStack(spacing: 16) {
                analysisOrb

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

            closeButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 14)
                .padding(.trailing, 24)
        }
        .preferredColorScheme(.light)
    }

    private var analysisOrb: some View {
        Circle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0xFFD600), location: 0),
                        .init(color: Color(hex: 0xFFFFFF), location: 0.50),
                        .init(color: Color(hex: 0x009FFE), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            // Paint the blurred shadow ring inside the ellipse's mask. Clipping it here
            // prevents any exterior/drop shadow from escaping the orb.
            .overlay {
                Circle()
                    .stroke(Color(hex: 0x595959).opacity(0.25), lineWidth: 1)
                    .blur(radius: 6.5)
                    .offset(x: 0, y: -1)
                    .clipShape(Circle())
                    .allowsHitTesting(false)
            }
            .overlay {
                Text("73%")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundStyle(Color(hex: 0x1B1B1B))
                    .accessibilityHidden(true)
            }
            .frame(width: 203, height: 203)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Analyzing your inbox")
            .accessibilityValue("73 percent")
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

    public init() {}

    public var body: some View {
        Group {
            if showingHome {
                PriorityCardShowcase()
                    .transition(.opacity)
            } else {
                InboxAnalysisView {
                    continueToHome()
                }
                .transition(.opacity)
            }
        }
        .task {
            guard !showingHome else { return }
            do {
                try await Task.sleep(for: .seconds(3.5))
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
