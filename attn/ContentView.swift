import SwiftUI
import AttnDesignSystem

private enum OnboardingRoute: Equatable {
    case welcome
    case confirmAccount
    case analysis
}

struct ContentView: View {
    @State private var route: OnboardingRoute = .welcome

    var body: some View {
        Group {
            switch route {
            case .welcome:
                WelcomeView {
                    move(to: .confirmAccount)
                }
                .transition(.opacity)

            case .confirmAccount:
                ConfirmAccountView(
                    identity: .prototype,
                    onConfirm: {
                        move(to: .analysis)
                    },
                    onDisconnect: {
                        move(to: .welcome)
                    },
                    onCancel: {
                        move(to: .welcome)
                    }
                )
                .transition(.opacity)

            case .analysis:
                PostConnectionAnalysisFlow()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: route)
    }

    private func move(to nextRoute: OnboardingRoute) {
        withAnimation(.easeInOut(duration: 0.22)) {
            route = nextRoute
        }
    }
}

#Preview {
    ContentView()
}
