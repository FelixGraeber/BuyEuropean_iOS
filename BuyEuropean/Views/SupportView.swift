import SwiftUI
import StoreKit
import Foundation // For NSLocalizedString

/// Returns a descriptive string for a given product based on ID and subscription type.
func getProductDescription(for product: Product?, isSubscription: Bool) -> String {
    guard let product = product else { return "" }
    let keyPrefix = isSubscription ? "support.description.sub." : "support.description.onetime."
    let defaultKey = isSubscription ? "support.description.sub.default" : "support.description.onetime.default"

    // Simplified mapping; assumes product IDs align with a pattern or specific values
    // This might need adjustment if IDs are arbitrary.
    let durationKey: String
    switch product.id {
    case let id where id.contains("0.99"): durationKey = "few_hours"
    case let id where id.contains("4.99"): durationKey = "day"
    case let id where id.contains("9.99"): durationKey = "few_days"
    case let id where id.contains("29.99"): durationKey = "week"
    case let id where id.contains("99.99"): durationKey = "few_weeks"
    default: return NSLocalizedString(defaultKey, comment: "Default product description")
    }
    
    return NSLocalizedString(keyPrefix + durationKey, comment: "Product description for \(product.id)")
}

struct SupportView: View {
    @EnvironmentObject private var iapManager: IAPManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // MARK: Tabs
    enum Tab: Int, CaseIterable, Identifiable {
        case support, feedback
        var id: Int { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .support: return "support.tab.support"
            case .feedback: return "support.tab.feedback"
            }
        }
    }

    @State private var selectedTab: Tab = .support
    @State private var isSubscription: Bool = false
    @State private var selectedOneTimeIndex: Int? = nil
    @State private var selectedSubIndex: Int? = nil

    // Share content
    private let appStoreLink = "https://apps.apple.com/de/app/buyeuropean/id6743128862?l=en-GB"
    private var shareText: String {
        let shareLine1 = NSLocalizedString("share.text.line1", comment: "Share text line 1")
        let shareLine2 = NSLocalizedString("share.text.line2", comment: "Share text line 2")
        return "\(shareLine1)\n\(shareLine2)\n\(appStoreLink)"
    }

    // MARK: Product Lists
    private var oneTimeProducts: [Product] {
        iapManager.products
            .filter { $0.id.contains("onetime_") || $0.id.contains("support_buyeuropean") }
            .sorted { $0.price < $1.price }
    }
    private var monthlyProducts: [Product] {
        iapManager.products
            .filter { $0.id.contains("longterm_") }
            .sorted { $0.price < $1.price }
    }
    private var currentProducts: [Product] {
        isSubscription ? monthlyProducts : oneTimeProducts
    }
    private var selectedProduct: Product? {
        let idx = isSubscription ? selectedSubIndex : selectedOneTimeIndex
        guard let i = idx, currentProducts.indices.contains(i) else { return nil }
        return currentProducts[i]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                List {
                    Section {
                        Picker(selection: $selectedTab, label: EmptyView()) {
                            ForEach(Tab.allCases) { tab in
                        Text(tab.title).tag(tab) // Text can take LocalizedStringKey
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 5)
                    }
                    .listRowBackground(Color(.secondarySystemGroupedBackground))

                    if selectedTab == .support {
                        shareSection
                        donateSection
                    }
                    
                    if selectedTab == .feedback {
                        feedbackSection
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
        .navigationTitle(LocalizedStringKey("support.title"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                Button(LocalizedStringKey("common.close")) { dismiss() }
                    }
                }
                .refreshable { await iapManager.fetchProducts() }
                .task { initializeSelection() }
            }
        }
    }

    private var shareSection: some View {
        Section(header: Text(LocalizedStringKey("support.share.header")).headerProminence(.increased)) {
            // Use iOS 16's ShareLink instead of ActivityView
            ShareLink(item: shareText) {
                HStack {
                    Label {
                         VStack(alignment: .leading, spacing: 4) {
                             Text(LocalizedStringKey("support.share.button.label")).font(.headline)
                             Text(LocalizedStringKey("support.share.button.description"))
                                 .font(.subheadline).foregroundColor(.secondary)
                         }
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                            .imageScale(.large)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.accentColor)

                    }
                    Spacer()
                    Image(systemName: "chevron.forward").foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
         .listRowBackground(Color(.secondarySystemGroupedBackground))
    }

    private var donateSection: some View {
        Section(header: Text(LocalizedStringKey("support.donate.header")).headerProminence(.increased)) {
            Text(LocalizedStringKey("support.donate.description"))
                .font(.subheadline).foregroundColor(.secondary).padding(.bottom, 8)

            if iapManager.isFetchingProducts {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical)
            } else if currentProducts.isEmpty {
                Text(LocalizedStringKey("support.donate.load_error"))
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 85), spacing: 12)], spacing: 12) {
                    ForEach(currentProducts.indices, id: \.self) { idx in
                        let prod = currentProducts[idx]
                        let isSel = (isSubscription ? selectedSubIndex : selectedOneTimeIndex) == idx
                        Button {
                             if isSubscription {
                                selectedSubIndex = idx
                            } else {
                                selectedOneTimeIndex = idx
                            }
                        } label: {
                            Text(prod.displayPrice)
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .padding(.horizontal, 4)
                                .foregroundColor(isSel ? .white : .accentColor)
                                .background(isSel ? Color.accentColor : Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.accentColor, lineWidth: isSel ? 0 : 1.5))
                                .shadow(color: isSel ? .accentColor.opacity(0.3) : .clear, radius: 4, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 4)
                .animation(.easeInOut(duration: 0.2), value: isSubscription ? selectedSubIndex : selectedOneTimeIndex)

                if let prod = selectedProduct {
                     HStack {
                         Spacer()
                         Text(getProductDescription(for: prod, isSubscription: isSubscription))
                             .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                         Spacer()
                     }
                    .padding(.vertical, 4)
                } else {
                    Text(LocalizedStringKey("support.donate.select_amount"))
                        .font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                }

                Toggle(LocalizedStringKey("support.donate.toggle.monthly"), isOn: $isSubscription)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    .padding(.vertical, 8)
                    .onChange(of: isSubscription) { newValue in
                        let priceToMatch: Decimal

                        guard !oneTimeProducts.isEmpty, !monthlyProducts.isEmpty else { return }

                        if newValue {
                            let currentOneTimeIdx = selectedOneTimeIndex ?? 0
                            guard oneTimeProducts.indices.contains(currentOneTimeIdx) else { return }
                            priceToMatch = oneTimeProducts[currentOneTimeIdx].price
                            selectedSubIndex = findClosestPriceIndex(price: priceToMatch, in: monthlyProducts)

                        } else {
                            let currentSubIdx = selectedSubIndex ?? 0
                            guard monthlyProducts.indices.contains(currentSubIdx) else { return }
                            priceToMatch = monthlyProducts[currentSubIdx].price
                            selectedOneTimeIndex = findClosestPriceIndex(price: priceToMatch, in: oneTimeProducts)
                        }
                    }

                Button { purchaseSelectedProduct() } label: {
                    HStack {
                        Spacer()
                        if iapManager.isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSubscription ? LocalizedStringKey("support.donate.button.subscribe") : LocalizedStringKey("support.donate.button.donate"))
                        }
                        Spacer()
                    }
                    .frame(height: 30)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(selectedProduct == nil || iapManager.isPurchasing)
                .padding(.top, 8)
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color(.secondarySystemGroupedBackground))
    }

    private var feedbackSection: some View {
        Section(header: Text(LocalizedStringKey("support.feedback.header")).headerProminence(.increased)) {
            Button {
                if let emailURL = URL(string: "mailto:contact@buyeuropean.io") {
                    openURL(emailURL)
                    FeedbackViewModel().promptForRatingIfNeeded()
                }
            } label: {
                 HStack {
                     Label("contact@buyeuropean.io", systemImage: "envelope") // Email not localized
                         .foregroundStyle(.tint)
                     Spacer()
                     Image(systemName: "chevron.forward").foregroundColor(.secondary)
                 }
                 .padding(.vertical, 6)
            }
        }
         .listRowBackground(Color(.secondarySystemGroupedBackground))
    }

    private func findClosestPriceIndex(price: Decimal, in products: [Product]) -> Int {
        guard !products.isEmpty else { return 0 }

        let closest = products.enumerated().min(by: { abs($0.element.price - price) < abs($1.element.price - price) })

        return closest?.offset ?? 0
    }
    
    private func initializeSelection() {
        if selectedOneTimeIndex == nil, !oneTimeProducts.isEmpty {
            selectedOneTimeIndex = oneTimeProducts.firstIndex(where: { $0.id == "onetime_4.99" }) ?? 0
        }
    }

    private func purchaseSelectedProduct() {
        guard let prod = selectedProduct else { return }
        Task {
            try? await iapManager.purchase(prod)
        }
    }
}

#if DEBUG
struct SupportView_Previews: PreviewProvider {
    static let iapManager: IAPManager = {
        let manager = IAPManager(entitlementManager: EntitlementManager())
        return manager
    }()

    static var previews: some View {
        SupportView()
            .environmentObject(iapManager)
    }
}
#endif 