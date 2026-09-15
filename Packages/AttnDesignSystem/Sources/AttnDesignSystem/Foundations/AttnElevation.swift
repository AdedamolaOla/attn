import SwiftUI

/// Reusable elevation treatments derived from existing attn surfaces.
public extension View {
    func attnCardElevation() -> some View {
        shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    func attnWidgetItemElevation() -> some View {
        shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    func attnToastElevation() -> some View {
        shadow(color: .black.opacity(0.14), radius: 18, y: 8)
    }

    func attnPriorityInset() -> some View {
        overlay {
            RoundedRectangle(cornerRadius: AttnRadius.priorityInner)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        }
    }
}
