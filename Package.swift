// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChildModeKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ChildModeKit",
            targets: ["ChildModeKit"]),
    ],
    targets: [
        .target(
            name: "ChildModeKit",
            dependencies: []),
        .testTarget(
            name: "ChildModeKitTests",
            dependencies: ["ChildModeKit"]),
    ]
)