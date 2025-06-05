//
//  BuyEuropeanApp.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI

@main
struct BuyEuropeanApp: App {
    @AppStorage(UserDefaultsKeys.hasCompletedOnboarding) var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

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
        // Initialize showOnboarding based on the persisted value
        // This needs to be done after _hasCompletedOnboarding is initialized
        // which happens before init() body is called.
        _showOnboarding = State(initialValue: !hasCompletedOnboarding)
    }

    var body: some Scene {
        WindowGroup {
            // Inject both managers into the environment
            ScanView()
                .environmentObject(iapManager)
                .environmentObject(entitlementManager)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(showOnboarding: $showOnboarding)
                }
                // Update hasCompletedOnboarding when showOnboarding changes to false
                .onChange(of: showOnboarding) { newValue in
                    if !newValue {
                        hasCompletedOnboarding = true
                    }
                }
            // Ensure other required environment objects are still passed if needed
            // e.g., .environmentObject(SomeOtherService())
        }
    }
}
