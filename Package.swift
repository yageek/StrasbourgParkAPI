// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StrasbourgParkAPI",
    products: [
        .library(
            name: "StrasbourgParkAPI",
            targets: ["StrasbourgParkAPI"]),
        
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "StrasbourgParkAPI",
            dependencies: [.product(name: "Logging", package: "swift-log")]),
        .testTarget(
            name: "StrasbourgParkAPITests",
            dependencies: ["StrasbourgParkAPI"],
            resources: [
                .copy("samples")]),
    ]
)
