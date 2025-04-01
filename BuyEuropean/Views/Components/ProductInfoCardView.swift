import SwiftUI

struct ProductInfoCardView: View {
    let product: String
    let company: String
    let headquarters: String
    let rationale: String
    let countryFlag: String
    
    // Add properties for parent company info
    let parentCompany: String?
    let parentCompanyFlag: String
    let shouldShowParentCompany: Bool

    @State private var isRationaleExpanded = false
    @State private var isAnimated = false

    // Constants for styling
    private let cornerRadius: CGFloat = 16
    private let iconSize: CGFloat = 18
    private let iconCircleSize: CGFloat = 36
    private let iconCircleOpacity: Double = 0.12 // Slightly increased opacity

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            infoRow(
                icon: "tag.fill",
                iconColor: .blue,
                title: "Product", // Use sentence case for titles
                value: product
            )

            infoRow(
                icon: "building.2.fill",
                iconColor: .purple,
                title: "Company",
                value: company
            )

            headquartersRow() // Extracted subview

            // Conditionally display Parent Company row
            if shouldShowParentCompany {
                parentCompanyRow() // Extracted subview for parent company
            }
            
            rationaleSection() // Extracted subview
        }
        .padding() // Keep default padding inside card
        .background(Color(.systemBackground)) // Use system background for card
        .cornerRadius(cornerRadius) // Use standard corner radius
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4) // Adjusted shadow
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 15) // Slightly reduced offset
        .onAppear {
             // Use withAnimation directly here for onAppear effect
            withAnimation(.easeOut(duration: 0.4).delay(0.05)) {
                isAnimated = true
            }
        }
    }

    // MARK: - Subviews

    private func infoRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconView(systemName: icon, color: iconColor) // Use helper

            VStack(alignment: .leading, spacing: 2) { // Reduced spacing
                Text(title.uppercased()) // Keep uppercase if desired, or use sentence case
                    .font(.caption)
                    .fontWeight(.medium) // Use medium weight
                    .foregroundColor(.secondary) // Standard secondary color
                Text(value)
                    .font(.body)
                    // .fontWeight(.medium) // Default weight for body is fine
                    .foregroundColor(.primary) // Standard primary color
            }
            Spacer() // Ensure row takes full width if needed
        }
    }

    private func headquartersRow() -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconView(systemName: "mappin.circle.fill", color: .green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Country (Headquarters)".uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) { // Align text baselines
                    Text(headquarters.localizedCountryNameFromAlpha3()) // Convert alpha-3 code to full name
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(countryFlag)
                         .font(.title3) // Slightly smaller flag?
                         .baselineOffset(-2) // Adjust baseline if needed
                }
            }
             Spacer()
        }
    }

    // New subview for Parent Company
    private func parentCompanyRow() -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconView(systemName: "building.columns.fill", color: .brown) // Example icon

            VStack(alignment: .leading, spacing: 2) {
                Text("Ultimate Parent Company".uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) { // Align text baselines
                    Text(parentCompany ?? "N/A") // Display parent company name
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(parentCompanyFlag) // Display parent company flag
                         .font(.title3)
                         .baselineOffset(-2)
                }
            }
             Spacer()
        }
    }

     private func rationaleSection() -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconView(systemName: "info.circle.fill", color: .orange)

            VStack(alignment: .leading, spacing: 4) { // Increased spacing for rationale text
                Text("Identification Rationale".uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Use a Group for conditional content
                Group {
                    if isRationaleExpanded || rationale.count < 100 {
                        Text(rationale)
                    } else {
                        Text(rationale.prefix(100) + "...")
                    }
                }
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4) // Add line spacing for readability
                // Animate size changes explicitly if needed, though VStack should handle it
                // .animation(.easeInOut, value: isRationaleExpanded)

                // Only show button if text is long enough
                if rationale.count >= 100 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { // Animate the toggle
                            isRationaleExpanded.toggle()
                        }
                    } label: {
                         Text(isRationaleExpanded ? "Show Less" : "Read More")
                             .font(.footnote)
                             .fontWeight(.medium)
                             .padding(.top, 4) // Add padding above button
                    }
                    .tint(.blue) // Use standard tint for links/buttons
                }
            }
             Spacer()
        }
    }

    // Helper for Icon Views
    private func iconView(systemName: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(iconCircleOpacity))
                .frame(width: iconCircleSize, height: iconCircleSize)
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium)) // Use medium weight
                .foregroundColor(color)
        }
    }
}