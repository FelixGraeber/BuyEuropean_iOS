//
//  ContentView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI
import Foundation // Required for NSLocalizedString

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
                Text(String(format: NSLocalizedString("location.status.ios", comment: ""), locationManager.authorizationStatus.description))
                #else
                Text(LocalizedStringKey("location.status.other"))
                #endif
                Text(String(format: NSLocalizedString("location.city_country", comment: ""), locationManager.currentCity ?? "...", locationManager.currentCountry ?? "..."))
            }
            .padding()
            .navigationTitle(LocalizedStringKey("app.title"))
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
