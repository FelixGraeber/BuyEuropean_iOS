import SwiftUI
import StoreKit

struct SupportView: View {
    @EnvironmentObject var iapManager: IAPManager
    @Environment(\.dismiss) var dismiss
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView { // Embed in NavigationView for title and close button
            VStack(spacing: 20) {
                
                Text("Support BuyEuropean")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 30)

                Text("Your support helps keep the app running and ad-free. Choose an option below:")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                if iapManager.isFetchingProducts {
                    ProgressView("Loading Products...")
                        .padding(.top, 40)
                } else if iapManager.products.isEmpty {
                    Text("Could not load support options. Please check your connection and try again.")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ForEach(iapManager.products) { product in
                        productButton(product)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
                
                restoreButton
                
                Text("Payments are processed securely by Apple.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
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
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // Product Button View
    @ViewBuilder
    private func productButton(_ product: Product) -> some View {
        Button { 
            Task { 
                do {
                    try await iapManager.purchase(product)
                    // Optional: Dismiss view on successful purchase?
                    // if iapManager.purchasedProductIDs.contains(product.id) { 
                    //    dismiss()
                    // }
                } catch {
                    // --- MANUALLY HANDLE ERROR HERE ---
                    print("[SupportView] Purchase failed: \(error)")
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    // ----------------------------------
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
            .background(.regularMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        // Maybe disable if already purchased?
        // .disabled(iapManager.purchasedProductIDs.contains(product.id))
    }

    // Restore Purchases Button
    @ViewBuilder
    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                await iapManager.restorePurchases()
                // --- MANUALLY HANDLE ERROR and SUCCESS HERE ---
                if let error = iapManager.error {
                    print("[SupportView] Restore failed: \(error)")
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                } else {
                    // Optionally show a success message
                    alertMessage = "Purchases restored successfully!"
                    showAlert = true
                } 
                // --------------------------------------------
            }
        }
        .padding(.vertical)
        .buttonStyle(.bordered)
    }
}

// MARK: - Preview
struct SupportView_Previews: PreviewProvider {
    // Explicitly create EntitlementManager first for the preview
    @MainActor static var entitlementManager = EntitlementManager()
    // Create IAPManager and pass the manager
    @MainActor static var iapManager = IAPManager(entitlementManager: entitlementManager) 
    
    static var previews: some View {
        // Simulate some products for preview
        // Note: In actual preview, fetching might fail unless configured.
        // You might want a mock IAPManager for better previews.
        SupportView()
            .environmentObject(iapManager)
            .environmentObject(entitlementManager) // Also inject the entitlement manager if needed by subviews
    }
} 