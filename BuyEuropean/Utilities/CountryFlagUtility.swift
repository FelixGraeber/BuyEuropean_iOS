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
    ]
}
