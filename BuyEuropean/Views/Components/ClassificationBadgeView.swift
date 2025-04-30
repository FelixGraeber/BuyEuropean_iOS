import SwiftUI

// Assume ClassificationStyle is defined with title, description, badgeColor
// struct ClassificationStyle { let title: String; let description: String; let badgeColor: Color }
// extension ClassificationStyle { static func forClassification(_ classification: Classification) -> ClassificationStyle } // Example usage

struct ClassificationBadgeView: View {
    let style: ClassificationStyle
    var font: Font? = nil
    @State private var isAnimated = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            // Main badge - Using Capsule shape for a more modern look
            Text(style.title)
                .font(font ?? .headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, font == .caption2 ? 14 : 24)
                .padding(.vertical, font == .caption2 ? 4 : 10)
                .background(
                    Capsule()
                        .fill(style.badgeColor(for: colorScheme))
                )
                .shadow(color: style.badgeColor(for: colorScheme).opacity(0.4), radius: 6, x: 0, y: 3)
                .scaleEffect(isAnimated ? 1.0 : 0.8)
                .opacity(isAnimated ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.1), value: isAnimated)
        }
        .padding(.vertical, 8)
        .onAppear {
            // No need for withAnimation here if using .animation modifier bound to isAnimated
            isAnimated = true
        }
        // Reset animation state if needed on disappear
        // .onDisappear { isAnimated = false }
    }
}