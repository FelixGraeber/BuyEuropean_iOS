//
//  Models.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import Foundation
import SwiftUI

enum Classification: String, Codable {
    case europeanCountry = "european_country"
    case europeanAlly = "european_ally"
    case europeanSceptic = "european_sceptic"
    case europeanAdversary = "european_adversary"
    case neutral = "neutral"
    case cat = "cat"
    case dog = "dog"
    case animal = "animal"
    case human = "human"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .europeanCountry:
            return "European Country"
        case .europeanAlly:
            return "European Ally"
        case .europeanSceptic:
            return "European Sceptic"
        case .europeanAdversary:
            return "European Adversary"
        case .neutral:
            return "Neutral"
        case .cat:
            return "Cat"
        case .dog:
            return "Dog"
        case .animal:
            return "Animal"
        case .human:
            return "Human"
        case .unknown:
            return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .europeanCountry:
            return .green
        case .europeanAlly:
            return .blue
        case .europeanSceptic:
            return .yellow
        case .europeanAdversary:
            return .red
        case .neutral:
            return .gray.opacity(0.7)
        case .cat:
            return .orange
        case .dog:
            return .brown
        case .animal:
            return .mint
        case .human:
            return .purple
        case .unknown:
            return .gray
        }
    }
}

// New enum for product_or_animal_or_human field
enum ObjectType: String, Codable, Equatable {
    case product = "product"
    case animal = "animal"
    case human = "human"
}

struct EuropeanAlternative: Identifiable, Codable, Equatable {
    var id = UUID() // For SwiftUI list identification
    let productName: String
    let company: String
    let description: String
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case company
        case description
        case country
    }
}

struct BuyEuropeanResponse: Codable, Equatable {
    let id: Int // Changed from Int?
    let thinking: String // Changed from String?
    let identifiedProductName: String // Changed from String?
    let identifiedCompany: String?
    let identifiedCompanyHeadquarters: String? // Renamed from identifiedHeadquarters, maps to identified_company_headquarters
    let ultimateParentCompany: String?
    let ultimateParentCompanyHeadquarters: String?
    let identificationRationale: String // Changed from String?
    let productOrAnimalOrHuman: ObjectType // Added new field
    let classification: Classification // Changed from Classification?
    let potentialAlternativeThinking: String?
    let potentialAlternatives: [EuropeanAlternative]? // potentialAlternative removed
    let inputTokens: Int // Changed from Int?
    let outputTokens: Int // Changed from Int?
    let totalTokens: Int // Changed from Int?
    
    // rawCountry removed
    
    enum CodingKeys: String, CodingKey {
        case id
        case thinking
        case identifiedProductName = "identified_product_name"
        case identifiedCompany = "identified_company"
        case identifiedCompanyHeadquarters = "identified_company_headquarters" // Renamed from identifiedHeadquarters
        case ultimateParentCompany = "ultimate_parent_company"
        case ultimateParentCompanyHeadquarters = "ultimate_parent_company_headquarters"
        case identificationRationale = "identification_rationale"
        case productOrAnimalOrHuman = "product_or_animal_or_human" // Added
        // rawCountry removed
        case classification
        case potentialAlternativeThinking = "potential_alternative_thinking"
        // potentialAlternative removed
        case potentialAlternatives = "potential_alternatives"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
    }
}

struct AnalyzeProductRequest: Codable {
    let image: String // Base64-encoded image
    let prompt: String? // Optional additional prompt
    let userLocation: UserLocation? // Add optional user location
}

struct UserLocation: Codable {
    let city: String
    let country: String
}

struct AnalyzeTextRequest: Codable {
    let product_text: String
    let prompt: String?
    let userLocation: UserLocation?
}
