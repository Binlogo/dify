// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DifyClient",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "DifyClient",
            targets: ["DifyClient"]
        ),
    ],
    dependencies: [
        // No external dependencies - using only Foundation and URLSession
    ],
    targets: [
        .target(
            name: "DifyClient",
            dependencies: []
        ),
        .testTarget(
            name: "DifyClientTests",
            dependencies: ["DifyClient"]
        ),
    ]
) 