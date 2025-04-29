import SwiftUI
import StoreKit
import MessageUI

/// Returns a descriptive string for a given product based on ID and subscription type.
func getProductDescription(for product: Product?, isSubscription: Bool) -> String {
    guard let product = product else { return "" }
    if isSubscription {
        switch product.id {
        case let id where id.contains("0.99"): return "Fund BuyEuropean for a few hours each month"
        case let id where id.contains("4.99"): return "Fund BuyEuropean for a day each month"
        case let id where id.contains("9.99"): return "Fund BuyEuropean for a few days each month"
        case let id where id.contains("29.99"): return "Fund BuyEuropean for a week each month"
        case let id where id.contains("99.99"): return "Fund BuyEuropean for a few weeks each month"
        default: return "Support BuyEuropean monthly"
        }
    } else {
        switch product.id {
        case let id where id.contains("support_buyeuropean"): return "Support BuyEuropean with a small donation"
        case let id where id.contains("0.99"): return "Fund BuyEuropean for a few hours"
        case let id where id.contains("4.99"): return "Fund BuyEuropean for a day"
        case let id where id.contains("9.99"): return "Fund BuyEuropean for a few days"
        case let id where id.contains("29.99"): return "Fund BuyEuropean for a week"
        case let id where id.contains("99.99"): return "Fund BuyEuropean for a few weeks"
        default: return "Support BuyEuropean"
        }
    }
}

struct SupportView: View {
    @EnvironmentObject private var iapManager: IAPManager
    @Environment(\.dismiss) private var dismiss

    // MARK: Tabs
    enum Tab: Int, CaseIterable, Identifiable {
        case support, feedback
        var id: Int { rawValue }
        var title: String { self == .support ? "Support" : "Feedback" }
    }

    @State private var selectedTab: Tab = .support
    @State private var isSubscription: Bool = false
    @State private var selectedOneTimeIndex: Int? = nil
    @State private var selectedSubIndex: Int? = nil
    @State private var showShareSheet = false
    @State private var showMailCompose = false

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
            List {
                // MARK: Tab Picker
                Section {
                    Picker(selection: $selectedTab, label: EmptyView()) {
                        ForEach(Tab.allCases) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: Support Tab
                if selectedTab == .support {
                    shareSection
                    donateSection
                }
                
                // MARK: Feedback Tab
                if selectedTab == .feedback {
                    feedbackSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Support Us")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .refreshable { await iapManager.fetchProducts() }
            // Share Sheet
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: ["Check out BuyEuropean: https://BuyEuropean.io"])            }
            // Mail Compose
            .sheet(isPresented: $showMailCompose) {
                MailComposeView(recipient: "contact@buyeuropean.io") { result in
                    if case .sent = result {
                        FeedbackViewModel().promptForRatingIfNeeded()
                    }
                }
            }
            .task { initializeSelection() }
        }
    }

    // MARK: Share Section
    private var shareSection: some View {
        Section(header: Text("Share BuyEuropean")) {
            Button { showShareSheet = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.accentColor)
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share BuyEuropean").font(.headline)
                        Text("Help us grow the BuyEuropean movement by sharing the app.")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.forward").foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: Donate Section
    private var donateSection: some View {
        Section(header: Text("Donate to Support")) {
            Text("Keep BuyEuropean free and ad-free, choose how you'd like to support:")
                .font(.subheadline).foregroundColor(.secondary).padding(.vertical, 4)

            if iapManager.isFetchingProducts {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if currentProducts.isEmpty {
                Text("Unable to load support options—pull down to retry.")
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 4)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
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
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(isSel ? Color.accentColor : Color.clear)
                                .foregroundColor(isSel ? .white : .accentColor)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.accentColor, lineWidth: 1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to prevent default button behavior
                    }
                }
                .padding(.vertical, 4)

                if let prod = selectedProduct {
                    Text(getProductDescription(for: prod, isSubscription: isSubscription))
                        .font(.caption).foregroundColor(.secondary).padding(.vertical, 4)
                }

                Toggle("Monthly Support", isOn: $isSubscription)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    .padding(.vertical, 4)
                    .onChange(of: isSubscription) { newValue in
                        let priceToMatch: Decimal
                        
                        if newValue {
                            // Switching TO subscription mode
                            // Get current one-time price to match
                            if let index = selectedOneTimeIndex, oneTimeProducts.indices.contains(index) {
                                priceToMatch = oneTimeProducts[index].price
                                
                                // Find closest price match in subscription products
                                selectedSubIndex = findClosestPriceIndex(price: priceToMatch, in: monthlyProducts)
                            }
                        } else {
                            // Switching TO one-time mode
                            // Get current subscription price to match
                            if let index = selectedSubIndex, monthlyProducts.indices.contains(index) {
                                priceToMatch = monthlyProducts[index].price
                                
                                // Find closest price match in one-time products
                                selectedOneTimeIndex = findClosestPriceIndex(price: priceToMatch, in: oneTimeProducts)
                            }
                        }
                    }

                Button { purchaseSelectedProduct() } label: {
                    Text(isSubscription ? "Subscribe" : "Donate")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(selectedProduct == nil || iapManager.isPurchasing)
            }
        }
    }

    // MARK: Feedback Section
    private var feedbackSection: some View {
        Section(header: Text("Send Feedback")) {
            Button { showMailCompose = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundColor(.accentColor)
                        .frame(width: 24, height: 24)
                    Text("contact@buyeuropean.io").foregroundColor(.accentColor)
                    Spacer()
                    Image(systemName: "chevron.forward").foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: Helpers
    
    /// Find the index of the product with the closest price to the given price
    private func findClosestPriceIndex(price: Decimal, in products: [Product]) -> Int {
        // Try exact match first (within 1 cent)
        if let exactIndex = products.firstIndex(where: { abs($0.price - price) < 0.01 }) {
            return exactIndex
        }
        
        // Try approximate match (within $1)
        if let approxIndex = products.firstIndex(where: { abs($0.price - price) < 1.0 }) {
            return approxIndex
        }
        
        // Try to find a $4.99 product as fallback
        if let defaultIndex = products.firstIndex(where: { $0.displayPrice.contains("4.99") }) {
            return defaultIndex
        }
        
        // Last resort: first product in the list
        return 0
    }
    
    private func initializeSelection() {
        if selectedOneTimeIndex == nil, !oneTimeProducts.isEmpty {
            // Try to find the $4.99 product, or default to the first product
            selectedOneTimeIndex = oneTimeProducts.firstIndex(where: { $0.displayPrice.contains("4.99") }) ?? 0
        }
        if selectedSubIndex == nil, !monthlyProducts.isEmpty {
            // Try to find the $4.99 product, or default to the first product 
            selectedSubIndex = monthlyProducts.firstIndex(where: { $0.displayPrice.contains("4.99") }) ?? 0
        }
    }

    private func purchaseSelectedProduct() {
        guard let prod = selectedProduct else { return }
        Task {
            try? await iapManager.purchase(prod)
        }
    }
}

// MARK: ActivityView Wrapper
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if let pop = controller.popoverPresentationController {
            pop.sourceView = UIApplication.shared.windows.first
            pop.sourceRect = CGRect(x: UIScreen.main.bounds.midX,
                                     y: UIScreen.main.bounds.midY,
                                     width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: MailComposeView Wrapper
struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    var onResult: ((MFMailComposeResult) -> Void)?
    @Environment(\.dismiss) private var dismiss

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        init(_ parent: MailComposeView) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            parent.onResult?(result)
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.mailComposeDelegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
} 