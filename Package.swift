// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MemeMaker",
    platforms: [.macOS(.v14)],
    products: [.library(name: "MemeMaker", targets: ["MemeMaker"])],
    targets: [
        .target(name: "MemeMaker", resources: [.process("Resources")]),
        .testTarget(name: "MemeMakerTests", dependencies: ["MemeMaker"]),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
