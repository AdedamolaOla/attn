import SwiftUI

/// A lightweight visual check for the foundations while components are built.
public struct FoundationShowcase: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AttnSpacing.section) {
                Text("attn foundations")
                    .font(AttnTypography.largeTitle)

                VStack(alignment: .leading, spacing: AttnSpacing.card) {
                    Text("Priority")
                        .font(AttnTypography.title)
                        .foregroundStyle(.white)

                    Text("The important things don’t fall through the cracks.")
                        .font(AttnTypography.body)
                        .foregroundStyle(.white.opacity(0.72))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AttnSpacing.content)
                .background(AttnColors.surfacePriority)
                .clipShape(.rect(cornerRadius: AttnRadius.card))
                .attnCardElevation()

                VStack(alignment: .leading, spacing: AttnSpacing.compact) {
                    Text("High confidence")
                        .font(AttnTypography.headline)
                    Text("Gmail connected · Recently synced")
                        .font(AttnTypography.subheadline)
                        .foregroundStyle(AttnColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AttnSpacing.content)
                .background(AttnColors.surfaceConfidence)
                .clipShape(.rect(cornerRadius: AttnRadius.panel))

                HStack(spacing: AttnSpacing.compact) {
                    swatch(AttnColors.priorityBlue)
                    swatch(AttnColors.priorityGreen)
                    swatch(AttnColors.priorityOrange)
                    swatch(AttnColors.priorityCyan)
                    swatch(AttnColors.attentionImmediate)
                }
            }
            .padding(AttnSpacing.content)
        }
        .background(AttnColors.background)
    }

    private func swatch(_ color: Color) -> some View {
        color
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .clipShape(.rect(cornerRadius: AttnRadius.control))
            .accessibilityHidden(true)
    }
}

#Preview {
    FoundationShowcase()
}
