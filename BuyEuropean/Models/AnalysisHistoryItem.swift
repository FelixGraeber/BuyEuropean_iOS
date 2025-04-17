import Foundation

struct AnalysisHistoryItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let response: BuyEuropeanResponse
}
