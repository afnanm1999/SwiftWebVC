// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftWebVC",
    defaultLocalization: "en",
    products: [
        .library(
            name: "SwiftWebVC",
            targets: ["SwiftWebVC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AFNetworking/AFNetworking.git", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        .target(
            name: "SwiftWebVC",
            dependencies: ["AFNetworking"]),
    ]
)
