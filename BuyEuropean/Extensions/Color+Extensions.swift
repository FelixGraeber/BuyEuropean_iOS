import SwiftUI

extension Color {
    // Brand Colors - Removed, use Color("AssetName") directly
    // static let brandPrimary = Color("BrandPrimary")
    // static let brandSecondary = Color("BrandSecondary")
    // static let brandAccent = Color("BrandAccent")
    
    // Interface Colors - Removed, use Color("AssetName") directly
    // static let cardBackground = Color("CardBackground")
    // static let inputBackground = Color("InputBackground")
    // static let inputBorder = Color("InputBorder")
    
    // Helper for getting adaptive colors (Can be kept or removed if unused)
    static func adaptiveColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
