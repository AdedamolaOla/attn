import SwiftUI

/// Shared backdrop used by the first-run onboarding screens.
struct OnboardingGradientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var gradientDrift: CGFloat = 0

    let bottomColor: Color
    let bottomColorLocation: CGFloat
    var animates: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            LinearGradient(
                stops: [
                    .init(color: Color(red: 0, green: 159 / 255, blue: 254 / 255), location: 0),
                    .init(color: bottomColor, location: bottomColorLocation),
                    .init(color: bottomColor, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: size.width, height: size.height + 56)
            .offset(y: -28 + (animates && !reduceMotion ? gradientDrift : 0))
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            guard animates, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                gradientDrift = 56
            }
        }
        .accessibilityHidden(true)
    }
}

enum OnboardingButtonTone {
    case primary
    case destructive

    var colors: [Color] {
        switch self {
        case .primary:
            [Color(red: 0, green: 137 / 255, blue: 1), Color(red: 0, green: 120 / 255, blue: 244 / 255)]
        case .destructive:
            [Color(red: 1, green: 0, blue: 0), Color(red: 1, green: 24 / 255, blue: 31 / 255)]
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary: Color(red: 0, green: 126 / 255, blue: 1).opacity(0.20)
        case .destructive: Color.red.opacity(0.15)
        }
    }
}

/// The same prominent capsule treatment used for onboarding actions.
struct OnboardingActionButton: View {
    let title: String
    let tone: OnboardingButtonTone
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    Capsule()
                        .fill(LinearGradient(colors: tone.colors, startPoint: .top, endPoint: .bottom))
                }
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                }
                .shadow(color: tone.shadowColor, radius: 3, y: 1)
                .contentShape(Capsule())
        }
        .buttonStyle(OnboardingPressButtonStyle())
    }
}

private struct OnboardingPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: configuration.isPressed ? 0.09 : 0.18), value: configuration.isPressed)
    }
}
