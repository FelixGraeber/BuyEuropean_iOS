//
//  BuyEuropeanApp.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI

@main
struct BuyEuropeanApp: App {
    // Create the central service registry
    @StateObject private var serviceRegistry = ServiceRegistry.shared
    
    // Initialize the IAP Manager and Entitlement Manager
    // Use @StateObject to ensure they persist through the app's lifecycle
    @StateObject private var iapManager:
        IAPManager // Specify type
    @StateObject private var entitlementManager = EntitlementManager()

    // Custom init to link the two managers
    init() {
        let entitlementMgr = EntitlementManager()
        let iapMgr = IAPManager(entitlementManager: entitlementMgr)
        _iapManager = StateObject(wrappedValue: iapMgr)
        _entitlementManager = StateObject(wrappedValue: entitlementMgr)
    }

    var body: some Scene {
        WindowGroup {
            // Inject both managers into the environment
            ScanView()
                .environmentObject(iapManager)
                .environmentObject(entitlementManager)
                .onOpenURL { url in
                    // Handle the URL
                    print("App opened with URL: \(url)")
                    // You could add more logic here later, e.g., navigate to a specific view
                    // based on url.path or query parameters if needed.
                }
            // Ensure other required environment objects are still passed if needed
            // e.g., .environmentObject(SomeOtherService())
        }
    }
}
