import SwiftUI
import UIKit

/// First-run welcome screen. The card and cloud artwork are Figma exports,
/// kept as bundled assets so the onboarding illustration stays faithful to the design.
@MainActor
public struct WelcomeView: View {
    private let onConnectMail: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var headlineSize: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 14

    @State private var flightVisible = false
    @State private var paymentVisible = false
    @State private var figmaVisible = false
    @State private var cloudVisible = false
    @State private var headlineVisible = false
    @State private var bodyVisible = false
    @State private var privacyVisible = false
    @State private var connectVisible = false
    @State private var hasStartedEntrance = false
    @State private var gradientDrift: CGFloat = 0

    public init(onConnectMail: @escaping () -> Void = {}) {
        self.onConnectMail = onConnectMail
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let isLandscape = size.width > size.height
            let bottomInset = proxy.safeAreaInsets.bottom
            let screenBottom = size.height + bottomInset

            let footerWidth = min(
                isLandscape ? size.width * 0.39 : size.width,
                screenBottom * (402.0 / 461.0)
            )
            let footerHeight = footerWidth * (461.0 / 402.0)
            let footerCropTop = footerHeight * 0.40
            let footerVisibleHeight = footerHeight - footerCropTop
            let footerCenterX = isLandscape ? footerWidth / 2 : size.width / 2
            let footerCenterY = screenBottom - footerVisibleHeight / 2

            let cardWidth = isLandscape
                ? min(size.width * 0.34, size.height * 0.34 * 2.15)
                : min(size.width * 0.75, size.height * 0.42 * 2.15)

            ZStack {
                movingBackground(in: size)

                // The export is cropped to its cloud/footer portion. Its original
                // shapes and button artwork remain intact; only the gradient above
                // the clouds comes from the animated background layer.
                WelcomeRaster(resourceName: "WelcomeCloudAndFooter")
                    .frame(width: footerWidth, height: footerHeight)
                    .offset(y: -footerCropTop)
                    .frame(width: footerWidth, height: footerVisibleHeight, alignment: .top)
                    .clipped()
                    .opacity(cloudVisible ? 1 : 0)
                    .position(x: footerCenterX, y: footerCenterY)
                    .accessibilityHidden(true)
                    .zIndex(0)

                cardArtwork(
                    resourceName: "WelcomeFlightCard",
                    label: "Flight check-in opens in three hours.",
                    width: cardWidth,
                    visible: flightVisible,
                    startOffset: CGSize(width: 68, height: -24),
                    rotation: 4.85,
                    isLandscape: isLandscape
                )
                .position(
                    x: isLandscape ? size.width * 0.68 : size.width * 0.49,
                    y: size.height * (isLandscape ? 0.25 : 0.37)
                )
                .zIndex(1)

                cardArtwork(
                    resourceName: "WelcomeFigmaCard",
                    label: "A Figma comment is waiting for review.",
                    width: cardWidth,
                    visible: figmaVisible,
                    startOffset: CGSize(width: 28, height: 50),
                    rotation: -1.97,
                    isLandscape: isLandscape
                )
                .position(
                    x: isLandscape ? size.width * 0.70 : size.width * 0.48,
                    y: size.height * (isLandscape ? 0.75 : 0.63)
                )
                .zIndex(2)

                cardArtwork(
                    resourceName: "WelcomePayment",
                    label: "Credit card payment due today.",
                    width: cardWidth,
                    visible: paymentVisible,
                    startOffset: CGSize(width: -70, height: 24),
                    rotation: 1.01,
                    isLandscape: isLandscape
                )
                .position(
                    x: isLandscape ? size.width * 0.73 : size.width * 0.51,
                    y: size.height * (isLandscape ? 0.50 : 0.49)
                )
                .zIndex(3)

                welcomeCopy(in: size, isLandscape: isLandscape)
                    .position(
                        x: isLandscape ? size.width * 0.24 : size.width / 2,
                        y: size.height * (isLandscape ? 0.29 : 0.142)
                    )
                    .zIndex(4)

                connectButton(
                    width: footerWidth,
                    footerHeight: footerHeight,
                    screenBottom: screenBottom,
                    centerX: footerCenterX
                )
                .opacity(connectVisible ? 1 : 0)
                .zIndex(5)

                // The matching text is already part of the Figma footer export.
                // This visually hidden label makes it available to VoiceOver.
                Text("Read-only access. Disconnect anytime.")
                    .font(.system(size: 12, weight: .medium))
                    .accessibilitySortPriority(1.1)
                    .opacity(0.001)
                    .allowsHitTesting(false)
                    .position(
                        x: footerCenterX,
                        y: screenBottom - footerHeight * (34.0 / 461.0)
                    )
                    .zIndex(6)
            }
            .frame(width: size.width, height: size.height)
            .onAppear(perform: startEntrance)
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.light)
        .tint(Color(hex: 0x087FF5))
    }

    private func movingBackground(in size: CGSize) -> some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x009FFE), location: 0),
                .init(color: Color(hex: 0xF9FBE3), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: size.width, height: size.height + 56)
        .offset(y: -28 + (reduceMotion ? 0 : gradientDrift))
        .frame(width: size.width, height: size.height)
        .clipped()
        .accessibilityHidden(true)
    }

    private func welcomeCopy(in size: CGSize, isLandscape: Bool) -> some View {
        VStack(spacing: 13) {
            Text("Know what deserves\nyour attention.")
                .font(.system(size: headlineSize, weight: .bold, design: .default))
                .foregroundStyle(Color(hex: 0x19191B))
                .multilineTextAlignment(.center)
                .lineSpacing(0)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(headlineVisible ? 1 : 0)
                .offset(y: headlineVisible || reduceMotion ? 0 : 8)
                .accessibilitySortPriority(4)

            Text("attn quietly finds important emails before they become problems.")
                .font(.system(size: bodySize, weight: .medium, design: .default))
                .foregroundStyle(Color(hex: 0x51515A))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: isLandscape ? 320 : 340)
                .opacity(bodyVisible ? 1 : 0)
                .offset(y: bodyVisible || reduceMotion ? 0 : 6)
                .accessibilitySortPriority(3)
        }
        .frame(width: isLandscape ? min(size.width * 0.43, 360) : min(size.width - 40, 360))
        .frame(height: isLandscape ? 138 : 144)
    }

    private func cardArtwork(
        resourceName: String,
        label: String,
        width: CGFloat,
        visible: Bool,
        startOffset: CGSize,
        rotation: Double,
        isLandscape: Bool
    ) -> some View {
        WelcomeRaster(resourceName: resourceName, accessibilityLabel: label)
            .frame(width: width, height: width / 2.15)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(visible || reduceMotion ? 1 : 0.93)
            .offset(visible || reduceMotion ? .zero : startOffset)
            .opacity(visible ? 1 : 0)
            .accessibilitySortPriority(
                resourceName == "WelcomeFlightCard" ? 2.9 :
                    resourceName == "WelcomePayment" ? 2.8 : 2.7
            )
            .accessibilityHidden(false)
            .shadow(color: .black.opacity(0.015), radius: 1, y: 1)
    }

    private func connectButton(
        width: CGFloat,
        footerHeight: CGFloat,
        screenBottom: CGFloat,
        centerX: CGFloat
    ) -> some View {
        Button {
            AttnHaptics.impactLight()
            onConnectMail()
        } label: {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: width * (358.0 / 402.0), height: footerHeight * (53.0 / 461.0))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Connect your mail")
        .accessibilityHint("Connect Gmail with read-only access.")
        .accessibilitySortPriority(1.2)
        .position(
            x: centerX,
            y: screenBottom - footerHeight * (82.0 / 461.0)
        )
    }

    private func startEntrance() {
        guard !hasStartedEntrance else { return }
        hasStartedEntrance = true

        Task { @MainActor in
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.22)) {
                    flightVisible = true
                    figmaVisible = true
                    paymentVisible = true
                    cloudVisible = true
                }
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.easeOut(duration: 0.22)) {
                    headlineVisible = true
                }
                try? await Task.sleep(for: .milliseconds(55))
                withAnimation(.easeOut(duration: 0.22)) {
                    bodyVisible = true
                }
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(.easeOut(duration: 0.22)) {
                    privacyVisible = true
                }
                try? await Task.sleep(for: .milliseconds(75))
                withAnimation(.easeOut(duration: 0.22)) {
                    connectVisible = true
                }
                return
            }

            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                flightVisible = true
            }
            withAnimation(.easeOut(duration: 0.30)) {
                cloudVisible = true
            }
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                figmaVisible = true
            }
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                paymentVisible = true
            }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeOut(duration: 0.32)) {
                headlineVisible = true
            }
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.easeOut(duration: 0.30)) {
                bodyVisible = true
            }
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeOut(duration: 0.22)) {
                privacyVisible = true
            }
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.easeOut(duration: 0.28)) {
                connectVisible = true
            }

            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                gradientDrift = 56
            }
        }
    }
}

@MainActor
private struct WelcomeRaster: View {
    private let accessibilityLabel: String?
    @State private var image: UIImage?

    init(resourceName: String, accessibilityLabel: String? = nil) {
        self.accessibilityLabel = accessibilityLabel
        _image = State(initialValue: Self.load(resourceName: resourceName))
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.clear
            }
        }
        .accessibilityLabel(accessibilityLabel ?? "")
        .accessibilityAddTraits(accessibilityLabel == nil ? [] : .isImage)
    }

    private static func load(resourceName: String) -> UIImage? {
        guard
            let url = Bundle.module.url(forResource: resourceName, withExtension: "b64"),
            let encoded = try? String(contentsOf: url, encoding: .utf8),
            let data = Data(base64Encoded: encoded),
            let image = UIImage(data: data, scale: 1)
        else {
            return nil
        }
        return image
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

#Preview("Welcome") {
    WelcomeView()
}
