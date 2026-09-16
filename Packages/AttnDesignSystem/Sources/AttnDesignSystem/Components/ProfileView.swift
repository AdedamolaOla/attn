import SwiftUI

public struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDisconnect = false
    public init() {}
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 18, weight: .medium)).frame(width: 50, height: 50) }
                    .buttonStyle(.plain).glassEffect(.regular.interactive(), in: .circle).accessibilityLabel("Back")
                Spacer()
                Text("Account").font(.system(size: 20, weight: .bold))
                Spacer().frame(width: 50)
            }
            .padding(.horizontal, AttnSpacing.panel).padding(.vertical, AttnSpacing.section)
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        Circle().fill(Color(red: 0.38, green: 0.11, blue: 0.45)).frame(width: 48, height: 48)
                            .overlay(Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.9)))
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text("Liam Oliver").font(.system(size: 18, weight: .semibold)); Spacer(); Text("● Connected").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(red: 31/255, green: 148/255, blue: 92/255)).padding(.horizontal, 9).padding(.vertical, 6).background(Color(red: 229/255, green: 247/255, blue: 235/255), in: .capsule) }
                            Text("Liamoliver@gmail.com").font(.system(size: 13)).foregroundStyle(Color(red: 119/255, green: 118/255, blue: 126/255))
                        }
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Color(red: 251/255, green: 251/255, blue: 251/255), in: .rect(cornerRadius: 20)).padding(.horizontal, AttnSpacing.panel).padding(.vertical, AttnSpacing.content)
                    VStack(spacing: 0) {
                        settingRow("bell", "Notifications & Widget"); divider
                        settingRow("app.dashed", "App Icon"); divider
                        settingRow("questionmark.circle", "FAQs"); divider
                        settingRow("text.bubble", "Send Feedback"); divider
                        settingRow("app.dashed", "About")
                    }
                    Spacer(minLength: 100)
                }
            }
            VStack(spacing: 16) {
                Button("Disconnect Gmail") { confirmDisconnect = true }.buttonStyle(.borderedProminent).tint(.red).controlSize(.large).frame(maxWidth: .infinity).frame(height: 50).padding(.horizontal, AttnSpacing.panel)
                Text("attn will stop syncing this inbox and remove\nits locally derived priorities.").font(.system(size: 12)).foregroundStyle(Color(red: 119/255, green: 118/255, blue: 126/255)).multilineTextAlignment(.center).padding(.bottom, AttnSpacing.section)
            }
        }.background(Color.white).navigationBarBackButtonHidden(true)
        .confirmationDialog("Disconnect Gmail?", isPresented: $confirmDisconnect, titleVisibility: .visible) { Button("Disconnect Gmail", role: .destructive) {}; Button("Cancel", role: .cancel) {} } message: { Text("attn will stop syncing this inbox and remove its locally derived priorities.") }
    }
    private var divider: some View { Rectangle().fill(Color(red: 222/255, green: 222/255, blue: 222/255)).frame(height: 0.5).padding(.leading, 66).padding(.trailing, AttnSpacing.panel) }
    private func settingRow(_ icon: String, _ title: String) -> some View {
        Button {} label: { HStack(spacing: 14) { Image(systemName: icon).font(.system(size: 16)).foregroundStyle(Color(red: 142/255, green: 142/255, blue: 147/255)).frame(width: 32, height: 32).background(Color(red: 251/255, green: 251/255, blue: 251/255), in: .rect(cornerRadius: 8)); Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(Color(red: 27/255, green: 27/255, blue: 27/255)); Spacer(); Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundStyle(Color(red: 190/255, green: 190/255, blue: 195/255)).frame(width: 20, height: 20) }.padding(.horizontal, AttnSpacing.panel).padding(.vertical, 12).frame(minHeight: 56) }.buttonStyle(.plain)
    }
}
