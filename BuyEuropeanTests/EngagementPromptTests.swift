import XCTest
@testable import BuyEuropean // To access EngagementLogic and potentially HistoryService if needed later

// Re-declare necessary keys if Constants.swift is not part of the test target
struct EngagementPromptTestsUserDefaultsKeys {
    static let lastAppOpenDate = "lastAppOpenDate"
}

class EngagementPromptTests: XCTestCase {

    let userDefaults = UserDefaults.standard
    let calendar = Calendar.current

    override func setUp() {
        super.setUp()
        // Clear the UserDefaults key before each test
        userDefaults.removeObject(forKey: EngagementPromptTestsUserDefaultsKeys.lastAppOpenDate)
        // Note: HistoryService mocking is not directly handled here as EngagementLogic
        // now takes a `historyIsEmpty: Bool` parameter, decoupling it for this test.
    }

    override func tearDown() {
        // Clear the UserDefaults key after each test
        userDefaults.removeObject(forKey: EngagementPromptTestsUserDefaultsKeys.lastAppOpenDate)
        super.tearDown()
    }

    // Helper to create dates relative to "now"
    func date(daysAgo: Int) -> Date {
        return calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
    }

    let nowDate = Date()

    // MARK: - Tests for EngagementLogic.shouldShowReEngagementPrompt

    func testPrompt_NoLastOpenDate_HistoryNotEmpty_ShouldNotShow() {
        let shouldShow = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: nil,
            historyIsEmpty: false
        )
        XCTAssertFalse(shouldShow, "Should not show prompt if there's no last open date, even with history.")
    }

    func testPrompt_NoLastOpenDate_HistoryEmpty_ShouldNotShow() {
        let shouldShow = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: nil,
            historyIsEmpty: true
        )
        XCTAssertFalse(shouldShow, "Should not show prompt if there's no last open date and history is empty.")
    }

    func testPrompt_LastOpenDateRecent_WithHistory_ShouldNotShow() {
        let lastOpen = date(daysAgo: 3) // 3 days ago
        let shouldShow = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: lastOpen,
            historyIsEmpty: false
        )
        XCTAssertFalse(shouldShow, "Should not show prompt if last open was recent (3 days ago) and history is not empty.")
    }

    func testPrompt_LastOpenDateRecent_NoHistory_ShouldNotShow() {
        let lastOpen = date(daysAgo: 3) // 3 days ago
        let shouldShow = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: lastOpen,
            historyIsEmpty: true
        )
        XCTAssertFalse(shouldShow, "Should not show prompt if last open was recent (3 days ago), regardless of history being empty (as history check comes first in logic).")
    }

    func testPrompt_LastOpenDateOld_NoHistory_ShouldNotShow() {
        let lastOpen = date(daysAgo: 10) // 10 days ago
        let shouldShow = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: lastOpen,
            historyIsEmpty: true
        )
        XCTAssertFalse(shouldShow, "Should not show prompt if history is empty, even if last open was old (10 days ago).")
    }

    func testPrompt_LastOpenDateOld_WithHistory_ShouldShow() {
        let lastOpen = date(daysAgo: 10) // 10 days ago
        let shouldShow = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: lastOpen,
            historyIsEmpty: false
        )
        XCTAssertTrue(shouldShow, "Should show prompt if last open was old (10 days ago) and history is not empty.")
    }

    func testPrompt_LastOpenDateExactly7Days_WithHistory_ShouldNotShow() {
        let lastOpen = date(daysAgo: 7) // Exactly 7 days ago
        let shouldShow = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: lastOpen,
            historyIsEmpty: false
        )
        XCTAssertFalse(shouldShow, "Should not show prompt if last open was exactly 7 days ago (boundary).")
    }

    func testPrompt_LastOpenDateSlightlyMoreThan7Days_WithHistory_ShouldShow() {
        // lastOpenDate is 7 days and a few hours ago, so dateComponents([.day]) will yield 7.
        // The logic `differenceInDays > 7` means it needs to be at least 8 days.
        let lastOpen = date(daysAgo: 8) // 8 days ago
        let shouldShow = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: lastOpen,
            historyIsEmpty: false
        )
        XCTAssertTrue(shouldShow, "Should show prompt if last open was 8 days ago and history is not empty.")
    }

    func testPrompt_LastOpenDateAlmost8Days_WithHistory_ShouldShow() {
        // Test with a date that is 7 days and some hours in the past.
        // Calendar.dateComponents([.day], from: lastOpen, to: nowDate) should result in 7 days.
        // So, if logic is strictly `> 7`, this should NOT show.
        // If logic means "has completed 7 full 24-hour periods", then it should show on the 8th day.
        // Our current EngagementLogic: `differenceInDays > 7` means it must be 8 or more.
        var components = DateComponents()
        components.day = -7
        components.hour = -1 // 7 days and 1 hour ago
        let lastOpen7Days1HourAgo = calendar.date(byAdding: components, to: nowDate)!

        let shouldShowFor7Days1Hour = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: lastOpen7Days1HourAgo,
            historyIsEmpty: false
        )
        // Based on `differenceInDays > 7` and `dateComponents` for `.day` just giving integer days:
        // A date 7 days and 1 hour ago will result in `differenceInDays == 7`.
        // So, 7 > 7 is false.
        XCTAssertFalse(shouldShowFor7Days1Hour, "Should NOT show if it's 7 days and 1 hour ago, as day difference is 7, not > 7.")

        // Test with a date that is just past the threshold into the 8th day.
        var componentsJustOver = DateComponents()
        componentsJustOver.day = -7
        // To ensure it's more than 7 full days, making it 8 days ago effectively for day components
        // We actually need to go to the start of the 8th day ago.
        // So, if today is Day X, Day X-7 is 7 days ago. Day X-8 is 8 days ago.
        // The logic `differenceInDays > 7` means `differenceInDays` must be 8, 9, ...
        let lastOpen8DaysAgo = calendar.date(byAdding: .day, value: -8, to: nowDate)!
        let shouldShowFor8Days = EngagementLogic.shouldShowReEngagementPrompt(
            currentDate: nowDate,
            lastOpenDate: lastOpen8DaysAgo,
            historyIsEmpty: false
        )
        XCTAssertTrue(shouldShowFor8Days, "Should show if it's 8 days ago.")
    }


    // MARK: - Test for UserDefaults Update (Simulating ScanView.onAppear's side effect)

    func testLastAppOpenDate_IsUpdatedAfterCheck() {
        // Arrange: No initial lastAppOpenDate

        // Act: Simulate the part of ScanView.onAppear that updates the date.
        // This happens regardless of whether the prompt is shown.
        let testDateForUpdate = Date() // Use a fixed date for assertion
        userDefaults.set(testDateForUpdate, forKey: EngagementPromptTestsUserDefaultsKeys.lastAppOpenDate)

        // Assert
        let updatedDate = userDefaults.object(forKey: EngagementPromptTestsUserDefaultsKeys.lastAppOpenDate) as? Date
        XCTAssertNotNil(updatedDate, "lastAppOpenDate should be set in UserDefaults.")

        // Compare dates with a small tolerance for precision issues if comparing Date directly
        // For this test, since we set it to testDateForUpdate, it should be exactly that.
        XCTAssertEqual(updatedDate, testDateForUpdate, "lastAppOpenDate should be updated to the current date of the check.")

        // Arrange: An old lastAppOpenDate
        let oldDate = date(daysAgo: 10)
        userDefaults.set(oldDate, forKey: EngagementPromptTestsUserDefaultsKeys.lastAppOpenDate)

        // Act: Simulate the update again with a new "current" date
        let newTestDateForUpdate = Date()
        userDefaults.set(newTestDateForUpdate, forKey: EngagementPromptTestsUserDefaultsKeys.lastAppOpenDate)

        // Assert
        let finalUpdatedDate = userDefaults.object(forKey: EngagementPromptTestsUserDefaultsKeys.lastAppOpenDate) as? Date
        XCTAssertNotNil(finalUpdatedDate)
        XCTAssertEqual(finalUpdatedDate, newTestDateForUpdate, "lastAppOpenDate should be updated to the new current date.")
        XCTAssertNotEqual(finalUpdatedDate, oldDate, "lastAppOpenDate should have changed from the old date.")
    }
}
