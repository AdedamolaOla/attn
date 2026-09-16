// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AttnDesignSystem",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "AttnDesignSystem", targets: ["AttnDesignSystem"])
    ],
    targets: [
        .target(name: "AttnDesignSystem", resources: [.process("Resources")]),
        .testTarget(
            name: "AttnDesignSystemTests",
            dependencies: ["AttnDesignSystem"]
        )
    ]
)
