import SwiftUI

/// Interactive sample data only. No Gmail connection or analysis is performed.
public struct PriorityCardShowcase: View {
    @State private var selection: TodaySection = .immediate
    @State private var reviewed: Set<String> = []
    @State private var notice = ""
    @State private var showingNotice = false
    @State private var showingProfile = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AttnSpacing.section) {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        TodayBriefingHeader(
                            date: context.date,
                            selection: $selection,
                            onProfile: { showingProfile = true }
                        )
                    }
                    .padding(.bottom, 8)

                    if selection == .immediate {
                        sample(
                            id: "payment",
                            title: "Credit card payment",
                            timing: "Due today",
                            sender: "RBC Mastercard",
                            initials: "RBC",
                            tone: AttnColors.priorityBlue,
                            logoColor: Color(red: 19 / 255, green: 94 / 255, blue: 171 / 255)
                        )
                        sample(
                            id: "flight",
                            title: "Flight check-in",
                            timing: "Opens in 3 hours",
                            sender: "Example Air",
                            initials: "EA",
                            tone: AttnColors.priorityGreen,
                            logoColor: Color(red: 0.04, green: 0.32, blue: 0.19)
                        )
                        sample(
                            id: "uncertain",
                            title: "Possible appointment change",
                            timing: "Timing unconfirmed",
                            sender: "Example Clinic",
                            initials: "EC",
                            tone: AttnColors.priorityCyan,
                            logoColor: Color(red: 0.02, green: 0.31, blue: 0.38),
                            attention: .needsReview
                        )
                    } else {
                        sample(
                            id: "interview",
                            title: "Interview",
                            timing: "Tomorrow · 9:30 AM",
                            sender: "Example Studio",
                            initials: "ES",
                            tone: AttnColors.priorityOrange,
                            logoColor: Color(red: 0.48, green: 0.19, blue: 0.02),
                            attention: .upcoming
                        )
                    }

                    Text("Sample priorities · Gmail is not connected")
                        .font(AttnTypography.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AttnSpacing.panel)
                .padding(.vertical, AttnSpacing.content)
            }
            .background(AttnColors.background)
            .toolbar(.hidden, for: .navigationBar)
            .alert("Design preview", isPresented: $showingNotice) {
                Button("OK", role: .cancel) {}
            } message: { Text(notice) }
        }
        .fullScreenCover(isPresented: $showingProfile) { ProfileView() }
    }

    private func sample(
        id: String, title: String, timing: String, sender: String,
        initials: String, tone: Color, logoColor: Color,
        attention: PriorityCard<Text>.Attention = .immediate
    ) -> some View {
        PriorityCard(
            title: title, timing: timing, sender: sender, attention: attention,
            brand: PriorityBrand(tone: tone, logoBackground: logoColor),
            isReviewed: reviewed.contains(id),
            onOpen: { show("The next screen will explain why “" + title + "” matters. This preview tests the card only.") },
            onReview: {
                if reviewed.contains(id) { reviewed.remove(id) }
                else { reviewed.insert(id); AttnHaptics.success() }
            },
            onOpenGmail: { show("This is sample content. No Gmail message is connected.") },
            onSnooze: { show("Snooze selected for “" + title + "”. Scheduling is not connected in this component preview.") },
            onNotImportant: { show("Not important selected for “" + title + "”. No learning data is saved in this preview.") }
        ) { Text(initials) }
    }

    private func show(_ message: String) {
        notice = message
        showingNotice = true
    }
}

#Preview("Standard") { PriorityCardShowcase() }
#Preview("Dark") { PriorityCardShowcase().preferredColorScheme(.dark) }
#Preview("Large text") { PriorityCardShowcase().environment(\.dynamicTypeSize, .accessibility3) }
