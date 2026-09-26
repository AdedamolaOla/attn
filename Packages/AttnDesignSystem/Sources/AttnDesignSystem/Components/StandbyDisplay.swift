import SwiftUI
import UIKit

/// Full-screen standby surface opened from the Home mascot.
///
/// The Figma canvas is 1328 × 616 and landscape. On a portrait iPhone we
/// rotate the same canvas rather than reflowing it into a portrait dashboard;
/// this preserves the intended left-rail / right-priority composition.
public struct StandbyDisplayView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let isPortrait = proxy.size.width < proxy.size.height

            TimelineView(.periodic(from: .now, by: 1)) { context in
                StandbyDisplayCanvas(
                    date: context.date,
                    onDismiss: { dismiss() }
                )
            }
            .frame(
                width: isPortrait ? proxy.size.height : proxy.size.width,
                height: isPortrait ? proxy.size.width : proxy.size.height
            )
            .rotationEffect(isPortrait ? .degrees(90) : .zero)
        }
        .background(.black)
        .ignoresSafeArea()
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
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        if #available(iOS 16.0, *) {
            scene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
            )
        }
    }

    static func requestPortrait() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        if #available(iOS 16.0, *) {
            scene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            )
        }
    }
}

private struct StandbyDisplayCanvas: View {
    let date: Date
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let blue = Color(red: 0, green: 159 / 255, blue: 254 / 255)
    private let cream = Color(red: 249 / 255, green: 251 / 255, blue: 227 / 255)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [blue, cream],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack(spacing: 22) {
                    leftRail
                        .frame(width: proxy.size.width * 0.39)

                    attentionColumn
                        .frame(width: proxy.size.width * 0.61 - 22)
                }
                .padding(24)
            }
            .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Standby display")
    }

    private var leftRail: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(timeLabel)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .tracking(-3)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.65)

                Text(dateLabel)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.84))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 14)

            Spacer(minLength: 10)

            FloatingStandbyMascot(reduceMotion: reduceMotion)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
        }
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeLabel), \(dateLabel), attn mascot")
    }

    private var attentionColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                Text("Needs attn. (6)")
                    .font(.system(size: 28, weight: .semibold))
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

            ScrollView(showsIndicators: false) {
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
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        // The priority rows remain separate raised cards. The Figma canvas does
        // not group them inside one enclosing black container.
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

private struct FloatingStandbyMascot: View {
    let reduceMotion: Bool

    var body: some View {
        Group {
            if reduceMotion {
                mascot(offset: .zero, scale: 1)
            } else {
                TimelineView(.animation) { context in
                    let phase = context.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: 7.6) / 7.6 * Double.pi * 2
                    mascot(
                        offset: CGSize(
                            width: CGFloat(sin(phase) * 2.5),
                            height: CGFloat(cos(phase * 0.82) * 2.2)
                        ),
                        scale: 1.004 + CGFloat(sin(phase * 0.5) * 0.002)
                    )
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func mascot(offset: CGSize, scale: CGFloat) -> some View {
        AttnMascotQuestion(width: 360)
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
