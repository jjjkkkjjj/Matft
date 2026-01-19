// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Matft",
    products: [
        .library(
            name: "Matft",
            targets: ["Matft"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/goodnotes/CLAPACK", branch: "eigen-support"),
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
                .product(name: "CLAPACK", package: "CLAPACK", condition: .when(platforms: [.wasi])),
            ]),
        .testTarget(
            name: "MatftTests",
            dependencies: ["Matft"]),
        .testTarget(
            name: "PerformanceTests",
            dependencies: ["Matft"]),
    ]
)
