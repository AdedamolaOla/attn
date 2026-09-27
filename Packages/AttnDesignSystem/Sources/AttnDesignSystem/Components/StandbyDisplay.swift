import SwiftUI
import UIKit

private func finitePositive(_ value: CGFloat, fallback: CGFloat = 1) -> CGFloat {
    guard value.isFinite, value > 0 else { return fallback }
    return value
}

/// Full-screen standby surface opened from the Home mascot.
///
/// The Figma canvas is 1328 × 616 and landscape. Standby requests a
/// landscape scene orientation so the left-rail / right-priority composition
/// uses the full display without rotating content inside a portrait canvas.
public struct StandbyDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var previewAttendedIDs: Set<String> = []
    private let externalAttendedIDs: Binding<Set<String>>?

    public init(attendedIDs: Binding<Set<String>>? = nil) {
        self.externalAttendedIDs = attendedIDs
        AttnAgbalumoFont.register()
    }

    public var body: some View {
        // Only the clock needs periodic updates. The scrollable priorities
        // keep a stable identity instead of being rebuilt sixty times a second.
        TimelineView(.periodic(from: .now, by: 60)) { context in
            StandbyDisplayCanvas(
                date: context.date,
                onDismiss: { dismiss() },
                attendedIDs: externalAttendedIDs ?? $previewAttendedIDs
            )
        }
        // Let the window scene perform the orientation change. Do not
        // rotate the SwiftUI content inside a portrait canvas, because
        // that clips the landscape composition when rotation is denied.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(.black)
        .statusBarHidden(true)
        .onAppear {
            StandbyOrientation.requestLandscape()
        }
        .onDisappear {
            StandbyOrientation.requestPortrait()
        }
    }
}

private enum StandbyOrientation {
    static func requestLandscape() {
        request(.landscape, fallback: .landscapeRight)
    }

    static func requestPortrait() {
        request(.portrait, fallback: .portrait)
    }

    private static func request(
        _ mask: UIInterfaceOrientationMask,
        fallback orientation: UIInterfaceOrientation
    ) {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }

            if #available(iOS 16.0, *) {
                scene.requestGeometryUpdate(
                    UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask),
                    errorHandler: { _ in
                        forceDeviceOrientation(orientation)
                    }
                )
            } else {
                forceDeviceOrientation(orientation)
            }
        }
    }

    private static func forceDeviceOrientation(_ orientation: UIInterfaceOrientation) {
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
}

private struct StandbyDisplayCanvas: View {
    let date: Date
    let onDismiss: () -> Void
    @Binding var attendedIDs: Set<String>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasScrolledPastTop = false
    @State private var lastAttendedID: String?

    var body: some View {
        GeometryReader { proxy in
            // All dimensions are measured from the actual landscape viewport.
            // Decorative layers never participate in the HStack's layout size.
            let horizontalInset: CGFloat = 16
            let verticalInset: CGFloat = 8
            let columnGap: CGFloat = 12
            let contentWidth = finitePositive(proxy.size.width - 2 * horizontalInset)
            let contentHeight = finitePositive(proxy.size.height - 2 * verticalInset)
            let columnWidth = finitePositive((contentWidth - columnGap) / 2)
            let mascotWidth = finitePositive(
                min(
                    columnWidth - 16,
                    (contentHeight - 128) * (CGFloat(629) / CGFloat(343))
                )
            )

            HStack(alignment: .top, spacing: columnGap) {
                leftRail(mascotWidth: mascotWidth)
                    .frame(width: columnWidth, height: contentHeight)

                attentionColumn
                    .frame(width: columnWidth, height: contentHeight, alignment: .top)
            }
            .frame(width: contentWidth, height: contentHeight)
            .padding(.horizontal, horizontalInset)
            .padding(.vertical, verticalInset)
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: .center
            )
            .background {
                LinearGradient(
                    colors: [
                        Color(red: 0, green: 159 / 255, blue: 254 / 255),
                        Color(red: 249 / 255, green: 251 / 255, blue: 227 / 255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Standby display")
    }

    private func leftRail(mascotWidth: CGFloat) -> some View {
        // The source mascot artwork ends mid-body. Keep the clock in its
        // centered position, but let the artwork bleed below the display edge
        // so its raster boundary can never appear as a line above the bezel.
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Text(timeLabel)
                    .font(.custom(AttnAgbalumoFont.name, size: 72))
                    .tracking(-3)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(dateLabel)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 16)

            FloatingStandbyMascot(width: mascotWidth, reduceMotion: reduceMotion)
                .frame(width: mascotWidth)
                .offset(y: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeLabel), \(dateLabel), attn mascot")
    }

    private var attentionColumn: some View {
        ScrollViewReader { scrollProxy in
            // A plain List gives each custom card Apple's familiar leading-edge
            // full-swipe interaction without changing the card's visual surface.
            List {
                HStack(alignment: .center) {
                    Text("Needs attn. (\(pendingPriorities.count))")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 12)

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.76))
                            .frame(width: 42, height: 42)
                            .background(.white.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close standby display")
                }
                .id("standby-attention-top")
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 18, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if pendingPriorities.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("All clear for now.")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("We'll let you know if that changes.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(pendingPriorities) { priority in
                        StandbyPriorityRow(
                            icon: priority.icon,
                            iconBackground: priority.iconBackground,
                            title: priority.title,
                            timing: priority.timing,
                            timingColor: priority.timingColor
                        )
                        .padding(.bottom, 16)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                markAttended(priority.id)
                            } label: {
                                Label("Attended", systemImage: "checkmark")
                            }
                            .tint(AttnColors.resolved)
                        }
                        .accessibilityAction(named: Text("Mark attended")) {
                            markAttended(priority.id)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .onAppear {
                scrollProxy.scrollTo("standby-attention-top", anchor: .top)
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y > 2
            } action: { _, isScrolled in
                hasScrolledPastTop = isScrolled
            }
            .mask {
                if hasScrolledPastTop {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.07),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    Rectangle()
                }
            }
            .overlay(alignment: .bottom) {
                if let lastAttendedID,
                   let priority = priorities.first(where: { $0.id == lastAttendedID }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AttnColors.resolved)
                            .accessibilityHidden(true)
                        Text("\(priority.title) attended")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 8)
                        Button("Undo", action: undoLastAttended)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AttnColors.surfaceConfidence)
                            .frame(minHeight: 44)
                    }
                    .padding(.horizontal, 16)
                    .background(AttnColors.surfaceWidget, in: .capsule)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .accessibilityElement(children: .contain)
                    .accessibilityHint("This marks your attention only; it does not confirm an action outside ATTN.")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(pendingPriorities.count) things need attention")
    }

    private var pendingPriorities: [StandbyPriority] {
        priorities.filter { !attendedIDs.contains($0.id) }
    }

    private var priorities: [StandbyPriority] {
        [
            StandbyPriority(
                id: "payment", icon: "$",
                iconBackground: Color(red: 217 / 255, green: 236 / 255, blue: 1),
                title: "Credit card payment", timing: "Due Today",
                timingColor: Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
            ),
            StandbyPriority(
                id: "flight", icon: "✈︎",
                iconBackground: Color(red: 1, green: 235 / 255, blue: 213 / 255),
                title: "Flight check-in", timing: "Closes in 30mins",
                timingColor: Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
            ),
            StandbyPriority(
                id: "tax", icon: "📑",
                iconBackground: Color(red: 201 / 255, green: 247 / 255, blue: 1),
                title: "Tax filing notice", timing: "Closes in 1 hour",
                timingColor: Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
            ),
            StandbyPriority(
                id: "figma", icon: "🖌️",
                iconBackground: Color(red: 189 / 255, green: 1, blue: 220 / 255),
                title: "Figma edit access req...", timing: "2days ago",
                timingColor: .white.opacity(0.68)
            ),
            StandbyPriority(
                id: "interview-soon", icon: "☎️",
                iconBackground: Color(red: 189 / 255, green: 1, blue: 220 / 255),
                title: "Product Design Interv...", timing: "In 8 hours",
                timingColor: .white.opacity(0.68)
            ),
            StandbyPriority(
                id: "interview-tomorrow", icon: "☎️",
                iconBackground: Color(red: 189 / 255, green: 1, blue: 220 / 255),
                title: "Product Design Interview", timing: "Tomorrow · 9:30 AM",
                timingColor: .white.opacity(0.68)
            )
        ]
    }

    private func markAttended(_ id: String) {
        guard !attendedIDs.contains(id) else { return }
        withAnimation(reduceMotion ? nil : AttnMotion.contentAnimation) {
            attendedIDs.insert(id)
            lastAttendedID = id
        }
        AttnHaptics.success()
    }

    private func undoLastAttended() {
        guard let id = lastAttendedID else { return }
        withAnimation(reduceMotion ? nil : AttnMotion.contentAnimation) {
            attendedIDs.remove(id)
            lastAttendedID = nil
        }
        AttnHaptics.selection()
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

private struct FloatingStandbyMascot: View {
    let width: CGFloat
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 7.6) / 7.6 * Double.pi * 2

            AttnMascotQuestion(width: width)
                .offset(
                    x: reduceMotion ? 0 : CGFloat(sin(phase) * 2.5),
                    y: reduceMotion ? 0 : CGFloat(cos(phase * 0.82) * 2.2)
                )
        }
        .accessibilityHidden(true)
    }
}

private struct StandbyPriority: Identifiable {
    let id: String
    let icon: String
    let iconBackground: Color
    let title: String
    let timing: String
    let timingColor: Color
}

private struct StandbyPriorityRow: View {
    let icon: String
    let iconBackground: Color
    let title: String
    let timing: String
    let timingColor: Color

    var body: some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 16 / 255, green: 16 / 255, blue: 18 / 255))
                .frame(width: 64, height: 64)
                .background(iconBackground, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(timing)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(timingColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 22 / 255, green: 22 / 255, blue: 24 / 255), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 7, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(timing)")
    }
}

#Preview("Standby") {
    StandbyDisplayView()
}
