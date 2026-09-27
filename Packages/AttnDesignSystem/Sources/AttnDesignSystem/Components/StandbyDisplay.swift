import SwiftUI
import UIKit

private func finitePositive(_ value: CGFloat, fallback: CGFloat = 1) -> CGFloat {
    guard value.isFinite, value > 0 else { return fallback }
    return value
}

/// Full-screen standby surface opened from the Home mascot.
///
/// The layout follows the active scene orientation: portrait uses the
/// stacked clock / mascot / priority composition, while landscape uses the
/// existing side-by-side rails. It adapts to the actual viewport so
/// orientation lock never clips or forces the display.
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
        // Use the system's current orientation. A portrait-locked phone
        // gets the portrait composition; rotating into landscape selects the
        // original two-column layout.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(.black)
        .statusBarHidden(true)
    }
}

private struct StandbyDisplayCanvas: View {
    let date: Date
    let onDismiss: () -> Void
    @Binding var attendedIDs: Set<String>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            Group {
                if size.height >= size.width {
                    portraitLayout(size: size)
                } else {
                    landscapeLayout(size: size)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Standby display")
        }
    }

    private func landscapeLayout(size: CGSize) -> some View {
        let horizontalInset: CGFloat = 16
        let verticalInset: CGFloat = 8
        let columnGap: CGFloat = 12
        let contentWidth = finitePositive(size.width - 2 * horizontalInset)
        let contentHeight = finitePositive(size.height - 2 * verticalInset)
        let columnWidth = finitePositive((contentWidth - columnGap) / 2)
        let mascotWidth = finitePositive(
            min(columnWidth - 16, contentHeight * 0.426)
        )

        return HStack(alignment: .top, spacing: columnGap) {
            leftRail(mascotWidth: mascotWidth)
                .frame(width: columnWidth, height: contentHeight)

            attentionColumn(isPortrait: false)
                .frame(width: columnWidth, height: contentHeight, alignment: .top)
        }
        .frame(width: contentWidth, height: contentHeight)
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, verticalInset)
        .frame(width: size.width, height: size.height, alignment: .center)
        .background(standbyGradient)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
    }

    private func portraitLayout(size: CGSize) -> some View {
        // Figma's 790 × 1599 canvas maps to about 395 × 800 points.
        // Cap the hero at its design height; smaller phones scale it down.
        let scale = min(size.width / 395, min(size.height / 800, 1))
        let heroHeight = min(365 * scale, size.height * 0.47)

        return VStack(spacing: 0) {
            portraitHero(scale: scale, heroHeight: heroHeight)
                .frame(height: heroHeight)

            attentionColumn(isPortrait: true)
                .padding(.horizontal, 12 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size.width, height: size.height)
        .background(standbyGradient)
        .clipShape(RoundedRectangle(cornerRadius: 36 * scale, style: .continuous))
    }

    private func portraitHero(scale: CGFloat, heroHeight: CGFloat) -> some View {
        let mascotWidth = min(127.7 * scale, heroHeight * 0.5 / 1.426)

        return ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                VStack(spacing: 12 * scale) {
                    Text(timeLabel)
                        .font(.custom(AttnAgbalumoFont.name, size: 64 * scale))
                        .tracking(-2 * scale)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .frame(height: 66 * scale)

                    Text(dateLabel)
                        .font(.system(size: 13 * scale, weight: .medium))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(height: 18 * scale)
                }

                Spacer(minLength: 30 * scale)

                FloatingStandbyMascot(width: mascotWidth, reduceMotion: reduceMotion)
                    .frame(
                        width: mascotWidth,
                        height: mascotWidth * 2048 / 1435
                    )
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16 * scale)
            .padding(.top, 48 * scale)
            .padding(.bottom, 4 * scale)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 8 * scale)
            .padding(.trailing, 12 * scale)
            .accessibilityLabel("Close standby display")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var standbyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0, green: 159.0 / 255.0, blue: 254.0 / 255.0),
                Color(red: 249.0 / 255.0, green: 251.0 / 255.0, blue: 227.0 / 255.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func leftRail(mascotWidth: CGFloat) -> some View {
        // Keep the clock and full portrait mascot inside the left rail.
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeLabel), \(dateLabel), attn mascot")
    }

    private func attentionColumn(isPortrait: Bool) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text("Needs attn. (\(pendingPriorities.count))")
                        .font(.system(size: isPortrait ? 18 : 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 12)

                    if !isPortrait {
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
                }
                .padding(.top, isPortrait ? 0 : 8)
                .padding(.bottom, isPortrait ? 12 : 18)

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
                } else {
                    ForEach(pendingPriorities) { priority in
                        StandbySwipeToAttendRow(priority: priority, isPortrait: isPortrait) {
                            markAttended(priority.id)
                        }
                        .padding(.bottom, isPortrait ? 12 : 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        // The card must be allowed to travel past either side of its column.
        // Only the outer rounded display clips at the physical screen edge.
        .scrollClipDisabled()
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
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28)) {
            attendedIDs.insert(id)
        }
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

/// Horizontal swipes complete a priority directly; vertical drags still scroll.
private struct StandbySwipeToAttendRow: View {
    let priority: StandbyPriority
    let isPortrait: Bool
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0
    @State private var width: CGFloat = 320
    @State private var isHorizontalDrag = false
    @State private var isCompleting = false

    var body: some View {
        StandbyPriorityRow(
            icon: priority.icon,
            iconBackground: priority.iconBackground,
            title: priority.title,
            timing: priority.timing,
            timingColor: priority.timingColor,
            isPortrait: isPortrait
        )
        .offset(x: offset)
        .opacity(isCompleting ? 0 : 1 - min(abs(offset) / max(width, 1) * 0.28, 0.28))
        .blur(radius: reduceMotion ? 0 : (isCompleting ? 6 : 0))
        .contentShape(Rectangle())
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { newWidth in
            width = max(newWidth, 1)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    guard !isCompleting else { return }
                    if !isHorizontalDrag {
                        guard abs(value.translation.width) > abs(value.translation.height) * 1.25 else { return }
                        isHorizontalDrag = true
                    }
                    offset = value.translation.width
                }
                .onEnded { value in
                    defer { isHorizontalDrag = false }
                    guard isHorizontalDrag, !isCompleting else { return }

                    let distance = abs(value.translation.width)
                    let predictedDistance = abs(value.predictedEndTranslation.width)
                    let deliberate = distance >= max(72, width * 0.28)
                        || (distance >= 48 && predictedDistance >= width * 0.55)

                    guard deliberate else {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) {
                            offset = 0
                        }
                        return
                    }

                    let direction: CGFloat = value.translation.width >= 0 ? 1 : -1
                    AttnHaptics.success()
                    if reduceMotion {
                        isCompleting = true
                        onComplete()
                    } else {
                        withAnimation(.easeInOut(duration: 0.26), completionCriteria: .removed) {
                            isCompleting = true
                            offset = direction * (width + 48)
                        } completion: {
                            onComplete()
                        }
                    }
                }
        )
        .accessibilityAction(named: Text("Mark attended")) {
            guard !isCompleting else { return }
            AttnHaptics.success()
            onComplete()
        }
        .accessibilityHint("Swipe left or right to mark attended")
    }
}

private struct StandbyPriorityRow: View {
    let icon: String
    let iconBackground: Color
    let title: String
    let timing: String
    let timingColor: Color
    let isPortrait: Bool

    var body: some View {
        HStack(spacing: isPortrait ? 15 : 14) {
            Text(icon)
                .font(.system(
                    size: isPortrait ? 34 : 28,
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundStyle(Color(red: 16 / 255, green: 16 / 255, blue: 18 / 255))
                .frame(width: isPortrait ? 68 : 64, height: isPortrait ? 68 : 64)
                .background(
                    iconBackground,
                    in: RoundedRectangle(
                        cornerRadius: isPortrait ? 8.5 : 15,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: isPortrait ? 18 : 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(timing)
                    .font(.system(size: isPortrait ? 15 : 14, weight: .semibold))
                    .foregroundStyle(timingColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, isPortrait ? 8.5 : 14)
        .padding(.trailing, isPortrait ? 17 : 14)
        .padding(.vertical, isPortrait ? 8.5 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(red: 22 / 255, green: 22 / 255, blue: 24 / 255),
            in: RoundedRectangle(cornerRadius: isPortrait ? 25.4 : 24, style: .continuous)
        )
        .shadow(
            color: .black.opacity(isPortrait ? 0.08 : 0.22),
            radius: isPortrait ? 4.1 : 7,
            y: isPortrait ? 4.2 : 6
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(timing)")
    }
}

#Preview("Standby — Portrait") {
    StandbyDisplayView()
        .frame(width: 395, height: 800)
}

#Preview("Standby — Landscape") {
    StandbyDisplayView()
        .frame(width: 852, height: 393)
}
