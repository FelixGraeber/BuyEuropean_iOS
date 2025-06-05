import Foundation

struct EngagementLogic {
    /// Determines whether the re-engagement prompt should be shown based on the last app open date and history content.
    /// - Parameters:
    ///   - currentDate: The current date.
    ///   - lastOpenDate: The date when the app was last opened. If nil (e.g., first open), prompt should not show.
    ///   - historyIsEmpty: A boolean indicating whether the user's scan history is empty.
    /// - Returns: `true` if the prompt should be shown, `false` otherwise.
    static func shouldShowReEngagementPrompt(
        currentDate: Date,
        lastOpenDate: Date?,
        historyIsEmpty: Bool
    ) -> Bool {
        guard let lastKnownOpenDate = lastOpenDate else {
            return false // Never show on first open (where lastOpenDate is nil)
        }

        // If history is empty, never show the prompt
        if historyIsEmpty {
            return false
        }

        let calendar = Calendar.current
        // Calculate the date 7 days ago from the current date.
        // We want to show the prompt if lastKnownOpenDate is *before* (older than) 7 days ago.
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: currentDate) else {
            return false // Should not happen
        }

        // Compare if lastKnownOpenDate is earlier than sevenDaysAgo (i.e., more than 7 days have passed).
        // To be precise, if lastKnownOpenDate is on day 1 and currentDate is day 8, difference is 7 days.
        // We want to show if difference is > 7 days.
        // So, if lastKnownOpenDate is day 1, sevenDaysAgo is day 1 (from day 8). Prompt should not show.
        // If lastKnownOpenDate is day 0, sevenDaysAgo is day 1. Prompt should show.
        // This means lastKnownOpenDate must be strictly earlier than the start of the day 7 days ago.
        // For example, if it's "more than 7 days", it means 8 days or more.
        // If last open was 7 days and 1 second ago, it should show.

        let differenceInDays = calendar.dateComponents([.day], from: lastKnownOpenDate, to: currentDate).day ?? 0

        return differenceInDays > 7
    }
}
