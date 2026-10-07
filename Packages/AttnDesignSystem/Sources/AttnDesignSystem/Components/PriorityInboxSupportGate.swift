import SwiftUI
import UIKit
import UserNotifications

/// Presents the one-time widget and notification introduction after the Priority Inbox opens.
@MainActor
public struct PriorityInboxSupportGate<Content: View>: View {
    @AppStorage("attn.priorityInboxSupportPromptsCompleted")
    private var promptsCompleted = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPresenting = false
    @State private var page: Page = .widget
    @State private var notificationAccessDenied = false

    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            // Keeps Home visible as a quiet card behind the native sheet.
            .scaleEffect(isPresenting ? 0.94 : 1)
            .animation(
                reduceMotion ? .easeOut(duration: 0.16) : .smooth(duration: 0.28),
                value: isPresenting
            )
            .sheet(isPresented: $isPresenting, onDismiss: markPromptsComplete) {
                promptContent
                    .presentationDetents([.height(650)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(32)
                    .presentationBackground(SupportPromptPalette.sheet)
                    .preferredColorScheme(.light)
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, notificationAccessDenied else { return }
                refreshNotificationPermission()
            }
            .task {
                guard !promptsCompleted else { return }
                try? await Task.sleep(for: .milliseconds(380))
                guard !Task.isCancelled, !promptsCompleted else { return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.16) : .smooth(duration: 0.28)) {
                    page = .widget
                    isPresenting = true
                }
            }
    }

    @ViewBuilder
    private var promptContent: some View {
        Group {
            switch page {
            case .widget:
                WidgetPromptPage(
                    onClose: dismissSequence,
                    onAddWidget: {
                        AttnHaptics.impactLight()
                        changePage(to: .widgetInstructions)
                    },
                    onNotNow: continueAfterWidgetPrompt
                )
            case .widgetInstructions:
                WidgetInstructionsPage(
                    onClose: dismissSequence,
                    onContinue: continueAfterWidgetPrompt,
                    onNotNow: continueAfterWidgetPrompt
                )
            case .notifications:
                NotificationsPromptPage(
                    onClose: dismissSequence,
                    notificationsAreDenied: notificationAccessDenied,
                    onAllow: requestNotifications,
                    onNotNow: dismissSequence
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(
            reduceMotion ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.18),
            value: page
        )
    }

    private func changePage(to nextPage: Page) {
        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.18)) {
            page = nextPage
        }
    }

    private func dismissSequence() {
        promptsCompleted = true
        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .smooth(duration: 0.28)) {
            isPresenting = false
        }
    }

    private func markPromptsComplete() {
        // Swiping the native sheet down is treated like choosing “Not now”.
        promptsCompleted = true
    }

    private func continueAfterWidgetPrompt() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                dismissSequence()
            case .denied:
                notificationAccessDenied = true
                changePage(to: .notifications)
            case .notDetermined:
                notificationAccessDenied = false
                changePage(to: .notifications)
            @unknown default:
                changePage(to: .notifications)
            }
        }
    }

    private func refreshNotificationPermission() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                dismissSequence()
            case .denied:
                notificationAccessDenied = true
            case .notDetermined:
                notificationAccessDenied = false
            @unknown default:
                break
            }
        }
    }

    private func requestNotifications() {
        if notificationAccessDenied {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
            return
        }

        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            switch settings.authorizationStatus {
            case .notDetermined:
                do {
                    let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                    if granted {
                        dismissSequence()
                    } else {
                        notificationAccessDenied = true
                    }
                } catch {
                    notificationAccessDenied = true
                }
            case .authorized, .provisional, .ephemeral:
                dismissSequence()
            case .denied:
                notificationAccessDenied = true
            @unknown default:
                dismissSequence()
            }
        }
    }

    private enum Page: Equatable {
        case widget
        case widgetInstructions
        case notifications
    }
}

private struct WidgetPromptPage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var previewVisible = false
    @State private var copyVisible = false

    let onClose: () -> Void
    let onAddWidget: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            promptHeader(onClose: onClose)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    PriorityWidgetPreview()
                        .padding(.top, 14)
                        .opacity(previewVisible ? 1 : 0)
                        .offset(y: previewVisible ? 0 : 12)

                    Text("Keep what matters within reach")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(SupportPromptPalette.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 24)
                        .opacity(copyVisible ? 1 : 0)
                        .offset(y: copyVisible ? 0 : 8)

                    Text("Add the widget to your Home Screen to see your most important priorities without opening the app.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(SupportPromptPalette.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .padding(.horizontal, 28)
                        .opacity(copyVisible ? 1 : 0)
                        .offset(y: copyVisible ? 0 : 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            }

            VStack(spacing: 10) {
                OnboardingActionButton(title: "Add Widget", tone: .primary, height: 52, action: onAddWidget)
                    .accessibilityHint("Shows the steps to add ATTN to your Home Screen.")

                Button("Not now", action: onNotNow)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SupportPromptPalette.secondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .opacity(copyVisible ? 1 : 0)
            .offset(y: copyVisible ? 0 : 8)
        }
        .accessibilityElement(children: .contain)
        .task {
            guard !reduceMotion else {
                previewVisible = true
                copyVisible = true
                return
            }
            withAnimation(.smooth(duration: 0.24)) {
                previewVisible = true
            }
            try? await Task.sleep(for: .milliseconds(70))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.24)) {
                copyVisible = true
            }
        }
    }
}

private struct WidgetInstructionsPage: View {
    let onClose: () -> Void
    let onContinue: () -> Void
    let onNotNow: () -> Void

    private let steps = [
        "Touch and hold an empty area on your Home Screen.",
        "Tap Edit, then Add Widget.",
        "Search for ATTN and choose the medium widget.",
        "Tap Add Widget, then return to ATTN."
    ]

    var body: some View {
        VStack(spacing: 0) {
            promptHeader(onClose: onClose)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    PriorityWidgetPreview()
                        .padding(.top, 14)
                        .frame(maxWidth: .infinity)

                    Text("Add the ATTN widget")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(SupportPromptPalette.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)

                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SupportPromptPalette.primary)
                                .frame(width: 28, height: 28)
                                .background(.white.opacity(0.76), in: Circle())

                            Text(step)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(SupportPromptPalette.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
            }

            VStack(spacing: 10) {
                OnboardingActionButton(title: "Continue", tone: .primary, height: 52, action: onContinue)
                Button("Not now", action: onNotNow)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SupportPromptPalette.secondary)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

private struct NotificationsPromptPage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var previewVisible = false
    @State private var copyVisible = false

    let onClose: () -> Void
    let notificationsAreDenied: Bool
    let onAllow: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            promptHeader(onClose: onClose)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    LockScreenNotificationPreview()
                        .padding(.top, 16)
                        .opacity(previewVisible ? 1 : 0)
                        .offset(y: previewVisible ? 0 : 12)

                    Text("Stay ahead of what matters")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(SupportPromptPalette.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 24)
                        .opacity(copyVisible ? 1 : 0)
                        .offset(y: copyVisible ? 0 : 8)

                    Text(notificationsAreDenied
                         ? "Notifications are off. You can turn them on in Settings whenever you’re ready."
                         : "Turn on notifications and attn will let you know when something important needs your attention.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(SupportPromptPalette.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .padding(.horizontal, 28)
                        .opacity(copyVisible ? 1 : 0)
                        .offset(y: copyVisible ? 0 : 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            }

            VStack(spacing: 10) {
                OnboardingActionButton(
                    title: notificationsAreDenied ? "Open Settings" : "Allow notifications",
                    tone: .primary,
                    height: 52,
                    action: onAllow
                )
                    .accessibilityHint("Opens the iOS notification permission request.")

                Button("Not now", action: onNotNow)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SupportPromptPalette.secondary)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .opacity(copyVisible ? 1 : 0)
            .offset(y: copyVisible ? 0 : 8)
        }
        .task {
            guard !reduceMotion else {
                previewVisible = true
                copyVisible = true
                return
            }
            withAnimation(.smooth(duration: 0.24)) {
                previewVisible = true
            }
            try? await Task.sleep(for: .milliseconds(70))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.24)) {
                copyVisible = true
            }
        }
    }
}

private struct PriorityWidgetPreview: View {
    private let priorities = [
        WidgetPriority(id: "payment", title: "Credit card payment", timing: "Due today", urgent: true),
        WidgetPriority(id: "flight", title: "Flight check-in", timing: "Opens in 3 hours", urgent: true),
        WidgetPriority(id: "tax", title: "Tax filing notice", timing: "Due this week", urgent: true),
        WidgetPriority(id: "interview", title: "Interview", timing: "Tomorrow · 9:30 AM", urgent: false)
    ]

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 8) {
                ForEach(priorities) { priority in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(priority.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(priority.timing)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(priority.urgent ? AttnColors.actionNeeded : .white.opacity(0.74))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                    .background(AttnColors.surfaceWidget, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 7.8, y: 4)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: 350)
        .frame(height: 164)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SupportPromptPalette.widgetBlue,
                            SupportPromptPalette.widgetCream
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.65), lineWidth: 1)
                        .blur(radius: 2)
                }
        }
        .overlay(alignment: .bottom) {
            Text("attn")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                .offset(y: 17)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ATTN widget preview with four priorities")
    }
}

private struct LockScreenNotificationPreview: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("9:41")
                .font(.system(size: 34, weight: .light, design: .rounded))
                .foregroundStyle(.white)
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(SupportPromptPalette.widgetBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("attn")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("now")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Text("Payment due today")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Your payment is due by 11:59 PM.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                }
                .foregroundStyle(.white)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.black.opacity(0.18))
                    }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.36, blue: 0.53),
                            Color(red: 0.25, green: 0.40, blue: 0.48),
                            SupportPromptPalette.widgetBlue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Example ATTN notification preview")
    }
}

private struct WidgetPriority: Identifiable {
    let id: String
    let title: String
    let timing: String
    let urgent: Bool
}

@MainActor
private func promptHeader(onClose: @escaping () -> Void) -> some View {
    HStack {
        Spacer()
        OnboardingCloseButton(accessibilityLabel: "Close setup prompts", action: onClose)
    }
}

private enum SupportPromptPalette {
    static let sheet = Color(hex: 0xF9FBE3)
    static let primary = Color(hex: 0x101012)
    static let secondary = Color(hex: 0x77767E)
    static let widgetBlue = Color(hex: 0x009FFE)
    static let widgetCream = Color(hex: 0xF9FBE3)
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

#Preview("Widget setup") {
    PriorityInboxSupportGate {
        PriorityCardShowcase()
    }
}
