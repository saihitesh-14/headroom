import XCTest

/// End-to-end: sample plan → ask → confirm → result. Also saves screenshots for the README.
final class SmokeTests: XCTestCase {
    /// Matches OnDeviceAI.settingKey; UI tests use the deterministic built-in parser.
    let onDeviceAIKey = "useOnDeviceAI"

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAskAboutALaptopShowsAVerdict() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSamplePlan", "-\(onDeviceAIKey)", "NO"]
        app.launch()

        XCTAssertTrue(app.staticTexts["spendingRoom"].waitForExistence(timeout: 10))
        snapshot(app, "1-ask")

        let question = app.descendants(matching: .any)["question"]
        question.tap()
        question.typeText("Can I buy a $700 laptop next Friday?")
        app.buttons["check"].tap()

        let confirm = app.buttons["confirmCheck"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        snapshot(app, "2-confirm")
        confirm.tap()

        XCTAssertTrue(app.descendants(matching: .any)["verdict"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["chartSummary"].exists || app.otherElements["chart"].exists)
        snapshot(app, "3-result")

        app.scrollViews.firstMatch.swipeUp(velocity: .slow)
        snapshot(app, "4-result-details")

        app.tabBars.buttons["Plan"].tap()
        snapshot(app, "5-plan")
    }

    @MainActor
    func testFirstLaunchShowsTheEmptyState() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestEmptyPlan"]
        app.launch()
        XCTAssertTrue(app.buttons["Try the sample plan"].waitForExistence(timeout: 10))
        snapshot(app, "0-empty")
    }

    @MainActor
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
