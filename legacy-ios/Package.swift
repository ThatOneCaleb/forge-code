// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ForgeCodeEngine",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ForgeCodeEngine",
            targets: ["ForgeCodeEngine"]
        )
    ],
    targets: [
        .target(
            name: "ForgeCodeEngine",
            resources: [
                .process("Content/code_basics.json"),
                .process("Content/challenges.json"),
                .process("Robotics/Content/robotics_fields.json"),
                .process("Robotics/Content/robotics_missions.json"),
                .process("Robotics/Content/robotics_matches.json")
            ]
        ),
        .testTarget(
            name: "ForgeCodeEngineTests",
            dependencies: ["ForgeCodeEngine"]
        )
    ]
)
