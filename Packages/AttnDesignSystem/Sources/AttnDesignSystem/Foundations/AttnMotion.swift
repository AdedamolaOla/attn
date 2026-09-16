import SwiftUI

/// Motion timings and interaction values used by attn.
public enum AttnMotion {
    public static let feedback: TimeInterval = 0.120
    public static let micro: TimeInterval = 0.200
    public static let content: TimeInterval = 0.300
    public static let list: TimeInterval = 0.320
    public static let expressive: TimeInterval = 0.550
    public static let stagger: TimeInterval = 0.060

    public static let pressedScale: CGFloat = 0.98
    public static let entranceDistance: CGFloat = 8

    public static var feedbackAnimation: Animation {
        .easeOut(duration: feedback)
    }

    public static var contentAnimation: Animation {
        .spring(duration: content, bounce: 0.12)
    }

    public static var expressiveAnimation: Animation {
        .spring(duration: expressive, bounce: 0.18)
    }
}
