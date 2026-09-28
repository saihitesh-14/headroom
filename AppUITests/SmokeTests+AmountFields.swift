import XCTest

/// Amount fields as VoiceOver hears them, and the what-if price error on Result.
///
/// An extension of SmokeTests rather than a class of its own: build/ui-shots.sh stops at the
/// first finished test class, so every UI test lives in this one class.
extension SmokeTests {
    @MainActor
    func testAmountFieldsSayTheirNameOnce() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestSamplePlan", "-\(onDeviceAIKey)", "NO"]
        app.launch()

        XCTAssertTrue(app.staticTexts["spendingRoom"].waitForExistence(timeout: 10))
        let question = app.descendants(matching: .any)["question"]
        question.tap()
        question.typeText("Can I buy a $700 laptop next Friday?")
        app.buttons["check"].tap()

        // The labeled field on Confirm details: its row names it once. At accessibility sizes
        // the row starts below the medium detent, where the form has not built it yet.
        XCTAssertTrue(app.buttons["confirmCheck"].waitForExistence(timeout: 5))
        let price = app.textFields["price"]
        for _ in 0..<3 where !price.waitForExistence(timeout: 2) {
            app.collectionViews.firstMatch.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(price.waitForExistence(timeout: 5))
        XCTAssertEqual(price.label, "Price")
        app.buttons["confirmCheck"].tap()

        // The compact field in the what-if bar.
        XCTAssertTrue(app.descendants(matching: .any)["verdict"].waitForExistence(timeout: 5))
        let whatIf = app.textFields["Price"]
        XCTAssertTrue(whatIf.waitForExistence(timeout: 5))
        XCTAssertEqual(whatIf.label, "Price")

        // A price that is not an amount keeps the last one analyzed and says so under the bar.
        whatIf.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        whatIf.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6) + "0")
        let error = app.descendants(matching: .any)["Enter a price, like 700 or 49.99."]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "6-price-error"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
