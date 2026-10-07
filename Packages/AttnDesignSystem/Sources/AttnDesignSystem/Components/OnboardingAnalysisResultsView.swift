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
            let cardWidth = min(230, max(0, proxy.size.width - 36))
            let cardHeight: CGFloat = 230
            let cardSectionHeight: CGFloat = 276

            ZStack {
                if showsBackground {
                    InboxAnalysisBackground()
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 12)

                    resultHeading
                        .padding(.top, 20)
                        .padding(.bottom, 60)

                    cardStack(
                        sectionWidth: max(0, proxy.size.width - 48),
                        sectionHeight: cardSectionHeight,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight
                    )
                    .frame(height: cardSectionHeight)

                    Text("Based on your last 50 emails")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(AnalysisResultsPalette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 32)
                        .accessibilityLabel("Based on your last 50 emails")

                    Spacer(minLength: 12)

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
        .alert("About these results", isPresented: $showingInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We grouped your last 50 emails by the action each may need. Review the original email when a detail or deadline matters.")
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

            HStack(spacing: 4) {
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

    private func cardStack(
        sectionWidth: CGFloat,
        sectionHeight: CGFloat,
        cardWidth: CGFloat,
        cardHeight: CGFloat
    ) -> some View {
        ZStack {
            translucentCard(width: cardWidth, height: cardHeight)
                .rotationEffect(.degrees(-12.74))
                .offset(x: -48, y: cardStage >= 1 ? 0 : 38)
                .scaleEffect(cardStage >= 1 ? 1 : 0.965)
                .opacity(cardStage >= 1 ? 0.15 : 0)
                .zIndex(0)
                .accessibilityHidden(true)

            translucentCard(width: cardWidth, height: cardHeight)
                .rotationEffect(.degrees(12.74))
                .offset(x: 48, y: cardStage >= 2 ? 0 : 38)
                .scaleEffect(cardStage >= 2 ? 1 : 0.965)
                .opacity(cardStage >= 2 ? 0.15 : 0)
                .zIndex(1)
                .accessibilityHidden(true)

            summaryCard(width: cardWidth, height: cardHeight)
                .offset(y: cardStage >= 3 ? 0 : 38)
                .scaleEffect(cardStage >= 3 ? 1 : 0.965)
                .opacity(cardStage >= 3 ? 1 : 0)
                .zIndex(2)
        }
        .frame(width: sectionWidth, height: sectionHeight)
        .accessibilityElement(children: .contain)
    }

    private func translucentCard(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.white)
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
        .padding(20)
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
            VStack(spacing: 8) {
                Text(countsVisible ? item.header : item.loadingHeader)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AnalysisResultsPalette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .contentTransition(.numericText())

                Text(item.detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(item.detailIsUrgent
                        ? AnalysisResultsPalette.urgent
                        : AnalysisResultsPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, isLast ? 0 : 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(item.accessibilityHeader). \(item.detail).")

            if !isLast {
                Rectangle()
                    .fill(AnalysisResultsPalette.separator)
                    .frame(height: 1)
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
    let header: String
    let loadingHeader: String
    let accessibilityHeader: String
    let detail: String
    let detailIsUrgent: Bool
}

private enum AnalysisResultsFixture {
    static let totalEmails = 14

    static let items = [
        AnalysisResultItem(
            id: "today",
            header: "3 due today",
            loadingHeader: "0 due today",
            accessibilityHeader: "3 due today",
            detail: "Urgent Action Needed",
            detailIsUrgent: true
        ),
        AnalysisResultItem(
            id: "upcoming",
            header: "2 due this week",
            loadingHeader: "0 due this week",
            accessibilityHeader: "2 due this week",
            detail: "Follow-ups/requests",
            detailIsUrgent: false
        ),
        AnalysisResultItem(
            id: "fyi",
            header: "2 FYI / low priority",
            loadingHeader: "0 FYI / low priority",
            accessibilityHeader: "2 FYI / low priority",
            detail: "No Immediate Action",
            detailIsUrgent: false
        )
    ]
}

private enum AnalysisResultsPalette {
    static let primaryText = Color(red: 16.0 / 255.0, green: 16.0 / 255.0, blue: 18.0 / 255.0)
    static let secondaryText = Color(red: 119.0 / 255.0, green: 118.0 / 255.0, blue: 126.0 / 255.0)
    static let urgent = Color(red: 255.0 / 255.0, green: 69.0 / 255.0, blue: 59.0 / 255.0)
    static let separator = Color(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 247.0 / 255.0)
}

#Preview("Analysis results") {
    OnboardingAnalysisResultsView()
}
