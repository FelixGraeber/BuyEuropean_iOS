import SwiftUI
import StoreKit
import MessageUI

/// Returns a descriptive string for a given product based on ID and subscription type.
func getProductDescription(for product: Product?, isSubscription: Bool) -> String {
    guard let product = product else { return "" }
    if isSubscription {
        switch product.id {
        case "longterm_0.99": return "Fund BuyEuropean for a few hours each month"
        case "longterm_4.99": return "Fund BuyEuropean for a day each month"
        case "longterm_9.99": return "Fund BuyEuropean for a few days each month"
        case "longterm_29.99": return "Fund BuyEuropean for a week each month"
        case "longterm_99.99": return "Fund BuyEuropean for a few weeks each month"
        default: return "Support BuyEuropean monthly"
        }
    } else {
        switch product.id {
        case "support_buyeuropean_0.99": return "Fund BuyEuropean for a few hours"
        case "onetime_4.99": return "Fund BuyEuropean for a day"
        case "onetime_9.99": return "Fund BuyEuropean for a few days"
        case "onetime_29.99": return "Fund BuyEuropean for a week"
        case "onetime_99.99": return "Fund BuyEuropean for a few weeks"
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
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                List {
                    Section {
                        Picker(selection: $selectedTab, label: EmptyView()) {
                            ForEach(Tab.allCases) { tab in
                                Text(tab.title).tag(tab)
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
                .navigationTitle("Support Us")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") { dismiss() }
                    }
                }
                .refreshable { await iapManager.fetchProducts() }
                .sheet(isPresented: $showShareSheet) {
                    ActivityView(activityItems: ["Check out BuyEuropean and Vote with your Money: https://BuyEuropean.io"])
                }
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
    }

    private var shareSection: some View {
        Section(header: Text("Share BuyEuropean").headerProminence(.increased)) {
            Button { showShareSheet = true } label: {
                HStack {
                    Label {
                         VStack(alignment: .leading, spacing: 4) {
                             Text("Share BuyEuropean").font(.headline)
                             Text("Help us grow the BuyEuropean movement by sharing the app.")
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
        Section(header: Text("Donate to Support").headerProminence(.increased)) {
            Text("Keep BuyEuropean free and ad-free. Choose how you'd like to support:")
                .font(.subheadline).foregroundColor(.secondary).padding(.bottom, 8)

            if iapManager.isFetchingProducts {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical)
            } else if currentProducts.isEmpty {
                Text("Unable to load support options—pull down to retry.")
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
                    Text("Select an amount above")
                        .font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                }

                Toggle("Monthly Support", isOn: $isSubscription)
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
                            Text(isSubscription ? "Subscribe" : "Donate")
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
        Section(header: Text("Send Feedback").headerProminence(.increased)) {
            Button { showMailCompose = true } label: {
                 HStack {
                     Label("contact@buyeuropean.io", systemImage: "envelope")
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