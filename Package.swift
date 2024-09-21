// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DCBOR",
    platforms: [
        .macOS(.v13),
        .iOS(.v14),
        .macCatalyst(.v14)
    ],
    products: [
        .library(
            name: "DCBOR",
            targets: ["DCBOR"]),
    ],
    dependencies: [
        .package(url: "https://github.com/wolfmcnally/SwiftSortedCollections", from: "0.1.0"),
        .package(url: "https://github.com/wolfmcnally/WolfBase", from: "7.0.0"),
        .package(url: "https://github.com/blockchaincommons/BCSwiftFloat16", from: "2.0.0"),
        .package(url: "https://github.com/BlockchainCommons/BCSwiftTags", from: "0.2.0"),
        .package(url: "https://github.com/objecthub/swift-numberkit.git", .upToNextMajor(from: "2.6.0")),
    ],
    targets: [
        .target(
            name: "DCBOR",
            dependencies: [
                .product(name: "BCFloat16", package: "BCSwiftFloat16"),
                .product(name: "SortedCollections", package: "SwiftSortedCollections"),
                .product(name: "BCTags", package: "BCSwiftTags"),
                .product(name: "NumberKit", package: "swift-numberkit"),
            ]),
        .testTarget(
            name: "DCBORTests",
            dependencies: [
                "DCBOR",
                "WolfBase",
            ]),
    ]
)
