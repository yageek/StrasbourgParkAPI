// swift-tools-version:5.5
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
        .target(name: "StrasbourgParkAPIObjc"),
        .target(name: "StrasbourgParkAPIObjcPrivate", dependencies: [.target(name:"StrasbourgParkAPIObjc")]),
        .target(
            name: "StrasbourgParkAPI",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .target(name: "StrasbourgParkAPIObjc"),
                .target(name: "StrasbourgParkAPIObjcPrivate")
            ]),
        .testTarget(
            name: "StrasbourgParkAPITests",
            dependencies: ["StrasbourgParkAPI"],
            resources: [
                .copy("samples")]),
    ]
)
