import Foundation

extension String {

    /// Converts an ISO 3166-1 alpha-3 country code string to its localized full name.
    /// Uses the map from CountryFlagUtility for Alpha-3 to Alpha-2 conversion.
    /// - Returns: The localized country name, or the original code if conversion fails.
    static func localizedName(forAlpha3Code code: String?) -> String {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines), code.count == 3 else {
            return code ?? "Unknown Country" // Return original or default if input is invalid
        }
        let alpha3Upper = code.uppercased()

        // Convert alpha-3 to alpha-2 using the map from CountryFlagUtility
        guard let alpha2Code = CountryFlagUtility.alpha3ToAlpha2Map[alpha3Upper] else {
            // If no mapping found, return the original alpha-3 code
             print("Warning: No Alpha-2 mapping found for Alpha-3 code: \(alpha3Upper). Returning original code.")
            return code // Return original input code
        }

        // Get localized name from alpha-2 code
        if let localizedName = Locale.current.localizedString(forRegionCode: alpha2Code) {
            return localizedName
        } else {
            // If localization fails, return the alpha-2 code as fallback
            print("Warning: Could not get localized name for Alpha-2 code: \(alpha2Code). Returning Alpha-2 code.")
            return alpha2Code 
        }
    }
    
    /// Instance method wrapper for `localizedName(forAlpha3Code:)`.
    /// Converts the string instance (assumed to be an alpha-3 code) to its localized full name.
    /// - Returns: The localized country name, or the original string if conversion fails.
    func localizedCountryNameFromAlpha3() -> String {
        return String.localizedName(forAlpha3Code: self)
    }
} 