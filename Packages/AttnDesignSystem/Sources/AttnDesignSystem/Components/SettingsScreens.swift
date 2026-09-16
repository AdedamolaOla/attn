import SwiftUI

public struct SettingsNotificationsWidgetsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var homeWidget = true
    @State private var notifications = true
    @State private var dynamicIsland = true

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            NotificationsSettingsHeader(title: "Notifications & Widget", dismiss: dismiss)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ZStack {
                        Color(red: 251/255, green: 251/255, blue: 251/255)
                        WidgetPreviewImage()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 184)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    SettingsOption(
                        title: "Home Screen Widget",
                        detail: "Adding the widget to your Home Screen helps you see your most important priorities without opening the app.",
                        isOn: $homeWidget
                    )
                    SettingsOption(
                        title: "Notifications",
                        detail: "ATTN only interrupts you when missing something could have a real consequence.",
                        isOn: $notifications
                    )
                    SettingsOption(
                        title: "Dynamic Island",
                        detail: "Show a countdown when a deadline is near",
                        isOn: $dynamicIsland
                    )
                }
                .padding(.horizontal, AttnSpacing.panel)
                .padding(.bottom, AttnSpacing.expanded)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}

public struct SettingsAppIconView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected = 0
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            SettingsScreenHeader(title: "App Icon", dismiss: dismiss)
            ScrollView {
                VStack(alignment: .leading, spacing: AttnSpacing.section) {
                    Text("Choose an app icon")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.attnPrimary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        iconOption(0, "attn-logo")
                        iconOption(1, "attn-logo-1")
                        iconOption(2, "attn-logo")
                    }
                    SettingsCaption("You can change this anytime in Settings.")
                }
                .padding(.horizontal, AttnSpacing.panel)
                .padding(.top, 16)
                .padding(.bottom, AttnSpacing.expanded)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func iconOption(_ index: Int, _ asset: String) -> some View {
        Button { selected = index } label: {
            VStack(spacing: 8) {
                Image(asset, bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(selected == index ? Color.accentColor : .clear, lineWidth: 3)
                    }
                Text(index == 0 ? "Signature" : "Classic")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.attnPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

public struct HelpTopicsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expanded: String? = "What is attn?"
    public init() {}

    private let topics = [
        ("What is attn?", "attn helps identify the emails that deserve your attention and surfaces them as clear priorities."),
        ("How does attn prioritize emails?", "attn looks for timing, consequences, trusted senders, and direct requests."),
        ("How private is my data?", "Gmail access is read-only. Review Privacy & Data for details."),
        ("How do notifications work?", "attn only interrupts you when timing and consequence make it worthwhile.")
    ]

    public var body: some View {
        VStack(spacing: 0) {
            SettingsScreenHeader(title: "FAQs", dismiss: dismiss)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Getting Started")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.attnPrimary)
                    ForEach(topics, id: \.0) { topic in
                        faqRow(title: topic.0, answer: topic.1)
                    }
                }
                .padding(.horizontal, AttnSpacing.panel)
                .padding(.top, 8)
                .padding(.bottom, AttnSpacing.expanded)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func faqRow(title: String, answer: String) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    expanded = expanded == title ? nil : title
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.attnPrimary)
                    Spacer()
                    Image(systemName: expanded == title ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color(red: 243/255, green: 244/255, blue: 246/255))
            }
            if expanded == title {
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.attnSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 229/255, green: 231/255, blue: 235/255)))
    }
}

public struct SettingsAboutLegalView: View {
    @Environment(\.dismiss) private var dismiss
    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            SettingsScreenHeader(title: "About", dismiss: dismiss)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SettingsCaption("Connect with attn.")
                        .padding(.vertical, 8)
                    aboutRow("X/Twitter")
                    aboutRow("Privacy Policy")
                    aboutRow("Terms of Use")
                    aboutRow("Contact Support")
                    VStack(spacing: 4) {
                        Image("attn-logo", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 34)
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.attnSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 42)
                }
                .padding(.horizontal, AttnSpacing.panel)
                .padding(.bottom, AttnSpacing.expanded)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func aboutRow(_ title: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.attnPrimary)
                Spacer()
                Image("chevron-right", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            .frame(height: 56)
            Rectangle()
                .fill(Color(red: 229/255, green: 229/255, blue: 234/255))
                .frame(height: 1)
                .mask(Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
        }
    }
}

private struct SettingsScreenHeader: View {
    let title: String
    let dismiss: DismissAction

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.attnPrimary)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)
                .notificationsBackButton()
                .accessibilityLabel("Back")
                Spacer()
            }
        }
        .padding(.horizontal, AttnSpacing.panel)
        .padding(.top, 25)
        .padding(.bottom, AttnSpacing.section)
    }
}

private struct NotificationsSettingsHeader: View {
    let title: String
    let dismiss: DismissAction

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(.plain)
            .notificationsBackButton()
            .accessibilityLabel("Back")

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.attnPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AttnSpacing.panel)
        .padding(.top, 25)
        .padding(.bottom, 16)
    }
}

private struct WidgetPreviewImage: View {
    var body: some View {
        if let image = UIImage(named: "attn-widget", in: .main, compatibleWith: nil)
            ?? UIImage(named: "attn-widget", in: .module, compatibleWith: nil) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Color.clear
                .accessibilityHidden(true)
        }
    }
}

private struct SettingsOption: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.black)
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(Color(red: 52/255, green: 199/255, blue: 89/255))
            }
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(Color.attnSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension View {
    func notificationsBackButton() -> some View {
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
                )
                .allowsHitTesting(false)
            }
    }
}

private struct SettingsCaption: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Color.attnSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private extension Color {
    static let attnPrimary = Color(red: 27/255, green: 27/255, blue: 27/255)
    static let attnSecondary = Color(red: 119/255, green: 118/255, blue: 126/255)
}
