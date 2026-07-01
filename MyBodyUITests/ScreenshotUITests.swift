import XCTest

/// 截图巡游：启动 App，点着走一遍各屏，每屏截一张图（作为 XCTAttachment，keepAlways）。
/// CI 里用 xcparse 从 .xcresult 抽出 PNG 上传 artifact。
/// 全程用存在性判断守卫，任何一步找不到元素都不让测试失败——尽量多截、不红。
final class ScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testCaptureAllScreens() throws {
        let app = XCUIApplication()
        app.launch()

        // 01 今日
        snap(app, "01-Today")

        // 进入训练记录
        let start = app.buttons["start_workout"]
        if start.waitForExistence(timeout: 8) {
            start.tap()
            snap(app, "02-Workout")

            // 勾一组 → 触发组间休息条
            let done = app.buttons.matching(identifier: "set_done").firstMatch
            if done.waitForExistence(timeout: 4) {
                done.tap()
                sleep(1)
                snap(app, "03-Workout-Rest")
            }

            // 完成训练 → 评估
            let finish = app.buttons["finish_workout"]
            if finish.waitForExistence(timeout: 4) {
                finish.tap()
                snap(app, "04-Evaluation")

                // 查看明日
                let tomorrow = app.buttons["go_tomorrow"]
                if tomorrow.waitForExistence(timeout: 4) {
                    tomorrow.tap()
                    sleep(1)
                    snap(app, "05-Tomorrow")
                }
            }
        }

        // 动作库（tab 常驻，可随时切）
        let libTab = app.tabBars.buttons["动作库"]
        if libTab.waitForExistence(timeout: 4) {
            libTab.tap()
            sleep(1)
            snap(app, "06-Library")

            // 打开第一个动作详情
            let firstRow = app.buttons.matching(identifier: "lib_row").firstMatch
            if firstRow.waitForExistence(timeout: 4) {
                firstRow.tap()
                sleep(1)
                snap(app, "07-Detail")
            }
        }

        // 数据
        let statsTab = app.tabBars.buttons["数据"]
        if statsTab.waitForExistence(timeout: 4) {
            statsTab.tap()
            sleep(1)
            snap(app, "08-Stats")
        }
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let shot = app.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }
}
