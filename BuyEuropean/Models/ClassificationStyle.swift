//
//  ClassificationStyle.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI
import Foundation

// Referencing the Classification enum from Models.swift
// We don't need to import it since they're in the same module
// But we need to access it correctly

struct ClassificationStyle {
    // Light mode colors
    let lightBackgroundColor: Color
    let lightTextColor: Color
    let lightBadgeColor: Color
    
    // Dark mode colors
    let darkBackgroundColor: Color
    let darkTextColor: Color
    let darkBadgeColor: Color
    
    let icon: String
    let title: String
    let description: String
    
    // Computed properties to get the right color based on color scheme
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? darkBackgroundColor : lightBackgroundColor
    }
    
    func textColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? darkTextColor : lightTextColor
    }
    
    func badgeColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? darkBadgeColor : lightBadgeColor
    }
    
    // For backward compatibility with existing code
    var backgroundColor: Color {
        lightBackgroundColor
    }
    
    var textColor: Color {
        lightTextColor
    }
    
    var badgeColor: Color {
        lightBadgeColor
    }
    
    static func forClassification(_ classification: Classification) -> ClassificationStyle {
        switch classification {
        case .europeanCountry:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 235/255, green: 242/255, blue: 255/255),
                lightTextColor: Color(red: 0/255, green: 51/255, blue: 153/255),
                lightBadgeColor: Color(red: 0/255, green: 51/255, blue: 153/255),
                darkBackgroundColor: Color(red: 13/255, green: 37/255, blue: 76/255),
                darkTextColor: Color(red: 114/255, green: 160/255, blue: 250/255),
                darkBadgeColor: Color(red: 65/255, green: 117/255, blue: 224/255),
                icon: "flag.fill",
                title: "European",
                description: "This product is made by a company headquartered in Europe."
            )
        case .europeanAlly:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 240/255, green: 247/255, blue: 255/255),
                lightTextColor: Color(red: 41/255, green: 112/255, blue: 219/255),
                lightBadgeColor: Color(red: 51/255, green: 131/255, blue: 255/255),
                darkBackgroundColor: Color(red: 21/255, green: 43/255, blue: 77/255),
                darkTextColor: Color(red: 99/255, green: 166/255, blue: 255/255),
                darkBadgeColor: Color(red: 79/255, green: 156/255, blue: 255/255),
                icon: "hand.thumbsup.fill",
                title: "European Ally",
                description: "This product is made by a company from a country allied with Europe."
            )
        case .europeanSceptic:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 255/255, green: 244/255, blue: 235/255),
                lightTextColor: Color(red: 230/255, green: 106/255, blue: 46/255),
                lightBadgeColor: Color(red: 255/255, green: 119/255, blue: 51/255),
                darkBackgroundColor: Color(red: 77/255, green: 43/255, blue: 21/255),
                darkTextColor: Color(red: 255/255, green: 156/255, blue: 107/255),
                darkBadgeColor: Color(red: 255/255, green: 146/255, blue: 89/255),
                icon: "exclamationmark.triangle.fill",
                title: "European Sceptic",
                description: "This product is made by a company from a country with skeptical relations to Europe."
            )
        case .europeanAdversary:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 255/255, green: 245/255, blue: 245/255),
                lightTextColor: Color(red: 197/255, green: 48/255, blue: 48/255),
                lightBadgeColor: Color(red: 229/255, green: 62/255, blue: 62/255),
                darkBackgroundColor: Color(red: 77/255, green: 28/255, blue: 28/255),
                darkTextColor: Color(red: 254/255, green: 118/255, blue: 118/255),
                darkBadgeColor: Color(red: 239/255, green: 87/255, blue: 87/255),
                icon: "xmark.octagon.fill",
                title: "European Adversary",
                description: "This product is made by a company from a country with adversarial relations to Europe."
            )
        case .neutral:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 240/255, green: 240/255, blue: 240/255),
                lightTextColor: Color(red: 100/255, green: 100/255, blue: 100/255),
                lightBadgeColor: Color(red: 150/255, green: 150/255, blue: 150/255),
                darkBackgroundColor: Color(red: 55/255, green: 55/255, blue: 55/255),
                darkTextColor: Color(red: 180/255, green: 180/255, blue: 180/255),
                darkBadgeColor: Color(red: 130/255, green: 130/255, blue: 130/255),
                icon: "equal.circle.fill",
                title: "Neutral",
                description: "This product is made by a company from a country with neutral standing to Europe."
            )
        case .cat:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 255/255, green: 240/255, blue: 220/255),
                lightTextColor: Color(red: 217/255, green: 115/255, blue: 13/255),
                lightBadgeColor: Color(red: 245/255, green: 158/255, blue: 11/255),
                darkBackgroundColor: Color(red: 77/255, green: 50/255, blue: 20/255),
                darkTextColor: Color(red: 255/255, green: 177/255, blue: 100/255),
                darkBadgeColor: Color(red: 255/255, green: 170/255, blue: 51/255),
                icon: "cat.fill",
                title: "Cat",
                description: ""
            )
        case .dog:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 252/255, green: 237/255, blue: 222/255),
                lightTextColor: Color(red: 180/255, green: 83/255, blue: 9/255),
                lightBadgeColor: Color(red: 217/255, green: 119/255, blue: 6/255),
                darkBackgroundColor: Color(red: 70/255, green: 45/255, blue: 20/255),
                darkTextColor: Color(red: 245/255, green: 158/255, blue: 90/255),
                darkBadgeColor: Color(red: 245/255, green: 146/255, blue: 46/255),
                icon: "dog.fill",
                title: "Dog",
                description: ""
            )
        case .animal:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 228/255, green: 250/255, blue: 241/255),
                lightTextColor: Color(red: 6/255, green: 148/255, blue: 100/255),
                lightBadgeColor: Color(red: 16/255, green: 185/255, blue: 129/255),
                darkBackgroundColor: Color(red: 22/255, green: 60/255, blue: 46/255),
                darkTextColor: Color(red: 95/255, green: 210/255, blue: 170/255),
                darkBadgeColor: Color(red: 52/255, green: 211/255, blue: 158/255),
                icon: "hare.fill",
                title: "Animal",
                description: ""
            )
        case .human:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 249/255, green: 240/255, blue: 255/255),
                lightTextColor: Color(red: 159/255, green: 18/255, blue: 237/255),
                lightBadgeColor: Color(red: 168/255, green: 85/255, blue: 247/255),
                darkBackgroundColor: Color(red: 60/255, green: 25/255, blue: 77/255),
                darkTextColor: Color(red: 205/255, green: 132/255, blue: 250/255),
                darkBadgeColor: Color(red: 190/255, green: 124/255, blue: 255/255),
                icon: "person.fill",
                title: "Human",
                description: ""
            )
        case .unknown:
            return ClassificationStyle(
                lightBackgroundColor: Color(red: 243/255, green: 244/255, blue: 246/255),
                lightTextColor: Color(red: 107/255, green: 114/255, blue: 128/255),
                lightBadgeColor: Color(red: 156/255, green: 163/255, blue: 175/255),
                darkBackgroundColor: Color(red: 50/255, green: 50/255, blue: 54/255),
                darkTextColor: Color(red: 176/255, green: 180/255, blue: 189/255),
                darkBadgeColor: Color(red: 166/255, green: 173/255, blue: 187/255),
                icon: "questionmark.circle.fill",
                title: "Unknown Origin",
                description: "This product's origin could not be determined with confidence."
            )
        }
    }
}
