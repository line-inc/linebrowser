// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LineBrowser",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executableLibrary(
            name: "LineBrowser",
            targets: ["LineBrowser"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LineBrowser",
            path: "."
        )
    ]
)
