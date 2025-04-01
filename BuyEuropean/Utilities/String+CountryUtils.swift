import Foundation

extension String {

    // Dictionary to map common ISO 3166-1 alpha-3 codes to alpha-2 codes
    private static let alpha3ToAlpha2Map: [String: String] = [
        // Europe
        "ALB": "AL", "AND": "AD", "AUT": "AT", "BEL": "BE", "BGR": "BG", "BIH": "BA",
        "BLR": "BY", "CHE": "CH", "CYP": "CY", "CZE": "CZ", "DEU": "DE", "DNK": "DK",
        "ESP": "ES", "EST": "EE", "FIN": "FI", "FRA": "FR", "FRO": "FO", "GBR": "GB",
        "GIB": "GI", "GRC": "GR", "HRV": "HR", "HUN": "HU", "IRL": "IE", "ISL": "IS",
        "ITA": "IT", "LIE": "LI", "LTU": "LT", "LUX": "LU", "LVA": "LV", "MCO": "MC",
        "MDA": "MD", "MKD": "MK", "MLT": "MT", "MNE": "ME", "NLD": "NL", "NOR": "NO",
        "POL": "PL", "PRT": "PT", "ROU": "RO", "RUS": "RU", "SMR": "SM", "SRB": "RS",
        "SVK": "SK", "SVN": "SI", "SWE": "SE", "TUR": "TR", "UKR": "UA", "VAT": "VA",
        // North America
        "CAN": "CA", "MEX": "MX", "USA": "US",
        // Add other relevant regions as needed
    ]

    /// Converts an ISO 3166-1 alpha-3 country code string to its localized full name.
    /// - Returns: The localized country name, or the original code if conversion fails.
    static func localizedName(forAlpha3Code code: String?) -> String {
        guard let code = code, code.count == 3 else {
            return code ?? "Unknown Country" // Return original or default if input is invalid
        }

        // Convert alpha-3 to alpha-2
        guard let alpha2Code = alpha3ToAlpha2Map[code.uppercased()] else {
            // If no mapping found, return the original alpha-3 code
            return code
        }

        // Get localized name from alpha-2 code
        if let localizedName = Locale.current.localizedString(forRegionCode: alpha2Code) {
            return localizedName
        } else {
            // If localization fails, return the original alpha-3 code as fallback
            return code
        }
    }
    
    /// Instance method wrapper for `localizedName(forAlpha3Code:)`.
    /// Converts the string instance (assumed to be an alpha-3 code) to its localized full name.
    /// - Returns: The localized country name, or the original string if conversion fails.
    func localizedCountryNameFromAlpha3() -> String {
        return String.localizedName(forAlpha3Code: self)
    }
} 