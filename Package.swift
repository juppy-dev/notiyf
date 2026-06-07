// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notiyf",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Notiyf", targets: ["Notiyf"])
    ],
    targets: [
        .executableTarget(
            name: "Notiyf",
            path: "Sources/Notiyf"
        ),
        .testTarget(
            name: "NotiyfTests",
            dependencies: ["Notiyf"],
            path: "Tests/NotiyfTests"
        )
    ]
)
