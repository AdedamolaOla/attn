import SwiftUI
import UIKit

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
    @Environment(\\.dismiss) private var dismiss
    @State private var selected = 0

    private let iconOptions: [AppIconOption] = [
        AppIconOption(id: 0, title: "Signature", subtitle: "Normal attn icon", style: .signature),
        AppIconOption(id: 1, title: "Gradient", subtitle: "A bold blend of colours", style: .gradient),
        AppIconOption(id: 2, title: "Pridey", subtitle: "A celebration of identity & being yourself", style: .pridey),
        AppIconOption(id: 3, title: "Nighty", subtitle: "Black and white / monochrome", style: .nighty)
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            NotificationsSettingsHeader(title: "App Icon", dismiss: dismiss)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(iconOptions) { option in
                        AppIconRow(
                            option: option,
                            isSelected: selected == option.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selected = option.id
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, AttnSpacing.expanded)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct AppIconOption: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let style: AppIconTileStyle
}

private enum AppIconTileStyle {
    case signature
    case gradient
    case pridey
    case nighty
}

private struct AppIconRow: View {
    let option: AppIconOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    AppIconTile(style: option.style)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.attnPrimary)
                        Text(option.subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.attnSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    AppIconRadio(isSelected: isSelected)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                DashedSettingsDivider()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\\(option.title), \\(option.subtitle)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct AppIconTile: View {
    let style: AppIconTileStyle

    var body: some View {
        ZStack {
            background
            Image(style == .nighty ? "attn-logo-1" : "attn-logo", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 43, height: 20)
        }
        .frame(width: 61, height: 61)
        .clipShape(RoundedRectangle(cornerRadius: 18.5, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18.5, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.38), .black.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.14), radius: 2, y: 1)
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .signature:
            LinearGradient(
                colors: [
                    Color(red: 0/255, green: 159/255, blue: 254/255),
                    Color(red: 169/255, green: 239/255, blue: 228/255),
                    Color(red: 249/255, green: 251/255, blue: 227/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .gradient:
            LinearGradient(
                stops: [
                    .init(color: Color(red: 255/255, green: 214/255, blue: 26/255), location: 0),
                    .init(color: Color(red: 255/255, green: 159/255, blue: 10/255), location: 0.52),
                    .init(color: Color(red: 255/255, green: 59/255, blue: 48/255), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pridey:
            VStack(spacing: 0) {
                Color(red: 255/255, green: 93/255, blue: 98/255)
                Color(red: 255/255, green: 149/255, blue: 0/255)
                Color(red: 255/255, green: 214/255, blue: 26/255)
                Color(red: 52/255, green: 199/255, blue: 89/255)
                Color(red: 64/255, green: 156/255, blue: 255/255)
                Color(red: 175/255, green: 82/255, blue: 222/255)
            }
        case .nighty:
            Color(red: 16/255, green: 16/255, blue: 18/255)
        }
    }
}

private struct AppIconRadio: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .stroke(isSelected ? Color.accentColor : Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: isSelected ? 2 : 1)
            .frame(width: 18, height: 18)
            .overlay {
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityHidden(true)
    }
}

private struct DashedSettingsDivider: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: 0.5))
            path.addLine(to: CGPoint(x: size.width, y: 0.5))
            context.stroke(
                path,
                with: .color(Color(red: 229/255, green: 231/255, blue: 235/255)),
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
        }
        .frame(height: 1)
        .accessibilityHidden(true)
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
