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
    
    var body: some Scene {
        WindowGroup {
            // Inject the ServiceRegistry and LocationManager into the environment
            // Assuming ScanView is the root view now, otherwise adapt to ContentView
             ScanView() // Or ContentView() if that's the intended root
                 .environmentObject(serviceRegistry) // Pass the whole registry
                 .environmentObject(serviceRegistry.locationManager) // Pass the specific manager
        }
    }
}
