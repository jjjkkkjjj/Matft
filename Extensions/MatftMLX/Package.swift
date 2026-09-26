// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MatftMLX",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "MatftMLX",
            targets: ["MatftMLX"]),
    ],
    dependencies: [
        .package(name: "Matft", path: "../.."),
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.30.0"),
    ],
    targets: [
        .target(
            name: "MatftMLX",
            dependencies: [
                .product(name: "Matft", package: "Matft"),
                .product(name: "MLX", package: "mlx-swift"),
            ]),
        .testTarget(
            name: "MatftMLXTests",
            dependencies: ["MatftMLX"]),
        .executableTarget(
            name: "MatftMLXDemo",
            dependencies: [
                "MatftMLX",
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
            ],
            path: "Examples/MatftMLXDemo"),
    ]
)
