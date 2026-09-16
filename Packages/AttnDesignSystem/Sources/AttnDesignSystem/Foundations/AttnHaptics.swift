import UIKit

/// Semantic haptic feedback used by meaningful attn interactions.
@MainActor
public enum AttnHaptics {
    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    public static func impactLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
