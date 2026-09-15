import SwiftUI
import UIKit

/// Semantic colors used throughout attn.
public enum AttnColors {
    public static let background = Color(uiColor: .systemBackground)
    public static let surfaceSecondary = Color(uiColor: .secondarySystemBackground)
    public static let textPrimary = Color.primary
    public static let textSecondary = Color(red: 119 / 255, green: 118 / 255, blue: 126 / 255)
    public static let separator = Color(uiColor: .separator)

    public static let surfacePriority = Color(red: 16 / 255, green: 16 / 255, blue: 18 / 255)
    public static let surfaceConfidence = Color(red: 169 / 255, green: 239 / 255, blue: 228 / 255)

    public static let priorityBlue = Color(red: 124 / 255, green: 208 / 255, blue: 255 / 255)
    public static let priorityGreen = Color(red: 36 / 255, green: 203 / 255, blue: 113 / 255)
    public static let priorityOrange = Color(red: 255 / 255, green: 136 / 255, blue: 0 / 255)
    public static let priorityCyan = Color(red: 0 / 255, green: 217 / 255, blue: 255 / 255)

    public static let attentionImmediate = Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
    public static let resolved = Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255)
}
