import SwiftUI
import CoreLocation // Import CoreLocation

struct LocationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    var onRequestPermission: () async -> Void // Action to trigger the request

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.fill") // Location icon
                .font(.system(size: 70))
                .foregroundColor(.green) // Use a different color (e.g., green)

            Text(LocalizedStringKey("permission.location.title")) // Updated title
                .font(.title2)
                .fontWeight(.bold)

            // Updated explanation text
            Text(LocalizedStringKey("permission.location.description"))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 16) {
                Button {
                    Task {
                        await onRequestPermission() // Call the passed-in request function
                        // Consider dismissing only after the system prompt is handled,
                        // which might require more complex state management in the parent view
                        // For simplicity now, we dismiss immediately after initiating the request.
                        dismiss()
                    }
                } label: {
                    Text(LocalizedStringKey("common.continue")) // Updated button text
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green) // Match icon color
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
}