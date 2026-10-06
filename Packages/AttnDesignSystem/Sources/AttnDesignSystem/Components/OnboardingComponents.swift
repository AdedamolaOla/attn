import SwiftUI

/// Shared backdrop used by the first-run onboarding screens.
struct OnboardingGradientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var gradientDrift: CGFloat = 0

    let bottomColor: Color
    let bottomColorLocation: CGFloat
    var topColorEndLocation: CGFloat? = nil
    var animates: Bool = false

    private var gradientStops: [Gradient.Stop] {
        let blue = Color(red: 0, green: 159.0 / 255.0, blue: 254.0 / 255.0)
        var stops: [Gradient.Stop] = [.init(color: blue, location: 0)]

        if let topColorEndLocation {
            stops.append(.init(color: blue, location: topColorEndLocation))
        }

        stops.append(.init(color: bottomColor, location: bottomColorLocation))
        if bottomColorLocation < 1 {
            stops.append(.init(color: bottomColor, location: 1))
        }
        return stops
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Color.white

                LinearGradient(
                    stops: gradientStops,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: size.width, height: size.height + 56)
                .offset(y: -28 + (animates && !reduceMotion ? gradientDrift : 0))
                .frame(width: size.width, height: size.height)
                .clipped()
            }
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
    case secondary
    case destructive

    var colors: [Color] {
        switch self {
        case .primary:
            return [Color(red: 0, green: 137.0 / 255.0, blue: 1), Color(red: 0, green: 120.0 / 255.0, blue: 244 / 255)]
        case .destructive:
            return [Color(red: 1, green: 0, blue: 0), Color(red: 1, green: 24.0 / 255.0, blue: 31.0 / 255)]
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary, .destructive: return .white
        }
    }

    var borderColor: Color {
        switch self {
        case .primary, .destructive: return .white.opacity(0.28)
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary: return Color(red: 0, green: 126.0 / 255.0, blue: 1).opacity(0.20)
        case .destructive: return Color.red.opacity(0.15)
        }
    }
}

/// Shared capsule button used for onboarding primary and secondary actions.
struct OnboardingActionButton: View {
    let title: String
    let tone: OnboardingButtonTone
    var height: CGFloat = 52
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tone.foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background {
                    Capsule()
                        .fill(LinearGradient(colors: tone.colors, startPoint: .top, endPoint: .bottom))
                }
                .overlay {
                    Capsule()
                        .stroke(tone.borderColor, lineWidth: 1)
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



/// Shared destructive Gmail action used on Account and onboarding confirmation.
struct DisconnectGmailButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.clear)
            .glassEffect(.regular.tint(.red).interactive(), in: .capsule)
            .environment(\\.colorScheme, .light)
    }
}

/// Shared circular close control used across onboarding screens.
struct OnboardingCloseButton: View {
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(red: 27.0 / 255.0, green: 27.0 / 255.0, blue: 27.0 / 255.0).opacity(0.82))
                .frame(width: 50, height: 50)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .environment(\.colorScheme, .light)
        .accessibilityLabel(accessibilityLabel)
    }
}
