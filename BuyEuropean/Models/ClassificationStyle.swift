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
    let backgroundColor: Color
    let textColor: Color
    let badgeColor: Color
    let icon: String
    let title: String
    let description: String
    
    static func forClassification(_ classification: Classification) -> ClassificationStyle {
        switch classification {
        case .europeanCountry:
            return ClassificationStyle(
                backgroundColor: Color(red: 235/255, green: 242/255, blue: 255/255),
                textColor: Color(red: 0/255, green: 51/255, blue: 153/255),
                badgeColor: Color(red: 0/255, green: 51/255, blue: 153/255),
                icon: "flag.fill",
                title: "European",
                description: "This product is made by a company headquartered in Europe."
            )
        case .europeanAlly:
            return ClassificationStyle(
                backgroundColor: Color(red: 240/255, green: 247/255, blue: 255/255),
                textColor: Color(red: 41/255, green: 112/255, blue: 219/255),
                badgeColor: Color(red: 51/255, green: 131/255, blue: 255/255),
                icon: "hand.thumbsup.fill",
                title: "European Ally",
                description: "This product is made by a company from a country allied with Europe."
            )
        case .europeanSceptic:
            return ClassificationStyle(
                backgroundColor: Color(red: 255/255, green: 244/255, blue: 235/255),
                textColor: Color(red: 230/255, green: 106/255, blue: 46/255),
                badgeColor: Color(red: 255/255, green: 119/255, blue: 51/255),
                icon: "exclamationmark.triangle.fill",
                title: "European Sceptic",
                description: "This product is made by a company from a country with skeptical relations to Europe."
            )
        case .europeanAdversary:
            return ClassificationStyle(
                backgroundColor: Color(red: 255/255, green: 245/255, blue: 245/255),
                textColor: Color(red: 197/255, green: 48/255, blue: 48/255),
                badgeColor: Color(red: 229/255, green: 62/255, blue: 62/255),
                icon: "xmark.octagon.fill",
                title: "European Adversary",
                description: "This product is made by a company from a country with adversarial relations to Europe."
            )
        case .neutral:
            return ClassificationStyle(
                backgroundColor: Color(red: 240/255, green: 240/255, blue: 240/255),
                textColor: Color(red: 100/255, green: 100/255, blue: 100/255),
                badgeColor: Color(red: 150/255, green: 150/255, blue: 150/255),
                icon: "equal.circle.fill",
                title: "Neutral",
                description: "This product is made by a company from a country with neutral standing to Europe."
            )
        case .cat:
            return ClassificationStyle(
                backgroundColor: Color(red: 255/255, green: 240/255, blue: 220/255),
                textColor: Color(red: 217/255, green: 115/255, blue: 13/255),
                badgeColor: Color(red: 245/255, green: 158/255, blue: 11/255),
                icon: "cat.fill",
                title: "Cat",
                description: ""
            )
        case .dog:
            return ClassificationStyle(
                backgroundColor: Color(red: 252/255, green: 237/255, blue: 222/255),
                textColor: Color(red: 180/255, green: 83/255, blue: 9/255),
                badgeColor: Color(red: 217/255, green: 119/255, blue: 6/255),
                icon: "dog.fill",
                title: "Dog",
                description: ""
            )
        case .animal:
            return ClassificationStyle(
                backgroundColor: Color(red: 228/255, green: 250/255, blue: 241/255),
                textColor: Color(red: 6/255, green: 148/255, blue: 100/255),
                badgeColor: Color(red: 16/255, green: 185/255, blue: 129/255),
                icon: "hare.fill",
                title: "Animal",
                description: ""
            )
        case .human:
            return ClassificationStyle(
                backgroundColor: Color(red: 249/255, green: 240/255, blue: 255/255),
                textColor: Color(red: 159/255, green: 18/255, blue: 237/255),
                badgeColor: Color(red: 168/255, green: 85/255, blue: 247/255),
                icon: "person.fill",
                title: "Human",
                description: ""
            )
        case .unknown:
            return ClassificationStyle(
                backgroundColor: Color(red: 243/255, green: 244/255, blue: 246/255),
                textColor: Color(red: 107/255, green: 114/255, blue: 128/255),
                badgeColor: Color(red: 156/255, green: 163/255, blue: 175/255),
                icon: "questionmark.circle.fill",
                title: "Unknown Origin",
                description: "This product's origin could not be determined with confidence."
            )
        }
    }
}
