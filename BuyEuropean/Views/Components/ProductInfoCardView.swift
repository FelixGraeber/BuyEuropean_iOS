import SwiftUI

struct ProductInfoCardView: View {
    let product: String
    let company: String
    let headquarters: String // Assumed to be Alpha-3 Country Code
    let rationale: String
    let countryFlag: String

    // Add properties for parent company info
    let parentCompany: String?
    let parentCompanyHeadquarters: String? // Add HQ code
    let parentCompanyFlag: String
    let shouldShowParentCompany: Bool

    // Removed isRationaleExpanded state
    @State private var isAnimated = false

    // Constants for styling
    private let cornerRadius: CGFloat = 16
    private let iconSize: CGFloat = 18
    private let iconCircleSize: CGFloat = 36
    private let iconCircleOpacity: Double = 0.12

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Product Row (Unchanged)
            infoRow(
                icon: "tag.fill",
                iconColor: .blue,
                title: "Product",
                value: product
            )

            // 2. Combined Company & Country Row
            companyAndCountryRow()

            // 3. Conditionally display Combined Parent Company Row
            if shouldShowParentCompany {
                parentCompanyAndCountryRow()
            }

            // 4. Rationale Section (Always expanded)
            rationaleSection()
        }
        .padding()
        // Use Color(.systemBackground) for SwiftUI equivalent
        .background(Color(.systemBackground))
        .cornerRadius(cornerRadius)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 15)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.05)) {
                isAnimated = true
            }
        }
    }

    // MARK: - Subviews

    // Generic Info Row (Kept for Product)
    private func infoRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconView(systemName: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true) // Allow product name to wrap
            }
            Spacer()
        }
    }

    // New: Combined Company & Country Row
    private func companyAndCountryRow() -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Use building icon for company
            iconView(systemName: "building.2.fill", color: .purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("Company".uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Stack company and country vertically
                VStack(alignment: .leading, spacing: 2) {
                    Text(company)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("(\(headquarters.localizedCountryNameFromAlpha3()) \(countryFlag))")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            Spacer()
        }
    }

    // New: Combined Parent Company Row
    private func parentCompanyAndCountryRow() -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconView(systemName: "building.columns.fill", color: .brown)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ultimate Parent Company".uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Stack parent company and country vertically
                VStack(alignment: .leading, spacing: 2) {
                    Text(parentCompany ?? "N/A")
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    let parentCountryName = parentCompanyHeadquarters?.localizedCountryNameFromAlpha3() ?? ""
                    Text("(\(parentCountryName) \(parentCompanyFlag))")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            Spacer()
        }
    }

    // Modified: Rationale Section (Always expanded)
     private func rationaleSection() -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconView(systemName: "info.circle.fill", color: .orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Identification Rationale".uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Always display full rationale
                Text(rationale)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true) // Ensure text wraps

                // Removed the conditional Group and the "Read More/Less" Button
            }
            Spacer()
        }
    }

    // Helper for Icon Views (Unchanged)
    private func iconView(systemName: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(iconCircleOpacity))
                .frame(width: iconCircleSize, height: iconCircleSize)
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(color)
        }
    }
}
