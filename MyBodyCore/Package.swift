// swift-tools-version: 5.9
import PackageDescription

// 注意：这里【故意不声明 platforms】。MyBodyCore 只含纯逻辑（评估/推荐/容量），
// 不依赖 UIKit / SwiftUI / SwiftData，因此能在 Windows / Linux 上直接 `swift test`，
// 无需 Mac。iOS 平台与最低版本由 App 工程（XcodeGen 的 project.yml）声明。
let package = Package(
    name: "MyBodyCore",
    products: [
        .library(name: "MyBodyCore", targets: ["MyBodyCore"]),
    ],
    targets: [
        .target(name: "MyBodyCore"),
        .testTarget(name: "MyBodyCoreTests", dependencies: ["MyBodyCore"]),
    ]
)
