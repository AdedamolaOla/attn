import SwiftUI

public enum TodaySection: String, CaseIterable, Identifiable, Sendable {
    case immediate = "Immediate"
    case upcoming = "Upcoming"
    public var id: Self { self }
}

/// Home chrome from Figma 108:3829. Latest designer specifications
/// override the earlier large navigation title and system segmented Picker.
public struct TodayBriefingHeader: View {
    private let date: Date
    private let onProfile: () -> Void
    @Binding private var selection: TodaySection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .subheadline) private var dateSize = 14
    @ScaledMetric(relativeTo: .callout) private var tabHeight = 56
    @Namespace private var indicator

    public init(date: Date = .now, selection: Binding<TodaySection>,
                onProfile: @escaping () -> Void) {
        self.date = date
        self._selection = selection
        self.onProfile = onProfile
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: AttnSpacing.content) {
                // Fixed 8pt title-to-date gap from the design.
                VStack(alignment: .leading, spacing: AttnSpacing.compact) {
                    Text("Needs attn.")
                        .font(.title.bold())
                        .foregroundStyle(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))
                        .accessibilityAddTraits(.isHeader)
                    Text(dateLabel)
                        .font(.system(size: dateSize, weight: .medium))
                        .foregroundStyle(Color(red: 183 / 255, green: 183 / 255, blue: 183 / 255))
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onProfile) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 19))
                        .foregroundStyle(AttnColors.surfacePriority)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("Profile")
            }

            HStack(spacing: 0) {
                ForEach(TodaySection.allCases) { section in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            selection = section
                        }
                    } label: {
                        Text(section.rawValue)
                            .font(.callout.weight(selection == section ? .bold : .medium))
                            .foregroundStyle(selection == section
                                ? Color(red: 0, green: 122 / 255, blue: 1)
                                : Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: max(56, tabHeight))
                            .background {
                                if selection == section {
                                    Capsule()
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.08), radius: 16, x: 1, y: 2)
                                        .padding(.vertical, 8)
                                        .matchedGeometryEffect(id: "selection", in: indicator)
                                }
                            }
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == section ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 4)
            .background(Color(red: 252 / 255, green: 252 / 255, blue: 252 / 255), in: .capsule)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Attention horizon")
        }
    }
}

private struct TodayHeaderPreview: View {
    @State private var selection: TodaySection = .immediate
    var body: some View {
        TodayBriefingHeader(
            date: Date(timeIntervalSince1970: 1784548800),
            selection: $selection,
            onProfile: { /* Preview only. Host provides profile navigation. */ }
        )
        .padding(.horizontal, AttnSpacing.panel)
        .padding(.vertical, AttnSpacing.content)
    }
}

#Preview("Header") { TodayHeaderPreview() }
#Preview("Accessibility text") {
    TodayHeaderPreview().environment(\.dynamicTypeSize, .accessibility3)
}
