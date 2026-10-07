import SwiftUI

/// The one-time result summary shown after the visual inbox analysis completes.
@MainActor
public struct OnboardingAnalysisResultsView: View {
    private let onViewPriorityInbox: () -> Void
    private let showsBackground: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var totalSize: CGFloat = 40
    @State private var cardStage = 0
    @State private var countsVisible = false
    @State private var showingInfo = false
    @State private var didSendSettleHaptic = false

    public init(
        showsBackground: Bool = true,
        onViewPriorityInbox: @escaping () -> Void = {}
    ) {
        self.showsBackground = showsBackground
        self.onViewPriorityInbox = onViewPriorityInbox
    }

    public var body: some View {
        GeometryReader { proxy in
            let stackHeight = min(350, max(296, proxy.size.height * 0.44))

            ZStack {
                if showsBackground {
                    InboxAnalysisBackground()
                }

                VStack(spacing: 0) {
                    resultHeading
                        .padding(.top, 12)

                    Spacer(minLength: 12)

                    cardStack(width: max(0, proxy.size.width - 48), height: stackHeight)
                        .frame(height: stackHeight)

                    Spacer(minLength: 10)

                    Text("Based on \(AnalysisResultsFixture.totalEmails) emails reviewed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.84))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .accessibilityLabel("Based on \(AnalysisResultsFixture.totalEmails) emails reviewed")

                    OnboardingActionButton(
                        title: "View Priority Inbox",
                        tone: .primary,
                        height: 52,
                        action: onViewPriorityInbox
                    )
                    .accessibilityHint("Opens your priorities for today.")
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .sheet(isPresented: $showingInfo) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How these results work")
                        .font(.title3.weight(.semibold))
                    Text("ATTN groups analyzed messages by the action they may need. Review the original email when a detail or deadline matters.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .navigationTitle("About these results")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showingInfo = false }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(.light)
        .task {
            await assembleCards()
        }
    }

    private var resultHeading: some View {
        VStack(spacing: 5) {
            Text("\(countsVisible ? AnalysisResultsFixture.totalEmails : 0) emails")
                .font(.system(size: totalSize, weight: .bold, design: .default))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .monospacedDigit()
                .accessibilityLabel("\(AnalysisResultsFixture.totalEmails) emails analyzed")

            HStack(spacing: 7) {
                Text("Need your attention")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Button {
                    showingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About these results")
                .accessibilityHint("Explains how ATTN groups analyzed messages.")
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private func cardStack(width: CGFloat, height: CGFloat) -> some View {
        let frontWidth = min(width - 14, 354)
        let frontHeight = min(height - 42, 278)

        return ZStack {
            translucentCard(width: frontWidth - 18, height: frontHeight - 8)
                .rotationEffect(.degrees(-12.74))
                .offset(x: -22, y: cardStage >= 1 ? -2 : 38)
                .scaleEffect(cardStage >= 1 ? 1 : 0.965)
                .opacity(cardStage >= 1 ? 1 : 0)
                .zIndex(0)
                .accessibilityHidden(true)

            translucentCard(width: frontWidth - 10, height: frontHeight - 2)
                .rotationEffect(.degrees(9.5))
                .offset(x: 19, y: cardStage >= 2 ? -1 : 38)
                .scaleEffect(cardStage >= 2 ? 1 : 0.965)
                .opacity(cardStage >= 2 ? 1 : 0)
                .zIndex(1)
                .accessibilityHidden(true)

            summaryCard(width: frontWidth, height: frontHeight)
                .offset(y: cardStage >= 3 ? 0 : 38)
                .scaleEffect(cardStage >= 3 ? 1 : 0.965)
                .opacity(cardStage >= 3 ? 1 : 0)
                .zIndex(2)
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .contain)
    }

    private func translucentCard(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.white.opacity(0.31))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.62), lineWidth: 1)
            }
            .frame(width: width, height: height)
            .shadow(color: Color.black.opacity(0.035), radius: 12, y: 5)
    }

    private func summaryCard(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(AnalysisResultsFixture.items.indices, id: \.self) { index in
                let item = AnalysisResultsFixture.items[index]
                resultRow(item, isLast: index == AnalysisResultsFixture.items.count - 1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(width: width, height: height)
        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.95), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 22, y: 12)
        .accessibilityElement(children: .contain)
    }

    private func resultRow(_ item: AnalysisResultItem, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: item.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.tint)
                    .frame(width: 38, height: 38)
                    .background(item.tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AnalysisResultsPalette.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)

                    Text(item.detail)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AnalysisResultsPalette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }

                Spacer(minLength: 2)

                Text(countsVisible ? "\(item.count)" : "0")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(AnalysisResultsPalette.primaryText)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 66)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(item.count) emails. \(item.title). \(item.detail).")

            if !isLast {
                Rectangle()
                    .fill(AnalysisResultsPalette.separator)
                    .frame(height: 0.7)
                    .padding(.leading, 50)
                    .accessibilityHidden(true)
            }
        }
    }

    @MainActor
    private func assembleCards() async {
        guard cardStage == 0 else { return }

        if reduceMotion {
            cardStage = 3
            countsVisible = true
            await sendSettleHapticOnce()
            return
        }

        withAnimation(.spring(duration: 0.48, bounce: 0.12)) {
            cardStage = 1
        }
        try? await Task.sleep(for: .milliseconds(60))
        guard !Task.isCancelled else { return }

        withAnimation(.spring(duration: 0.48, bounce: 0.12)) {
            cardStage = 2
        }
        withAnimation(.easeOut(duration: 0.28)) {
            countsVisible = true
        }
        try? await Task.sleep(for: .milliseconds(65))
        guard !Task.isCancelled else { return }

        withAnimation(.spring(duration: 0.48, bounce: 0.12)) {
            cardStage = 3
        }
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await sendSettleHapticOnce()
    }

    @MainActor
    private func sendSettleHapticOnce() async {
        guard !didSendSettleHaptic else { return }
        didSendSettleHaptic = true
        AttnHaptics.success()
    }
}

private struct AnalysisResultItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let count: Int
    let symbol: String
    let tint: Color
}

private enum AnalysisResultsFixture {
    static let totalEmails = 14

    static let items = [
        AnalysisResultItem(
            id: "today",
            title: "Action needed today",
            detail: "3 emails due today",
            count: 3,
            symbol: "clock.fill",
            tint: AnalysisResultsPalette.immediate
        ),
        AnalysisResultItem(
            id: "upcoming",
            title: "Calendar follow-ups",
            detail: "2 emails due this week",
            count: 2,
            symbol: "calendar",
            tint: AnalysisResultsPalette.upcoming
        ),
        AnalysisResultItem(
            id: "fyi",
            title: "No immediate action",
            detail: "2 FYI emails",
            count: 2,
            symbol: "tray.fill",
            tint: AnalysisResultsPalette.neutral
        )
    ]
}

private enum AnalysisResultsPalette {
    static let primaryText = Color(red: 27.0 / 255.0, green: 29.0 / 255.0, blue: 33.0 / 255.0)
    static let secondaryText = Color(red: 115.0 / 255.0, green: 117.0 / 255.0, blue: 123.0 / 255.0)
    static let separator = Color(red: 224.0 / 255.0, green: 226.0 / 255.0, blue: 229.0 / 255.0)
    static let immediate = Color(red: 239.0 / 255.0, green: 78.0 / 255.0, blue: 69.0 / 255.0)
    static let upcoming = Color(red: 0, green: 135.0 / 255.0, blue: 220.0 / 255.0)
    static let neutral = Color(red: 128.0 / 255.0, green: 132.0 / 255.0, blue: 140.0 / 255.0)
}

#Preview("Analysis results") {
    OnboardingAnalysisResultsView()
}
