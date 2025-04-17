import Foundation
import Combine

@MainActor
class HistoryService: ObservableObject {
    static let shared = HistoryService()
    @Published private(set) var history: [AnalysisHistoryItem] = []

    private let key = "AnalysisHistory"
    private let userDefaults = UserDefaults.standard

    private init() {
        loadHistory()
    }

    private func loadHistory() {
        guard let data = userDefaults.data(forKey: key) else { return }
        do {
            history = try JSONDecoder().decode([AnalysisHistoryItem].self, from: data)
        } catch {
            history = []
            print("[HistoryService] Failed to load history: \(error)")
        }
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            userDefaults.set(data, forKey: key)
        } catch {
            print("[HistoryService] Failed to save history: \(error)")
        }
    }

    func add(response: BuyEuropeanResponse) {
        let item = AnalysisHistoryItem(id: UUID(), timestamp: Date(), response: response)
        history.insert(item, at: 0)
        saveHistory()
    }

    func clear() {
        history.removeAll()
        userDefaults.removeObject(forKey: key)
    }
}
