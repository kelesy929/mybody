# MyBody

iPhone 原生健身记录 App（SwiftUI + SwiftData，iOS 17+，零三方库）。
记录每组动作的重量/次数 → 训练后科学评估「今天练够了吗」→ 推荐明日训练 → 内置动作指导库。

## 工程结构

```
MyBody/                 # iOS App（SwiftUI + SwiftData）
  App/                  # @main 入口、ModelContainer、首次播种
  Models/               # SwiftData @Model（Exercise / WorkoutSession / …）
  DesignSystem/         # 设计 token（草绿 #82B43C 主题）与通用组件
  Features/             # 各界面 View + @Observable ViewModel
  Data/                 # 内置动作种子数据
MyBodyCore/             # 纯逻辑 Swift Package（评估/推荐/容量）——可在 Windows 上单测
  Sources/MyBodyCore/
  Tests/MyBodyCoreTests/
project.yml             # XcodeGen 配置（macOS 侧据此生成 .xcodeproj）
.github/workflows/      # CI：Linux 跑逻辑单测 + macOS 编译 App
```

## 在 Windows 上开发

- 写代码、跑算法单测全程只用 Windows，无需 Mac。
- 算法层 `MyBodyCore` 是平台无关的 SwiftPM 包：装 [Swift for Windows](https://www.swift.org/install/windows/) 后，
  ```
  cd MyBodyCore
  swift test
  ```
  即可验证评估/推荐/容量逻辑。
- SwiftUI 界面与 SwiftData 持久化那层必须由 **macOS 上的 Xcode** 编译——见下。

## 出包装到 iPhone（Windows → GitHub → TestFlight）

1. 代码推到 GitHub。
2. `.github/workflows/ci.yml` 自动在 **Linux** 跑逻辑单测、在 **macOS runner** 用真 Xcode 编译（公开仓库免费）。
3. 要装进手机：开一个 **Apple Developer 账号（$99/年）**，在 App Store Connect 生成 API Key，
   存进 GitHub Secrets，加一个打 tag 触发的 release 工作流（fastlane → TestFlight）。
4. iPhone 上用 TestFlight 安装，像正常 App 一样用。

本人全程只用 Windows，Mac 完全在云端（GitHub Actions）。

## 生成并运行（在 macOS 上）

```
brew install xcodegen
xcodegen generate
open MyBody.xcodeproj
```
