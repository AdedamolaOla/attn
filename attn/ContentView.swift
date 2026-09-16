import SwiftUI
import AttnDesignSystem

struct ContentView: View {
    @AppStorage("attn.onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted {
            PriorityCardShowcase()
        } else {
            OnboardingFlowView {
                onboardingCompleted = true
            }
        }
    }
}

#Preview {
    ContentView()
}
