//
//  ResultsViewModel.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI
import Combine

class ResultsViewModel: ObservableObject {
    // Data
    private let response: BuyEuropeanResponse
    
    // UI state
    @Published var showShareOptions = false
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
    
    // Share the result via system share sheet
    func shareResult() -> UIActivityViewController {
        // Create text to share
        let shareText = """
        Product Analysis Results:
        
        Product: \(response.identifiedProductName)
        Company: \(response.identifiedCompany)
        Headquarters: \(response.identifiedHeadquarters)
        Classification: \(response.classification.displayName)
        
        Analyzed with BuyEuropean app
        """
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        return activityViewController
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
    
    // Toggle share options visibility
    func toggleShareOptions() {
        withAnimation {
            showShareOptions.toggle()
        }
    }
}
