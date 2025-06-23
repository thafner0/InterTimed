// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TimingModel",
    platforms: [.iOS(.v18), .macOS(.v15), .tvOS(.v18), .macCatalyst(.v18), .watchOS(.v11)],
    products: [
        .library(
            name: "TimingModel",
            targets: ["TimingModel"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.3")
    ],
    targets: [
        .target(
            name: "TimingModel"
        ),
        .testTarget(
            name: "TimingModelTests",
            dependencies: ["TimingModel", .product(name: "RealModule", package: "swift-numerics")]
        ),
    ]
)
