import UIKit

/// 轻量触觉反馈封装（规格：完成一组时轻触反馈）。
enum Haptics {
    /// 完成一组：成功反馈。
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    /// 轻触（步进等）。
    static func light() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
}
