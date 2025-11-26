// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "YogaDietApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "YogaDietApp",
            targets: ["YogaDietApp"])
    ],
    targets: [
        .target(
            name: "YogaDietApp",
            path: "Sources")
    ]
)
