//
//  CountryFlagUtility.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import Foundation

struct CountryFlagUtility {
    
    /// Converts a country name or code to a flag emoji
    /// - Parameter country: Country name or code
    /// - Returns: Flag emoji or globe emoji if not found
    static func countryToFlag(_ country: String?) -> String {
        guard let country = country, !country.isEmpty else { return "🌍" }
        
        let normalizedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // First, check if it's a direct country code (2 letters)
        if normalizedCountry.count == 2 {
            return normalizedCountry
                .unicodeScalars
                .map { String(UnicodeScalar(127397 + $0.value)!) }
                .joined()
        }
        
        // Check if it's a 3-letter ISO code
        if normalizedCountry.count == 3, let twoLetterCode = alpha3ToAlpha2Map[normalizedCountry] {
            return twoLetterCode
                .unicodeScalars
                .map { String(UnicodeScalar(127397 + $0.value)!) }
                .joined()
        }
        
        // Try to find a match in our mapping (case-insensitive)
        if let countryCode = countryMap[normalizedCountry] {
            return countryCode
                .unicodeScalars
                .map { String(UnicodeScalar(127397 + $0.value)!) }
                .joined()
        }
        
        // If no match found, return globe emoji
        return "🌍"
    }
    
    // Mapping from ISO 3166-1 alpha-3 to alpha-2 codes
    // Make this internal static so it can be accessed by the String extension
    internal static let alpha3ToAlpha2Map: [String: String] = [
        // European Union and Europe
        "AUT": "AT", // Austria
        "BEL": "BE", // Belgium
        "DNK": "DK", // Denmark
        "FIN": "FI", // Finland
        "FRA": "FR", // France
        "DEU": "DE", // Germany
        "GRC": "GR", // Greece
        "IRL": "IE", // Ireland
        "ITA": "IT", // Italy
        "LUX": "LU", // Luxembourg
        "NLD": "NL", // Netherlands
        "PRT": "PT", // Portugal
        "ESP": "ES", // Spain
        "SWE": "SE", // Sweden
        "CHE": "CH", // Switzerland
        "GBR": "GB", // United Kingdom
        "NOR": "NO", // Norway
        "POL": "PL", // Poland
        
        // North America
        "USA": "US", // United States
        "CAN": "CA", // Canada
        "MEX": "MX", // Mexico
        
        // Asia Pacific
        "CHN": "CN", // China
        "JPN": "JP", // Japan
        "KOR": "KR", // South Korea
        "IND": "IN", // India
        "AUS": "AU", // Australia
        "NZL": "NZ", // New Zealand
        "SGP": "SG", // Singapore
        "TWN": "TW", // Taiwan
        "IDN": "ID", // Indonesia
        "MYS": "MY", // Malaysia
        "THA": "TH", // Thailand
        "VNM": "VN", // Vietnam
        
        // Middle East
        "ISR": "IL", // Israel
        "SAU": "SA", // Saudi Arabia
        "ARE": "AE", // United Arab Emirates
        "TUR": "TR", // Turkey
        
        // South America
        "BRA": "BR", // Brazil
        "ARG": "AR", // Argentina
        "CHL": "CL", // Chile
        "COL": "CO", // Colombia
        
        // Eastern Europe & Russia
        "RUS": "RU", // Russia
        "UKR": "UA", // Ukraine
        "CZE": "CZ", // Czech Republic
        "HUN": "HU", // Hungary
        "ROU": "RO", // Romania
        
        // Africa
        "ZAF": "ZA", // South Africa
        "EGY": "EG", // Egypt
        "NGA": "NG", // Nigeria
        "MAR": "MA", // Morocco
        "KEN": "KE", // Kenya
        
        // Other Important Markets
        "HKG": "HK", // Hong Kong
        "MAC": "MO", // Macau
        "QAT": "QA", // Qatar
        "KWT": "KW", // Kuwait

        // Add more countries here if needed
        "PHL": "PH", // Philippines
        "PAK": "PK", // Pakistan
        "BGD": "BD", // Bangladesh
    ]
    
    // Country name to ISO code mapping
    private static let countryMap: [String: String] = [
        // European Union and Europe
        "AUSTRIA": "AT", "ÖSTERREICH": "AT", // 🇦🇹
        "BELGIUM": "BE", "BELGIË": "BE", "BELGIQUE": "BE", // 🇧🇪
        "DENMARK": "DK", "DANMARK": "DK", // 🇩🇰
        "FINLAND": "FI", "SUOMI": "FI", // 🇫🇮
        "FRANCE": "FR", "RÉPUBLIQUE FRANÇAISE": "FR", // 🇫🇷
        "GERMANY": "DE", "DEUTSCHLAND": "DE", // 🇩🇪
        "GREECE": "GR", "ΕΛΛΆΔΑ": "GR", "HELLAS": "GR", // 🇬🇷
        "IRELAND": "IE", "ÉIRE": "IE", // 🇮🇪
        "ITALY": "IT", "ITALIA": "IT", // 🇮🇹
        "LUXEMBOURG": "LU", // 🇱🇺
        "NETHERLANDS": "NL", "HOLLAND": "NL", "NEDERLAND": "NL", // 🇳🇱
        "PORTUGAL": "PT", // 🇵🇹
        "SPAIN": "ES", "ESPAÑA": "ES", // 🇪🇸
        "SWEDEN": "SE", "SVERIGE": "SE", // 🇸🇪
        "SWITZERLAND": "CH", "SCHWEIZ": "CH", "SUISSE": "CH", // 🇨🇭
        "UK": "GB", "UNITED KINGDOM": "GB", "GREAT BRITAIN": "GB", // 🇬🇧
        "NORWAY": "NO", "NORGE": "NO", // 🇳🇴
        "POLAND": "PL", "POLSKA": "PL", // 🇵🇱
        
        // North America
        "USA": "US", "UNITED STATES": "US", "U.S.A.": "US", "UNITED STATES OF AMERICA": "US", // 🇺🇸
        "CANADA": "CA", "CAN": "CA", // 🇨🇦
        "MEXICO": "MX", "MÉXICO": "MX", // 🇲🇽
        
        // Asia Pacific
        "CHINA": "CN", "PRC": "CN", "PEOPLES REPUBLIC OF CHINA": "CN", "中国": "CN", // 🇨🇳
        "JAPAN": "JP", "NIPPON": "JP", "日本": "JP", // 🇯🇵
        "SOUTH KOREA": "KR", "KOREA": "KR", "대한민국": "KR", // 🇰🇷
        "INDIA": "IN", "BHARAT": "IN", "भारत": "IN", // 🇮🇳
        "AUSTRALIA": "AU", // 🇦🇺
        "NEW ZEALAND": "NZ", "AOTEAROA": "NZ", // 🇳🇿
        "SINGAPORE": "SG", "新加坡": "SG", // 🇸🇬
        "TAIWAN": "TW", "CHINESE TAIPEI": "TW", "臺灣": "TW", // 🇹🇼
        "INDONESIA": "ID", // 🇮🇩
        "MALAYSIA": "MY", // 🇲🇾
        "THAILAND": "TH", "ประเทศไทย": "TH", // 🇹🇭
        "VIETNAM": "VN", "VIỆT NAM": "VN", // 🇻🇳
        
        // Middle East
        "ISRAEL": "IL", "ישראל": "IL", // 🇮🇱
        "SAUDI ARABIA": "SA", "KSA": "SA", "السعودية": "SA", // 🇸🇦
        "UAE": "AE", "UNITED ARAB EMIRATES": "AE", "الإمارات": "AE", // 🇦🇪
        "TURKEY": "TR", "TÜRKİYE": "TR", // 🇹🇷
        
        // South America
        "BRAZIL": "BR", "BRASIL": "BR", // 🇧🇷
        "ARGENTINA": "AR", // 🇦🇷
        "CHILE": "CL", // 🇨🇱
        "COLOMBIA": "CO", // 🇨🇴
        
        // Eastern Europe & Russia
        "RUSSIA": "RU", "RUSSIAN FEDERATION": "RU", "РОССИЯ": "RU", // 🇷🇺
        "UKRAINE": "UA", "УКРАЇНА": "UA", // 🇺🇦
        "CZECH REPUBLIC": "CZ", "CZECHIA": "CZ", "ČESKO": "CZ", // 🇨🇿
        "HUNGARY": "HU", "MAGYARORSZÁG": "HU", // 🇭🇺
        "ROMANIA": "RO", "ROMÂNIA": "RO", // 🇷🇴
        
        // Africa
        "SOUTH AFRICA": "ZA", "RSA": "ZA", // 🇿🇦
        "EGYPT": "EG", "مصر": "EG", // 🇪🇬
        "NIGERIA": "NG", // 🇳🇬
        "MOROCCO": "MA", "MAROC": "MA", "المغرب": "MA", // 🇲🇦
        "KENYA": "KE", // 🇰🇪
        
        // Other Important Markets
        "HONG KONG": "HK", "香港": "HK", // 🇭🇰
        "MACAU": "MO", "澳門": "MO", // 🇲🇴
        "QATAR": "QA", "قطر": "QA", // 🇶🇦
        "KUWAIT": "KW", "الكويت": "KW", // 🇰🇼

        // Add more countries here if needed
        "PHL": "PH", // Philippines
        "PAK": "PK", // Pakistan
        "BGD": "BD", // Bangladesh
    ]
    
    // Converts an ISO 3166-1 alpha-3 country code string to its localized full name.
    /// Uses the alpha3ToAlpha2Map within this utility.
    /// - Parameter code: The Alpha-3 country code.
    /// - Returns: The localized country name, or the original code if conversion fails.
    static func localizedName(forAlpha3Code code: String?) -> String {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines), code.count == 3 else {
            return code ?? "Unknown Country" // Return original or default if input is invalid
        }
        let alpha3Upper = code.uppercased()

        // Convert alpha-3 to alpha-2 using the map from CountryFlagUtility
        guard let alpha2Code = alpha3ToAlpha2Map[alpha3Upper] else {
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
}
