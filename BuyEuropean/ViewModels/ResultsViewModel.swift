//
//  ResultsViewModel.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI
import Combine
import UIKit

// Assume Models and Utilities are available globally or via target membership
// import Models
// import Utilities 

class ResultsViewModel: ObservableObject {
    // Data
    private let response: BuyEuropeanResponse
    let analysisImage: UIImage?
    
    // UI state
    @Published var showFeedback = false
    @Published var isAnimating = false
    
    // Generated ID for feedback
    let analysisId: String
    
    // --- FEEDBACK TRACKING ---
    @Published var submittedFeedbackIds: Set<Int> = {
        if let saved = UserDefaults.standard.array(forKey: "SubmittedFeedbackIds") as? [Int] {
            return Set(saved)
        }
        return []
    }()

    func markFeedbackSubmitted(for analysisId: Int) {
        submittedFeedbackIds.insert(analysisId)
        UserDefaults.standard.set(Array(submittedFeedbackIds), forKey: "SubmittedFeedbackIds")
    }

    func hasSubmittedFeedback(for analysisId: Int) -> Bool {
        submittedFeedbackIds.contains(analysisId)
    }
    
    @Published var translatedIdentificationRationale: String? = nil
    @Published var isTranslatingIdentificationRationale: Bool = false
    @Published var translatedAlternativeDescriptions: [UUID: String] = [:]
    @Published var isTranslatingAlternatives: Set<UUID> = []
    private let translationService = TranslationService()
    private let systemLanguageCode: String = Locale.current.language.languageCode?.identifier ?? "en"
    
    init(response: BuyEuropeanResponse, analysisImage: UIImage?) {
        self.response = response
        self.analysisImage = analysisImage
        
        // Generate a unique ID for this analysis result
        self.analysisId = UUID().uuidString
        print("Initialized ResultsViewModel. Classification: \(response.classification.rawValue)") // Debug print
        // --- TRANSLATION LOGIC ---
        if systemLanguageCode != "en" {
            translateIdentificationRationale()
            translateAlternativesDescriptions()
        }
    }
    
    // MARK: - Computed Properties for View
    
    // Safely unwrapped classification or default
    var displayClassification: Classification {
        response.classification
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
    var productName: String { response.identifiedProductName }
    var companyName: String { response.identifiedCompany ?? "N/A" }
    var headquartersCountry: String { response.identifiedCompanyHeadquarters ?? "N/A" }
    var parentCompany: String? { response.ultimateParentCompany }
    var parentCompanyHeadquarters: String? { response.ultimateParentCompanyHeadquarters }
    var identificationRationale: String { response.identificationRationale }
    
    // Computed property to determine if parent company info should be shown
    var shouldShowParentCompany: Bool {
        guard let parent = parentCompany, !parent.isEmpty else { return false }
        // Show if parent company exists and is different from the identified company
        return parent != companyName
    }
    
    // Computed property for the parent company headquarters flag
    var parentCompanyFlag: String {
        countryFlag(for: parentCompanyHeadquarters)
    }
    
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
           let url = URL(string: "https://www.qwant.com/?q=\(encodedQuery)") {
            UIApplication.shared.open(url)
        }
    }
    
    // Toggle feedback form visibility
    func toggleFeedback() {
        withAnimation {
            showFeedback.toggle()
        }
    }
    
    private func translateIdentificationRationale() {
        isTranslatingIdentificationRationale = true
        Task {
            let translated = await translationService.translate(text: response.identificationRationale, to: Locale.current)
            await MainActor.run {
                self.translatedIdentificationRationale = translated
                self.isTranslatingIdentificationRationale = false
            }
        }
    }
    
    private func translateAlternativesDescriptions() {
        for alt in alternatives {
            isTranslatingAlternatives.insert(alt.id)
            Task {
                let translated = await translationService.translate(text: alt.description, to: Locale.current)
                await MainActor.run {
                    if let translated = translated {
                        self.translatedAlternativeDescriptions[alt.id] = translated
                    }
                    self.isTranslatingAlternatives.remove(alt.id)
                }
            }
        }
    }
    
    func translatedDescription(for alternative: EuropeanAlternative) -> String? {
        translatedAlternativeDescriptions[alternative.id]
    }
    
    func isTranslatingAlternative(_ alternative: EuropeanAlternative) -> Bool {
        isTranslatingAlternatives.contains(alternative.id)
    }
}
