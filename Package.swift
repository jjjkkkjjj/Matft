// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Matft",
    // The same as SwiftPM's default. The other platforms (tvOS, watchOS, visionOS) use SwiftPM's default and are not tested
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "Matft",
            targets: ["Matft"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "pocketFFT"
            ),
        .target(
            name: "Matft",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                "pocketFFT",
            ]),
        .testTarget(
            name: "MatftTests",
            dependencies: ["Matft"]),
        .testTarget(
            name: "PerformanceTests",
            dependencies: ["Matft"]),
    ]
)
