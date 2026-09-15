import SwiftUI

/// Brand appearance supplied alongside the logo, independently of urgency.
/// The caller is responsible for choosing a readable logo foreground.
public struct PriorityBrand {
    public let tone: Color
    public let logoBackground: Color
    public let logoForeground: Color

    public init(tone: Color, logoBackground: Color, logoForeground: Color = .white) {
        self.tone = tone
        self.logoBackground = logoBackground
        self.logoForeground = logoForeground
    }
}

/// A meaning-first card based on Figma PriorityCard/Default (74:1326).
/// The host owns review state, navigation, Gmail access and persistence.
public struct PriorityCard<Logo: View>: View {
    public enum Attention: String, CaseIterable, Sendable {
        case immediate, upcoming, needsReview
    }

    private let title: String
    private let timing: String
    private let sender: String
    private let attention: Attention
    private let brand: PriorityBrand
    private let isReviewed: Bool
    private let onOpen: () -> Void
    private let onReview: () -> Void
    private let onOpenGmail: () -> Void
    private let onSnooze: () -> Void
    private let onNotImportant: () -> Void
    private let logo: Logo
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var timingSize = 14

    public init(
        title: String, timing: String, sender: String,
        attention: Attention = .immediate,
        brand: PriorityBrand, isReviewed: Bool,
        onOpen: @escaping () -> Void,
        onReview: @escaping () -> Void,
        onOpenGmail: @escaping () -> Void,
        onSnooze: @escaping () -> Void,
        onNotImportant: @escaping () -> Void,
        @ViewBuilder logo: () -> Logo
    ) {
        self.title = title
        self.timing = timing
        self.sender = sender
        self.attention = attention
        self.brand = brand
        self.isReviewed = isReviewed
        self.onOpen = onOpen
        self.onReview = onReview
        self.onOpenGmail = onOpenGmail
        self.onSnooze = onSnooze
        self.onNotImportant = onNotImportant
        self.logo = logo()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AttnSpacing.card) {
            Button(action: onOpen) {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: AttnSpacing.row))
                    : AnyLayout(HStackLayout(alignment: .center, spacing: AttnSpacing.row))
                layout {
                    logo
                        .font(AttnTypography.titleSmall)
                        .foregroundStyle(brand.logoForeground)
                        .frame(width: 64, height: 64)
                        .background(brand.logoBackground, in: .rect(cornerRadius: 17.067))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AttnSpacing.compact) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(AttnTypography.headline)
                                .foregroundStyle(.white)
                            Text(attention == .needsReview ? "Needs review · " + timing : timing)
                                .font(.system(size: timingSize, weight: .semibold))
                                .foregroundStyle(timingColor)
                        }
                        Text(sender)
                            .font(AttnTypography.caption)
                            .foregroundStyle(AttnColors.onDarkTertiary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AttnSpacing.content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AttnColors.surfaceWidget, in: .rect(cornerRadius: AttnRadius.priorityInner))
                .shadow(color: .black.opacity(0.08), radius: 3.9, y: 4)
                .contentShape(.rect(cornerRadius: AttnRadius.priorityInner))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens why this matters")
            .contextMenu { menuActions }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AttnSpacing.compact) {
                    reviewButton
                    gmailButton
                    Spacer(minLength: 0)
                    moreMenu
                }
                VStack(alignment: .leading, spacing: AttnSpacing.compact) {
                    reviewButton
                    gmailButton
                    moreMenu
                }
            }
        }
        .padding(AttnSpacing.card)
        .background {
            RoundedRectangle(cornerRadius: AttnRadius.card)
                .fill(brand.tone
                    .shadow(.inner(color: .white.opacity(0.36), radius: 1.3, x: -2, y: 2))
                    .shadow(.inner(color: .black.opacity(0.25), radius: 1, x: 0, y: -2)))
                .overlay {
                    GeometryReader { geometry in
                        // Decorative light only; kept behind the opaque content.
                        Circle()
                            .fill(.white.opacity(0.42))
                            .frame(width: 188, height: 188)
                            .blur(radius: 50)
                            .position(x: 40, y: 16)
                        Circle()
                            .fill(.white.opacity(0.42))
                            .frame(width: 188, height: 188)
                            .blur(radius: 50)
                            .position(x: geometry.size.width - 28,
                                      y: geometry.size.height - 16)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
        }
        .clipShape(.rect(cornerRadius: AttnRadius.card))
    }

    private var timingColor: Color {
        switch attention {
        case .immediate: AttnColors.actionNeeded
        case .upcoming: .white
        case .needsReview: .orange
        }
    }

    private var reviewButton: some View {
        Button(action: onReview) {
            Text(isReviewed ? "Undo review" : "Reviewed")
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(PriorityPillStyle(dark: true))
        .accessibilityLabel(isReviewed ? "Undo review" : "Mark reviewed")
        .accessibilityHint("Reviewing does not confirm a payment or complete an action")
    }

    private var gmailButton: some View {
        Button("Open in Gmail", action: onOpenGmail)
            .buttonStyle(PriorityPillStyle(dark: false))
    }

    private var moreMenu: some View {
        Menu { menuActions } label: {
            Image(systemName: "ellipsis")
                .font(.headline)
                .foregroundStyle(AttnColors.surfacePriority)
                .frame(width: 49, height: 44)
                .background(.white, in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More actions for " + title)
    }

    @ViewBuilder private var menuActions: some View {
        Button("Why this matters", action: onOpen)
        Button(isReviewed ? "Undo review" : "Mark reviewed", action: onReview)
        if !isReviewed {
            Button("Snooze", action: onSnooze)
            Button("Not important", action: onNotImportant)
        }
        Button("Open in Gmail", action: onOpenGmail)
    }
}

private struct PriorityPillStyle: ButtonStyle {
    let dark: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AttnTypography.footnote.weight(.semibold))
            .foregroundStyle(dark ? Color.white : AttnColors.surfacePriority)
            .padding(.horizontal, 13)
            .padding(.vertical, AttnSpacing.control)
            .frame(minHeight: 44)
            .background(dark ? AttnColors.surfacePriority : Color.white, in: .capsule)
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
