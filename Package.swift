// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MPMessagePack",
    platforms: [
        .iOS(.v8), .tvOS(.v10), .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "MPMessagePack",
            targets: ["MPMessagePack"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gabriel/GHODictionary", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "MPMessagePack",
            dependencies: ["GHODictionary"],
            path: "MPMessagePack",
            exclude: ["MPMessagePack.h"],
            cSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("include/RPC"),
                .headerSearchPath("include/XPC"),
            ]),
        .testTarget(
            name: "MPMessagePackTests",
            dependencies: ["MPMessagePack"],
            path: "MPMessagePackTests",
            exclude: ["Info.plist"]),
    ]
)
