import SwiftUI

// Assume ClassificationStyle is defined with title, description, badgeColor
// struct ClassificationStyle { let title: String; let description: String; let badgeColor: Color }
// extension ClassificationStyle { static func forClassification(_ classification: Classification) -> ClassificationStyle } // Example usage

struct ClassificationBadgeView: View {
    let style: ClassificationStyle
    @State private var isAnimated = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) { // Slightly reduced spacing
            // Main badge - Using Capsule shape for a more modern look
            Text(style.title)
                .font(.headline) // Keep headline
                .fontWeight(.bold) // Use semibold for badge text
                .foregroundColor(.white) // White text for contrast on color
                .padding(.horizontal, 24)
                .padding(.vertical, 10) // Slightly less vertical padding for capsule
                .background(
                    Capsule() // Use Capsule shape
                        .fill(style.badgeColor(for: colorScheme))
                )
                .shadow(color: style.badgeColor(for: colorScheme).opacity(0.4), radius: 6, x: 0, y: 3) // Adjusted shadow
                .scaleEffect(isAnimated ? 1.0 : 0.8)
                .opacity(isAnimated ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.1), value: isAnimated) // Smooth spring
        }
        .padding(.vertical, 8) // Keep overall vertical padding
        .onAppear {
            // No need for withAnimation here if using .animation modifier bound to isAnimated
            isAnimated = true
        }
        // Reset animation state if needed on disappear
        // .onDisappear { isAnimated = false }
    }
}