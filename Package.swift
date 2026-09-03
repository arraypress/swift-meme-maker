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
