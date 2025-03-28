//
//  ContentView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI

struct ContentView: View {
    // LocationManager might still be needed for other purposes, or removed if not.
    // Keeping it for now in case status display is desired.
    @EnvironmentObject var locationManager: LocationManager 
    // REMOVED: @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                // Example: Display authorization status instead of the setting
                #if os(iOS)
                Text("Location Status: \(locationManager.authorizationStatus.description)")
                #else
                Text("Location Status: N/A")
                #endif
                Text("City: \(locationManager.currentCity ?? "..."), Country: \(locationManager.currentCountry ?? "...")")
            }
            .padding()
            .navigationTitle("BuyEuropean")
            .toolbar {
                // REMOVED: Settings ToolbarItem
            }
            // REMOVED: .sheet modifier for SettingsView
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager()) // Provide for preview
}
