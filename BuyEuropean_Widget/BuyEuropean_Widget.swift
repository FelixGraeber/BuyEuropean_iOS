//
//  OpenAppWidget.swift
//  BuyEuropean_Widget
//
//  Created by Felix Graeber on 05.04.25.
//

import WidgetKit
import SwiftUI

// 1. Timeline Entry
struct OpenAppEntry: TimelineEntry {
    let date: Date // Required by protocol, but not used visually
}

// 2. Timeline Provider
struct OpenAppProvider: TimelineProvider {
    // Placeholder for widget gallery
    func placeholder(in context: Context) -> OpenAppEntry {
        OpenAppEntry(date: Date())
    }

    // Snapshot for transient situations
    func getSnapshot(in context: Context, completion: @escaping (OpenAppEntry) -> ()) {
        let entry = OpenAppEntry(date: Date())
        completion(entry)
    }

    // Provide the actual timeline
    func getTimeline(in context: Context, completion: @escaping (Timeline<OpenAppEntry>) -> ()) {
        let entry = OpenAppEntry(date: Date())
        // Create a timeline that never refreshes
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// 3. Widget View
struct OpenAppWidgetView : View {
    var entry: OpenAppProvider.Entry // The entry provided by the provider
    @Environment(\.widgetFamily) var family // To detect widget size

    // Define the URL to open
    private var appURL: URL? {
        URL(string: "buyeuropean://open") // Using a simple path, can be extended later if needed
    }

    @ViewBuilder
    var body: some View {
        // Use a GeometryReader to potentially adapt icon size, though fixed SF Symbols are fine here
        GeometryReader { geometry in
            ZStack { // Use ZStack to center content
                // Conditional view based on widget family
                switch family {
                case .accessoryCircular:
                    Image(systemName: "app.dashed")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(geometry.size.width * 0.15) // Add some padding relative to size

                case .accessoryRectangular:
                     HStack {
                         Image(systemName: "app.dashed")
                         Text("Open App") // Or your app name: "BuyEuropean"
                             .font(.headline)
                     }
                     .padding(.horizontal, 4) // Minimal padding for rectangular

                // Add default cases for other families if needed, though we restrict them below
                default:
                    // Maybe show a generic icon or text for unsupported families
                    Image(systemName: "questionmark.app.dashed")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(geometry.size.width * 0.15)
                }
            }
            // Apply the URL link to the entire ZStack/view content
            .widgetURL(appURL)
        }
        // Apply container background styling for iOS 17+
         .containerBackground(.clear, for: .widget) // Use clear or a subtle background
    }
}

// 4. Widget Configuration
struct OpenAppWidget: Widget {
    let kind: String = "com.buyeuropean.openappwidget" // Unique identifier

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OpenAppProvider()) { entry in
            OpenAppWidgetView(entry: entry)
        }
        .configurationDisplayName("Open BuyEuropean")
        .description("Quickly open the BuyEuropean app.")
        // Specify only the supported lock screen families
#if os(iOS)
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
#endif
    }
}

// Note: The #Preview is removed as it requires more complex setup for URL handling
// and isn't essential for the widget functionality itself. You can add it back
// later for design iterations if needed, potentially mocking the environment.
