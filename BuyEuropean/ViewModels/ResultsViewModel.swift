//
//  ResultsViewModel.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI
import Combine
import UIKit

class ResultsViewModel: ObservableObject {
    // Data
    private let response: BuyEuropeanResponse
    
    // UI state
    @Published var showFeedback = false
    @Published var isAnimating = false
    
    // Generated ID for feedback
    let analysisId: String
    
    init(response: BuyEuropeanResponse) {
        self.response = response
        
        // Generate a unique ID for this analysis result
        self.analysisId = UUID().uuidString
        print("Initialized ResultsViewModel. Classification: \(response.classification?.rawValue ?? "nil")") // Debug print
    }
    
    // MARK: - Computed Properties for View
    
    // Safely unwrapped classification or default
    var displayClassification: Classification {
        response.classification ?? .unknown
    }
    
    // Get the style for the current classification
    var classificationStyle: ClassificationStyle {
        ClassificationStyle.forClassification(displayClassification)
    }
    
    // Check if classification suggests a typical product/company analysis
    var isProductAnalysis: Bool {
        switch displayClassification {
        case .europeanCountry, .europeanAlly, .europeanSceptic, .europeanAdversary, .neutral:
            return true
        // Consider .unknown as non-product for display purposes unless specified otherwise
        case .cat, .dog, .animal, .human, .unknown:
            return false
        }
    }
    
    // Product details with defaults
    var productName: String { response.identifiedProductName ?? "N/A" }
    var companyName: String { response.identifiedCompany ?? "N/A" }
    var headquartersCountry: String { response.identifiedHeadquarters ?? "N/A" }
    var parentCompany: String? { response.ultimateParentCompany }
    var parentCompanyHeadquarters: String? { response.ultimateParentCompanyHeadquarters }
    var identificationRationale: String { response.identificationRationale ?? "No rationale provided." }
    var rawCountryDisplay: String { response.rawCountry ?? "N/A" } // Raw country from analysis
    
    // Alternatives logic, handling nil classification
    var shouldShowAlternatives: Bool {
        // Only show alternatives if it's a product analysis and alternatives exist
        guard isProductAnalysis, let alternatives = response.potentialAlternatives else {
            return false
        }
        return !alternatives.isEmpty
    }
    
    var alternatives: [EuropeanAlternative] {
        response.potentialAlternatives ?? [] // Return empty array if nil
    }
    
    // Other fields potentially useful for display or debugging
    var thinking: String? { response.thinking }
    var potentialAlternativeThinking: String? { response.potentialAlternativeThinking }
    var potentialAlternativeSingular: String? { response.potentialAlternative } // The singular alternative suggestion
    var inputTokens: Int? { response.inputTokens }
    var outputTokens: Int? { response.outputTokens }
    var totalTokens: Int? { response.totalTokens }
    
    // Get the country flag emoji
    func countryFlag(for country: String?) -> String {
        CountryFlagUtility.countryToFlag(country)
    }
    
    // Open web search for an alternative
    func openWebSearch(for alternative: EuropeanAlternative) {
        let searchQuery = "\(alternative.productName) \(alternative.company)"
        if let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://www.google.com/search?q=\(encodedQuery)") {
            UIApplication.shared.open(url)
        }
    }
    
    // Toggle feedback form visibility
    func toggleFeedback() {
        withAnimation {
            showFeedback.toggle()
        }
    }
}
