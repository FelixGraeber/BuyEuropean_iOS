import SwiftUI
import Foundation
import NaturalLanguage

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
    @State private var translatedRationale: String? = nil
    @State private var isTranslating = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

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
                title: LocalizedStringKey("product.label"),
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
            
            // 5. AI disclaimer text
            Text(LocalizedStringKey("ai.disclaimer"))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        // Use our cardBackground color for better dark mode support
        .background(Color("CardBackground"))
        .cornerRadius(cornerRadius)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 15)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.05)) {
                isAnimated = true
            }
        }
        .task {
            // Attempt auto-translation if translatedRationale is nil
            if translatedRationale == nil {
                await translateRationale()
            }
        }
    }

    // MARK: - Subviews

    // Generic Info Row (Kept for Product)
    private func infoRow(icon: String, iconColor: Color, title: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconView(systemName: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
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
                Text(LocalizedStringKey("company.label"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Combine company name and country/flag into a single Text view for proper wrapping
                Text("\(company) (\(CountryFlagUtility.localizedName(forAlpha3Code: headquarters)) \(countryFlag))")
                    .font(.body)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }

    // New: Combined Parent Company Row
    private func parentCompanyAndCountryRow() -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconView(systemName: "building.columns.fill", color: .brown)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey("ultimate_parent.label"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Stack parent company and country vertically
                VStack(alignment: .leading, spacing: 2) {
                    Text(parentCompany ?? "N/A")
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    let parentCountryName = CountryFlagUtility.localizedName(forAlpha3Code: parentCompanyHeadquarters ?? "")
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
                Text(LocalizedStringKey("identification.label"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Display translated text if available, otherwise show original
                Text(translatedRationale ?? rationale)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Show loading indicator while translating
                if isTranslating {
                    ProgressView()
                        .padding(.top, 4)
                }
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
    
    // MARK: - Translation Logic
    
    private func translateRationale() async {
        // If we already have a translation, toggle back to original
        if translatedRationale != nil {
            translatedRationale = nil
            return
        }
        
        // Skip empty text
        if rationale.isEmpty {
            return
        }
        
        // Show loading indicator
        isTranslating = true
        defer { isTranslating = false }
        
        // Get the current locale for target language
        let targetLocale = locale
        
        do {
            // First, detect the language
            let languageRecognizer = NLLanguageRecognizer()
            languageRecognizer.processString(rationale)
            
            guard let sourceLanguage = languageRecognizer.dominantLanguage else {
                print("Could not determine rationale language")
                return
            }
            
            // Get target language code from current locale
            guard let targetLanguageCode = targetLocale.language.languageCode?.identifier else {
                print("Could not determine target language code")
                return
            }
            
            // Skip if source and target are the same
            if sourceLanguage.rawValue == targetLanguageCode {
                print("Source and target languages are the same, skipping translation")
                return
            }
            
            // Attempt to create a URL request for a simple translation API
            let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(sourceLanguage.rawValue)&tl=\(targetLanguageCode)&dt=t&q=\(rationale.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            guard let url = URL(string: urlString) else {
                print("Failed to create translation URL")
                return
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Parse the JSON response - fixed to concatenate all translated segments
            if let json = try JSONSerialization.jsonObject(with: data) as? Array<Any>,
               let translationArray = json.first as? Array<Any> {
                
                // The first element in the JSON response is an array of translation segments
                // Each segment is an array where the first element is the translated text
                var completeTranslation = ""
                
                // Go through all segments and concatenate them
                for translationSegment in translationArray {
                    if let segment = translationSegment as? Array<Any>,
                       let translatedTextPart = segment.first as? String {
                        completeTranslation += translatedTextPart
                    }
                }
                
                if !completeTranslation.isEmpty {
                    await MainActor.run {
                        self.translatedRationale = completeTranslation
                    }
                }
            }
        } catch {
            print("Translation error: \(error.localizedDescription)")
        }
    }
} 
