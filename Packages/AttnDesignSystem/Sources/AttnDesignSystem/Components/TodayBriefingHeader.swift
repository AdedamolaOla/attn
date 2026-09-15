import SwiftUI

/// The two attention horizons in Today.
public enum TodaySection: String, CaseIterable, Identifiable, Sendable {
    case immediate = "Immediate"
    case upcoming = "Upcoming"

    public var id: Self { self }
}

/// Daily briefing and native horizon selector.
/// Place below a NavigationStack's large "Today" title.
/// Summary text comes from the host so this component makes no analysis claims.
public struct TodayBriefingHeader: View {
    private let summary: String
    @Binding private var selection: TodaySection

    public init(summary: String, selection: Binding<TodaySection>) {
        self.summary = summary
        self._selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AttnSpacing.section) {
            Text(summary)
                .font(AttnTypography.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("today.summary")

            Picker("Attention horizon", selection: $selection) {
                ForEach(TodaySection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("today.horizon")
        }
    }
}

private struct TodayHeaderPreview: View {
    let summary: String
    @State private var selection: TodaySection = .immediate

    var body: some View {
        NavigationStack {
            ScrollView {
                TodayBriefingHeader(summary: summary, selection: $selection)
                    .padding(AttnSpacing.content)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview("Briefing") {
    TodayHeaderPreview(summary: "Two priorities need attention. One item needs review.")
}
#Preview("All clear") {
    TodayHeaderPreview(summary: "Nothing urgent today.")
}
#Preview("One priority") {
    TodayHeaderPreview(summary: "One deadline is approaching.")
}
#Preview("Accessible text") {
    TodayHeaderPreview(summary: "Your travel plans become important tomorrow.")
        .environment(\.dynamicTypeSize, .accessibility3)
}
