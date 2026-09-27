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

    public init() {
        AttnAgbalumoFont.register()
    }

    public var body: some View {
        // Standby is a living surface: the clock and the slow background
        // motion share one animation timeline.
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            StandbyDisplayCanvas(
                date: context.date,
                onDismiss: { dismiss() }
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset: CGFloat = 24
            let topInset: CGFloat = 24
            let bottomInset: CGFloat = 0
            let contentWidth = finitePositive(proxy.size.width - (horizontalInset * 2))
            // Keep the top inset from the composition, but let the content
            // run to the rounded bottom edge. A bottom inset here creates the
            // visible horizontal cut line seen in the standby screenshot.
            let contentHeight = finitePositive(proxy.size.height - topInset - bottomInset)
            let railWidth = finitePositive(contentWidth * 0.48)
            let attentionWidth = finitePositive(contentWidth - railWidth - 22)
            // Keep enough vertical breathing room for the clock, date, and
            // the mascot's transparent artwork bounds. This prevents the
            // mascot from being cropped by the bottom edge on short landscape
            // windows while preserving the larger treatment on iPad-sized
            // canvases.
            let mascotWidth = finitePositive(
                min(
                    920,
                    min(
                        railWidth - 16,
                        contentHeight * 0.86 * (CGFloat(629) / CGFloat(343))
                    )
                )
            )

            ZStack {
                AnimatedStandbyBackground(date: date, reduceMotion: reduceMotion)

                HStack(alignment: .top, spacing: 22) {
                    leftRail(mascotWidth: mascotWidth)
                        .frame(width: railWidth, height: contentHeight, alignment: .top)

                    attentionColumn
                        .frame(width: attentionWidth, height: contentHeight, alignment: .top)
                }
                .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
                .padding(.horizontal, horizontalInset)
                .padding(.top, topInset)
                .padding(.bottom, bottomInset)
            }
            .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Standby display")
    }

    private func leftRail(mascotWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(timeLabel)
                    .font(.custom(AttnAgbalumoFont.name, size: 72))
                    .tracking(-3)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.65)

                Text(dateLabel)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.84))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 100)

            Spacer(minLength: 10)

            FloatingStandbyMascot(width: mascotWidth, date: date, reduceMotion: reduceMotion)
                .frame(width: mascotWidth, alignment: .center)
                .padding(.bottom, 18)
        }
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeLabel), \(dateLabel), attn mascot")
    }

    private var attentionColumn: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center) {
                    Text("Needs attn. (6)")
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

                VStack(spacing: 16) {
                    StandbyPriorityRow(
                        icon: "$",
                        iconBackground: Color(red: 217 / 255, green: 236 / 255, blue: 1),
                        title: "Credit card payment",
                        timing: "Due Today",
                        timingColor: Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
                    )
                    StandbyPriorityRow(
                        icon: "✈︎",
                        iconBackground: Color(red: 255 / 255, green: 235 / 255, blue: 213 / 255),
                        title: "Flight check-in",
                        timing: "Closes in 30mins",
                        timingColor: Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
                    )
                    StandbyPriorityRow(
                        icon: "📑",
                        iconBackground: Color(red: 201 / 255, green: 247 / 255, blue: 255 / 255),
                        title: "Tax filing notice",
                        timing: "Closes in 1 hour",
                        timingColor: Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
                    )
                    StandbyPriorityRow(
                        icon: "🖌️",
                        iconBackground: Color(red: 189 / 255, green: 255 / 255, blue: 220 / 255),
                        title: "Figma edit access req...",
                        timing: "2days ago",
                        timingColor: .white.opacity(0.68)
                    )
                    StandbyPriorityRow(
                        icon: "☎️",
                        iconBackground: Color(red: 189 / 255, green: 255 / 255, blue: 220 / 255),
                        title: "Product Design Interv...",
                        timing: "In 8 hours",
                        timingColor: .white.opacity(0.68)
                    )
                    StandbyPriorityRow(
                        icon: "☎️",
                        iconBackground: Color(red: 189 / 255, green: 255 / 255, blue: 220 / 255),
                        title: "Product Design Interview",
                        timing: "Tomorrow · 9:30 AM",
                        timingColor: .white.opacity(0.68)
                    )
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        // The heading is intentionally inside the same scroll container as
        // the priority cards so the list moves as one continuous surface.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Six things need attention")
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

private struct AnimatedStandbyBackground: View {
    let date: Date
    let reduceMotion: Bool

    private let blue = Color(red: 0, green: 159 / 255, blue: 254 / 255)
    private let cream = Color(red: 249 / 255, green: 251 / 255, blue: 227 / 255)

    var body: some View {
        // The standby surface is intentionally alive: large, soft color fields
        // travel across the canvas instead of behaving like a static wallpaper.
        let phase = date.timeIntervalSinceReferenceDate * 0.30

        ZStack {
            LinearGradient(
                colors: [blue, cream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if !reduceMotion {
                // Blue field sweeps diagonally from the lower-left toward
                // the upper-right on a long, calm loop.
                RoundedRectangle(cornerRadius: 260, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                blue.opacity(0.95),
                                blue.opacity(0.42),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 920, height: 500)
                    .blur(radius: 92)
                    .rotationEffect(.degrees(Double(sin(phase * 0.52) * 12)))
                    .offset(
                        x: CGFloat(cos(phase * 0.82) * 250),
                        y: CGFloat(sin(phase * 0.64) * 135)
                    )

                // A warm, pale counter-field keeps the motion dimensional
                // without introducing a noisy animated texture.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                cream.opacity(0.92),
                                Color.white.opacity(0.38),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 300
                        )
                    )
                    .frame(width: 650, height: 650)
                    .blur(radius: 82)
                    .offset(
                        x: CGFloat(sin(phase * 0.58) * 235),
                        y: CGFloat(cos(phase * 0.76) * 105)
                    )

                // A restrained sheen slowly rotates through the moving fields.
                LinearGradient(
                    colors: [.clear, .white.opacity(0.18), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 1100, height: 420)
                .rotationEffect(.degrees(Double(sin(phase * 0.36) * 14)))
                .offset(x: CGFloat(cos(phase * 0.44) * 180))
                .blendMode(.screen)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .drawingGroup()
        .accessibilityHidden(true)
    }
}

private struct FloatingStandbyMascot: View {
    let width: CGFloat
    let date: Date
    let reduceMotion: Bool

    var body: some View {
        let phase = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: 7.6) / 7.6 * Double.pi * 2

        Group {
            if reduceMotion {
                mascot(offset: .zero, scale: 1)
            } else {
                mascot(
                    offset: CGSize(
                        width: CGFloat(sin(phase) * 2.5),
                        height: CGFloat(cos(phase * 0.82) * 2.2)
                    ),
                    scale: 1.004 + CGFloat(sin(phase * 0.5) * 0.002)
                )
            }
        }
        .accessibilityHidden(true)
    }

    private func mascot(offset: CGSize, scale: CGFloat) -> some View {
        AttnMascotQuestion(width: width)
            .offset(offset)
            .scaleEffect(scale)
            .frame(maxWidth: .infinity, alignment: .center)
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
