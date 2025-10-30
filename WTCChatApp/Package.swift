// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WTCChatApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "WTCChatApp",
            targets: ["WTCChatApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "WTCChatApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ]
        )
    ]
)
