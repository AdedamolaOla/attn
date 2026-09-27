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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
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
                .padding(.top, 8)
                .padding(.bottom, 18)

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
                        StandbySwipeToAttendRow(priority: priority) {
                            markAttended(priority.id)
                        }
                        .padding(.bottom, 16)
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

/// A restrained repeating dance for the standby surface.
///
/// Choreography (one 6.4 second cycle):
/// 0.00–0.45s  Anticipation: settle down and widen slightly.
/// 0.45–1.00s  Lift: quick stretch with a small leftward tilt, then rebound.
/// 1.00–3.20s  Dance: two alternating left/right weight shifts with soft beats.
/// 3.47–4.35s  Hop: rise, squash on landing, and recover.
/// 4.35–6.40s  Rest: hold a calm pose before the next phrase.
///
/// The source illustration stays a single, unmodified image layer. This keeps
/// the approved face and silhouette intact while the full character moves as
/// one, and leaves enough layout clearance for every pose without clipping.
private struct FloatingStandbyMascot: View {
    let width: CGFloat
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { context in
            let pose = reduceMotion
                ? MascotDancePose.rest
                : MascotDancePose.pose(at: context.date.timeIntervalSinceReferenceDate)

            AttnMascotQuestion(width: width)
                .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
                .rotationEffect(.degrees(Double(pose.rotation)), anchor: .bottom)
                .offset(x: pose.x, y: pose.y)
                .compositingGroup()
        }
        .accessibilityHidden(true)
    }
}

private struct MascotDancePose {
    var x: CGFloat
    var y: CGFloat
    var rotation: CGFloat
    var scaleX: CGFloat
    var scaleY: CGFloat

    static let rest = MascotDancePose(x: 0, y: 0, rotation: 0, scaleX: 1, scaleY: 1)

    private static let cycleDuration: TimeInterval = 6.4

    private static let choreography: [(time: TimeInterval, pose: MascotDancePose)] = [
        (0.00, rest),
        // Anticipation and a springy first lift.
        (0.45, MascotDancePose(x: 0, y: 5, rotation: 0, scaleX: 1.045, scaleY: 0.92)),
        (0.74, MascotDancePose(x: -5, y: -10, rotation: -5, scaleX: 0.96, scaleY: 1.085)),
        (1.00, MascotDancePose(x: -4, y: -4, rotation: -3, scaleX: 1.02, scaleY: 1.01)),
        // Two-step sway. Each weight shift has a small center rebound.
        (1.35, MascotDancePose(x: -9, y: 0, rotation: -7, scaleX: 1.025, scaleY: 0.985)),
        (1.68, MascotDancePose(x: 0, y: -4, rotation: 0, scaleX: 0.985, scaleY: 1.04)),
        (2.00, MascotDancePose(x: 9, y: 0, rotation: 7, scaleX: 1.025, scaleY: 0.985)),
        (2.32, MascotDancePose(x: 0, y: -4, rotation: 0, scaleX: 0.985, scaleY: 1.04)),
        (2.63, MascotDancePose(x: -8, y: 0, rotation: -6, scaleX: 1.025, scaleY: 0.985)),
        (2.94, MascotDancePose(x: 8, y: 0, rotation: 6, scaleX: 1.025, scaleY: 0.985)),
        (3.20, rest),
        // A distinct little hop, soft squash on landing, then settle.
        (3.47, MascotDancePose(x: 0, y: 4, rotation: 0, scaleX: 1.035, scaleY: 0.93)),
        (3.70, MascotDancePose(x: 0, y: -13, rotation: 0, scaleX: 0.97, scaleY: 1.085)),
        (3.88, MascotDancePose(x: 0, y: 4, rotation: 0, scaleX: 1.055, scaleY: 0.90)),
        (4.10, MascotDancePose(x: 0, y: -3, rotation: 0, scaleX: 0.985, scaleY: 1.04)),
        (4.35, rest),
        // A quiet, friendly sway before the loop returns to anticipation.
        (5.00, MascotDancePose(x: 4, y: 0, rotation: 3, scaleX: 1.01, scaleY: 0.995)),
        (5.35, MascotDancePose(x: 0, y: -2, rotation: 0, scaleX: 0.995, scaleY: 1.015)),
        (cycleDuration, rest)
    ]

    static func pose(at time: TimeInterval) -> MascotDancePose {
        let wrappedTime = ((time.truncatingRemainder(dividingBy: cycleDuration))
            + cycleDuration)
            .truncatingRemainder(dividingBy: cycleDuration)

        guard let nextIndex = choreography.firstIndex(where: { $0.time >= wrappedTime }),
              nextIndex > 0 else {
            return rest
        }

        let previous = choreography[nextIndex - 1]
        let next = choreography[nextIndex]
        let duration = next.time - previous.time
        guard duration > 0 else { return next.pose }

        let linearProgress = CGFloat((wrappedTime - previous.time) / duration)
        // Cubic ease-in/ease-out gives each pose a soft arrival and departure.
        let easedProgress = linearProgress * linearProgress * (3 - 2 * linearProgress)

        return MascotDancePose(
            x: interpolate(previous.pose.x, next.pose.x, easedProgress),
            y: interpolate(previous.pose.y, next.pose.y, easedProgress),
            rotation: interpolate(previous.pose.rotation, next.pose.rotation, easedProgress),
            scaleX: interpolate(previous.pose.scaleX, next.pose.scaleX, easedProgress),
            scaleY: interpolate(previous.pose.scaleY, next.pose.scaleY, easedProgress)
        )
    }

    private static func interpolate(_ from: CGFloat, _ to: CGFloat, _ progress: CGFloat) -> CGFloat {
        from + (to - from) * progress
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
            timingColor: priority.timingColor
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
