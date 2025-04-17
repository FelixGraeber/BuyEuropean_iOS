import SwiftUI

struct HistoryView: View {
    @ObservedObject private var historyService = HistoryService.shared
    @State private var searchText = ""
    let onSelect: (AnalysisHistoryItem) -> Void

    private var filtered: [AnalysisHistoryItem] {
        if searchText.isEmpty {
            return historyService.history
        }
        let q = searchText.lowercased()
        return historyService.history.filter {
            let resp = $0.response
            return resp.identifiedProductName.lowercased().contains(q)
                || (resp.identifiedCompany?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        List(filtered) { item in
            Button {
                onSelect(item)
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.response.identifiedCompany ?? "N/A")
                            .font(.headline)
                        Text(item.response.identifiedProductName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    ClassificationBadgeView(
                        style: ClassificationStyle.forClassification(item.response.classification),
                        font: .caption2
                    )
                    .frame(height: 14)
                    .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
        .searchable(text: $searchText, prompt: "Search history")
    }
}
