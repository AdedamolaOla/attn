import SwiftUI
import AttnDesignSystem

struct ContentView: View {
    @State private var showingGmailNextStep = false

    var body: some View {
        WelcomeView {
            showingGmailNextStep = true
        }
        .alert("Connect Gmail", isPresented: $showingGmailNextStep) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Gmail authorization is the next onboarding step. No account has been connected yet.")
        }
    }
}

#Preview {
    ContentView()
}
