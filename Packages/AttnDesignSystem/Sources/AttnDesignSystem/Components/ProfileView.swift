import SwiftUI

public struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDisconnect = false
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 0) {
                    identityCard.padding(.horizontal, AttnSpacing.panel).padding(.vertical, AttnSpacing.content)
                    settingsRows
                    Spacer(minLength: 80)
                }
            }
            disconnectArea
        }
        .background(Color.white)
        .ignoresSafeArea(edges: .top)
        .confirmationDialog("Disconnect Gmail?", isPresented: $confirmDisconnect, titleVisibility: .visible) {
            Button("Disconnect Gmail", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("attn will stop syncing this inbox and remove its locally derived priorities.")
        }
    }

    private var header: some View {
        ZStack {
            Text("Account").font(.system(size: 20, weight: .bold))
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .medium)).frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)
                .profileGlassButton()
                .accessibilityLabel("Back")
                Spacer()
            }
        }
        .padding(.horizontal, AttnSpacing.panel)
        .padding(.top, 50)
        .padding(.bottom, AttnSpacing.section)
    }

    private var identityCard: some View {
        HStack(spacing: 14) {
            Circle().fill(Color(red: 0.38, green: 0.11, blue: 0.45)).frame(width: 48, height: 48)
                .overlay(Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.9)))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Liam Oliver").font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Text("● Connected").font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 31/255, green: 148/255, blue: 92/255))
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .background(Color(red: 229/255, green: 247/255, blue: 235/255), in: .capsule)
                }
                Text("Liamoliver@gmail.com").font(.system(size: 13))
                    .foregroundStyle(Color(red: 119/255, green: 118/255, blue: 126/255))
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 251/255, green: 251/255, blue: 251/255), in: .rect(cornerRadius: 20))
    }

    private var settingsRows: some View {
        VStack(spacing: 0) {
            settingRow("bell", "Notifications & Widget"); divider
            settingRow("attn logo-1", "App Icon"); divider
            settingRow("question-circle", "FAQs"); divider
            settingRow("annotation", "Send Feedback"); divider
            settingRow("attn logo", "About")
        }
    }

    private var divider: some View {
        Rectangle().fill(Color(red: 229/255, green: 229/255, blue: 234/255))
            .frame(height: 1)
            .mask(Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
            .padding(.leading, 66)
            .padding(.trailing, AttnSpacing.panel)
    }

    private func settingRow(_ icon: String, _ title: String) -> some View {
        Button {} label: {
            HStack(spacing: 14) {
                Image(icon, bundle: .module).frame(width: 32, height: 32)
                    .background(Color(red: 251/255, green: 251/255, blue: 251/255), in: .rect(cornerRadius: 8))
                Text(title).font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(red: 27/255, green: 27/255, blue: 27/255))
                Spacer()
                Image("chevron-right", bundle: .module).frame(width: 20, height: 20)
            }
            .padding(.horizontal, AttnSpacing.panel).padding(.vertical, 12).frame(minHeight: 56)
        }.buttonStyle(.plain)
    }

    private var disconnectArea: some View {
        VStack(spacing: 16) {
            Button("Disconnect Gmail") { confirmDisconnect = true }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(.clear)
                .glassEffect(.regular.tint(.red).interactive(), in: .capsule)
                .padding(.horizontal, AttnSpacing.panel)
            Text("attn will stop syncing this inbox and remove\nits locally derived priorities.")
                .font(.system(size: 12)).foregroundStyle(Color(red: 119/255, green: 118/255, blue: 126/255))
                .multilineTextAlignment(.center).padding(.bottom, AttnSpacing.section)
        }
    }
}

private extension View {
    func profileGlassButton() -> some View {
        glassEffect(.regular.interactive(), in: .circle)
            .overlay {
                Circle().strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.65), location: 0),
                            .init(color: .black.opacity(0.20), location: 0.35),
                            .init(color: .black.opacity(0.16), location: 0.65),
                            .init(color: .white.opacity(0.55), location: 1)
                        ], startPoint: .top, endPoint: .bottom
                    ), lineWidth: 0.5
                ).allowsHitTesting(false)
            }
    }
}
