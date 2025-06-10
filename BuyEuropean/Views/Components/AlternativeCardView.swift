import SwiftUI

// Assume EuropeanAlternative is defined:
// struct EuropeanAlternative: Identifiable { let id = UUID(); let productName, company, description: String; let country: String? }

struct AlternativeCardView: View {
    let alternative: EuropeanAlternative
    let countryFlag: String
    let onLearnMore: () -> Void
    var descriptionOverride: String? = nil
    var isLoading: Bool = false

    @State private var isAnimated = false
    @Environment(\.colorScheme) private var colorScheme

    // Styling constants
    private let cornerRadius: CGFloat = 12 // Slightly smaller radius for nested cards?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Reduced spacing within card
            // Header: Product Name and Flag
            HStack {
                Text(alternative.productName)
                    .font(.headline) // Keep headline
                    .fontWeight(.semibold) // Make product name stand out
                    .foregroundColor(Color("BrandPrimary")) // Use asset catalog color

                Spacer()

                // Show flag only if country exists
                if alternative.country != nil && !countryFlag.isEmpty {
                    Text(countryFlag)
                        .font(.title3) // Consistent flag size
                }
            }

            // Company Name
            Text(alternative.company)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary) // Use secondary color

            // Description
            Text(descriptionOverride ?? alternative.description)
                .font(.body)
                .foregroundColor(.primary.opacity(0.9)) // Slightly dimmer primary for body
                .lineSpacing(3) // Add line spacing
                .padding(.top, 4) // Space above description
            if isLoading {
                ProgressView().padding(.top, 2)
            }

            // Learn More Button - Aligned Right
            HStack {
                Spacer() // Pushes button to the right
                Button(action: onLearnMore) {
                    Label(LocalizedStringKey("alternatives.learn_more"), systemImage: "arrow.up.right.square")
                         .font(.footnote.weight(.medium))
                         .padding(.vertical, 4) // Smaller padding for footnote button
                }
                .tint(Color("BrandSecondary")) // Use asset catalog color
            }
            .padding(.top, 4) // Space above button row
        }
        .padding(12) // Reduced padding inside card
        .background(Color("CardBackground")) // Use asset catalog color
        .cornerRadius(cornerRadius)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.06), radius: 5, x: 0, y: 2) // Enhanced shadow for dark mode
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 10) // Reduced offset
        .onAppear {
             // Use withAnimation directly
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                isAnimated = true
            }
        }
    }
}

struct AlternativesHeaderView: View {
    @State private var isAnimated = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) { // Reduced spacing
            HStack(spacing: 8) {
                Image(systemName: "flag.2.crossed.fill") // More relevant icon?
                    .font(.title3) // Consistent icon size
                    .foregroundColor(Color("BrandPrimary")) // Use asset catalog color

                Text(LocalizedStringKey("alternatives.title"))
                    .font(.title3) // Consistent sizing
                    .fontWeight(.semibold) // Medium weight for better readability
            }

            Text(LocalizedStringKey("alternatives.subtitle")) // Updated description
                .font(.subheadline)
                .foregroundColor(.secondary) // Standard secondary color
                // .italic() // Removed italic for cleaner look
        }
        .padding(.bottom, 8) // Space below header before cards
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 10)
        .onAppear {
             withAnimation(.easeOut(duration: 0.5)) {
                isAnimated = true
            }
        }
    }
}