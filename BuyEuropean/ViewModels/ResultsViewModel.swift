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
    }
    
    // Get the style for the current classification
    var classificationStyle: ClassificationStyle {
        ClassificationStyle.forClassification(response.classification)
    }
    
    // Determine if alternatives should be shown
    var shouldShowAlternatives: Bool {
        response.classification != .europeanCountry &&
        (response.potentialAlternatives != nil && !(response.potentialAlternatives?.isEmpty ?? true) || 
         !response.potentialAlternative.isEmpty)
    }
    
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
