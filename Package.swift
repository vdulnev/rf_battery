// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RFBattery",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "RFBattery", path: "Sources/RFBattery"),
    ]
)
