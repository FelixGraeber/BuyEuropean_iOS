import SwiftUI
import StoreKit

@MainActor
class IAPManager: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isFetchingProducts = false
    @Published var error: Error? = nil // To display errors in the UI

    // MARK: - Product Identifiers

    // --- REPLACE WITH YOUR ACTUAL PRODUCT IDS ---
    private let productIDs: Set<String> = [
        "support_buyeuropean_0.99", // Example ID for one-time
    ]
    // --------------------------------------------

    private let entitlementManager: EntitlementManager // To manage access based on purchases
    private var updates: Task<Void, Never>? = nil // Task for listening transaction updates

    // MARK: - Initialization

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        // Start listening for transactions as soon as the manager is initialized.
        updates = observeTransactionUpdates()

        // Fetch products on initialization
        Task {
            await fetchProducts()
        }
    }

    deinit {
        // Cancel the task when the manager is deallocated
        updates?.cancel()
    }

    // MARK: - Public Methods

    func fetchProducts() async {
        guard !isFetchingProducts else { return } // Prevent concurrent fetches
        print("[IAPManager] Fetching products...")
        isFetchingProducts = true
        error = nil

        do {
            let storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.sorted { $0.price < $1.price } // Sort by price
            print("[IAPManager] Fetched \(products.count) products.")
        } catch {
            self.error = error // Store the error
            print("[IAPManager] Failed to fetch products: \(error)")
        }

        isFetchingProducts = false
        await updatePurchasedStatus() // Update status after fetching
    }

    func purchase(_ product: Product) async throws {
        print("[IAPManager] Initiating purchase for product: \(product.id)")
        error = nil // Clear previous error
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                print("[IAPManager] Purchase successful, verifying transaction...")
                // Verification already happened implicitly (or throws). Now process it.
                await processTransaction(verification)
            case .userCancelled:
                print("[IAPManager] Purchase cancelled by user.")
                // No error needed, user action.
                return // Exit gracefully
            case .pending:
                print("[IAPManager] Purchase is pending, requires action in App Store.")
                // Inform the user if necessary, no error state here.
                return // Exit gracefully
            @unknown default:
                print("[IAPManager] Unknown purchase result.")
                // Set a generic error or handle specific unknown cases if they arise.
                self.error = IAPError.unknownPurchaseError
            }
        } catch {
            print("[IAPManager] Purchase failed with error: \(error)")
            self.error = error // Store the purchase error
            throw error // Re-throw to let the caller know
        }
    }

    func restorePurchases() async {
        print("[IAPManager] Attempting to restore purchases...")
        error = nil // Clear previous error
        isFetchingProducts = true // Use this flag to indicate activity
        do {
            try await AppStore.sync()
            print("[IAPManager] Purchases synced successfully.")
            // Re-verify and update entitlements after syncing
            await updatePurchasedStatus()
        } catch {
            print("[IAPManager] Failed to restore purchases: \(error)")
            self.error = error
        }
        isFetchingProducts = false
    }

    // MARK: - Private Transaction Handling

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await verificationResult in StoreKit.Transaction.updates {
                print("[IAPManager] Received transaction update.")
                // Verification happens implicitly when accessing verificationResult.payloadData
                await self.processTransaction(verificationResult)
            }
        }
    }

    private func processTransaction(_ verificationResult: VerificationResult<StoreKit.Transaction>) async {
        print("[IAPManager] Processing transaction...")
        do {
            let transaction = try verificationResult.payloadValue // Check verification
            print("[IAPManager] Transaction verified for product ID: \(transaction.productID)")

            // Add the purchased product ID
            if transaction.revocationDate == nil { // Only add if not revoked
                purchasedProductIDs.insert(transaction.productID)
                print("[IAPManager] Added product ID: \(transaction.productID) to purchased set.")
            } else {
                print("[IAPManager] Transaction \(transaction.id) for \(transaction.productID) was revoked.")
                purchasedProductIDs.remove(transaction.productID) // Remove if revoked
            }

            // Update entitlements based on the latest state
            await entitlementManager.updateUserEntitlement(basedOn: purchasedProductIDs)

            // IMPORTANT: Always finish the transaction
            await transaction.finish()
            print("[IAPManager] Transaction finished: \(transaction.id)")

        } catch let verificationError as VerificationResult<Any>.VerificationError {
            print("[IAPManager] Transaction verification failed: \(verificationError)")
            self.error = verificationError
        } catch {
            print("[IAPManager] Failed to process transaction: \(error)")
            self.error = error
        }
        // No need to call updatePurchasedStatus separately, it's implicitly updated via the entitlementManager now
    }


    // Check current entitlements and purchased products.
    private func updatePurchasedStatus() async {
        print("[IAPManager] Updating purchased status...")
        var validPurchasedIDs: Set<String> = []
        // Iterate through all transactions and verify them again.
        for await verificationResult in StoreKit.Transaction.currentEntitlements {
             if case .verified(let transaction) = verificationResult {
                 // Check if the transaction is for a product managed by this IAP Manager
                 // and if it's currently active (e.g., not refunded, subscription not expired)
                 if productIDs.contains(transaction.productID) && transaction.revocationDate == nil {
                     // For subscriptions, you might need additional checks (e.g., expiry date)
                     // if transaction.productType == .autoRenewableSubscription {
                     //    guard let expiryDate = transaction.expirationDate else { continue }
                     //    if expiryDate > Date() { // Check if not expired
                     //        validPurchasedIDs.insert(transaction.productID)
                     //    }
                     // } else {
                          validPurchasedIDs.insert(transaction.productID) // Assume non-consumables/non-renewing are valid if verified and not revoked
                     // }
                 }
             }
        }
        self.purchasedProductIDs = validPurchasedIDs
        await entitlementManager.updateUserEntitlement(basedOn: validPurchasedIDs)
        print("[IAPManager] Updated purchased IDs: \(self.purchasedProductIDs)")
    }
}

// MARK: - Helper Entitlement Manager (Example)

// A simple manager to track if the user is entitled to premium features.
// You might replace this with UserDefaults, a dedicated UserState service, etc.
@MainActor
class EntitlementManager: ObservableObject {
    @Published var isProUser: Bool = false

    func updateUserEntitlement(basedOn purchasedIDs: Set<String>) {
        // Check if ANY of the product IDs granting pro access are present
        let hasProPurchase = purchasedIDs.contains("com.yourapp.onetime_support") || purchasedIDs.contains("com.yourapp.monthly_support")
        if isProUser != hasProPurchase {
            isProUser = hasProPurchase
            print("[EntitlementManager] User pro status updated to: \(isProUser)")
        }
    }
}


// MARK: - Custom Error Enum

enum IAPError: LocalizedError {
    case unknownPurchaseError
    case productNotFound
    case networkError(underlyingError: Error)
    // Add more specific errors as needed

    var errorDescription: String? {
        switch self {
        case .unknownPurchaseError:
            return "An unknown error occurred during the purchase."
        case .productNotFound:
            return "The requested product could not be found."
        case .networkError(let underlyingError):
            return "Network error: \(underlyingError.localizedDescription)"
        }
    }
} 