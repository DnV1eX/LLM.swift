// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "LLM",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "LLM",
            targets: ["LLM"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"606.0.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0")
    ],
    targets: [
        .binaryTarget(
            name: "llama",
            path: "llama.cpp/llama.xcframework"
        ),
        .macro(
            name: "LLMMacrosImplementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/LLMMacrosImplementation"
        ),
        .target(
            name: "LLMMacros",
            dependencies: [
                "LLMMacrosImplementation",
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/LLMMacros"
        ),
        .target(
            name: "LLM",
            dependencies: ["llama", "LLMMacros"],
            path: "Sources/LLM"
        ),
        .testTarget(
            name: "LLMTests",
            dependencies: [
                "LLM",
                "LLMMacros"
            ],
            path: "Tests/LLMTests"
        )
    ]
)
