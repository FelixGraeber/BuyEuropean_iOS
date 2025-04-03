import SwiftUI
import StoreKit

// Define the support type options
enum SupportType: String, CaseIterable, Identifiable {
    case oneTime = "One-Time"
    case monthly = "Monthly"
    var id: String { self.rawValue }
}

struct SupportView: View {
    @EnvironmentObject var iapManager: IAPManager
    @Environment(\.dismiss) var dismiss
    @State private var showAlert = false
    @State private var alertMessage = ""
    // State to track the selected support type
    @State private var selectedSupportType: SupportType = .oneTime

    // Filtered product lists based on type
    private var oneTimeProducts: [Product] {
        iapManager.products.filter { $0.id.hasPrefix("onetime_") || $0.id.hasPrefix("support_") }.sorted { $0.price < $1.price }
    }

    private var monthlyProducts: [Product] {
        iapManager.products.filter { $0.id.hasPrefix("longterm_") }.sorted { $0.price < $1.price }
    }

    var body: some View {
        NavigationView { // Embed in NavigationView for title and close button
            ScrollView { // Use ScrollView for potentially longer lists
                VStack(alignment: .leading, spacing: 20) {

                    Text("Support BuyEuropean")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10) // Reduced top padding slightly

                    // Updated explanatory text
                    Text("To keep BuyEuropean free and ad-free, we rely on community support. Choose how you'd like to contribute:")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)

                    // Picker for selecting support type
                    Picker("Support Type", selection: $selectedSupportType) {
                        ForEach(SupportType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented) // Use segmented control style
                    .padding(.bottom, 10)

                    if iapManager.isFetchingProducts {
                        ProgressView("Loading Products...")
                            .padding(.top, 20) // Adjusted padding
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // Display products based on selection
                        displayProductList()
                    }

                    Spacer(minLength: 20) // Ensure some space before the restore button

                    Text("Payments are processed securely by Apple.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center) // Center caption
                        .padding(.bottom, 10)
                }
                .padding(.horizontal, 20) // Apply horizontal padding to the VStack content
            }
            .navigationTitle("Support Us") // Set the navigation title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { // Add a close button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Info", isPresented: $showAlert) { // Changed title to Info for general messages
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            // Show error specific to IAP Manager separately if needed
            .alert("Purchase Error", isPresented: .constant(iapManager.error != nil), presenting: iapManager.error) { _ in
                 Button("OK") { iapManager.error = nil } // Clear error on dismiss
            } message: { error in
                 Text(error.localizedDescription)
            }
        }
        .navigationViewStyle(.stack) // Use stack style for better appearance on larger devices if needed
    }

    // ViewBuilder for displaying the correct product list
    @ViewBuilder
    private func displayProductList() -> some View {
        let productsToDisplay = (selectedSupportType == .oneTime) ? oneTimeProducts : monthlyProducts
        let listIsEmpty = productsToDisplay.isEmpty

        if listIsEmpty && !iapManager.isFetchingProducts && iapManager.products.isEmpty {
             // Case: No products fetched at all
             Text("Could not load support options. Please check your connection and try again.")
                 .foregroundColor(.red)
                 .multilineTextAlignment(.leading)
                 .padding()
        } else if listIsEmpty && !iapManager.isFetchingProducts {
            // Case: Products fetched, but none match the selected type (unlikely with current setup, but good practice)
             Text("No \(selectedSupportType.rawValue.lowercased()) options available at this time.")
                 .foregroundColor(.secondary)
                 .multilineTextAlignment(.center)
                 .padding()
        } else {
            // Display the filtered list
            VStack(spacing: 15) { // Add spacing between product buttons
                ForEach(productsToDisplay) { product in
                    productButton(product)
                }
            }
        }
    }


    // Product Button View (Remains largely the same)
    @ViewBuilder
    private func productButton(_ product: Product) -> some View {
        Button {
            Task {
                do {
                    try await iapManager.purchase(product)
                    // Optional: Show success message or dismiss view
                    if iapManager.purchasedProductIDs.contains(product.id) {
                       alertMessage = "Thank you for your support!"
                       showAlert = true
                       // Optionally dismiss after a delay?
                    }
                } catch {
                    // Error is now handled by the .alert modifier bound to iapManager.error
                    print("[SupportView] Purchase failed: \(error)")
                    // No need to set local alert state here anymore
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.thinMaterial) // Changed background for subtle difference
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        // Example: Dim if purchased (adjust based on your needs, esp for subscriptions)
         .opacity(iapManager.purchasedProductIDs.contains(product.id) && product.type != .autoRenewable ? 0.6 : 1.0)
         .disabled(iapManager.purchasedProductIDs.contains(product.id) && product.type != .autoRenewable)
    }
}


// MARK: - Preview
struct SupportView_Previews: PreviewProvider {
    // Explicitly create EntitlementManager first for the preview
    @MainActor static var entitlementManager = EntitlementManager()
    // Create IAPManager and pass the manager
    @MainActor static var iapManager: IAPManager = {
        let manager = IAPManager(entitlementManager: entitlementManager)
        // --- Simulate Products for Preview ---
        // Uncomment and modify if you have a way to create mock Product instances
        /*
        let mockProduct1 = Product(...) // Requires StoreKit Test file or manual creation
        let mockProduct2 = Product(...)
        manager.products = [mockProduct1, mockProduct2]
        manager.purchasedProductIDs = ["onetime_4.99"] // Simulate a purchased product
        */
        // -------------------------------------
        return manager
    }()

    static var previews: some View {
        SupportView()
            .environmentObject(iapManager)
            .environmentObject(entitlementManager) // Also inject the entitlement manager
    }
} 