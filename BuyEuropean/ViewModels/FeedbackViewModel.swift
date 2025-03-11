//
//  FeedbackViewModel.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import Foundation
import Combine

class FeedbackViewModel: ObservableObject {
    // Feedback data
    @Published var feedbackData: FeedbackModel
    
    // UI state
    @Published var isSubmitting = false
    @Published var isSubmitted = false
    @Published var error: String? = nil
    @Published var showDetailedFeedback = false
    
    private let apiService = APIService.shared
    
    init(analysisId: String, initialPositive: Bool = true) {
        self.feedbackData = FeedbackModel(analysisId: analysisId, isPositive: initialPositive)
    }
    
    func toggleFeedbackType(isPositive: Bool) {
        feedbackData.isPositive = isPositive
        
        // If positive feedback, auto-submit without showing detailed form
        if isPositive {
            submitFeedback()
        } else {
            showDetailedFeedback = true
        }
    }
    
    func submitFeedback() {
        isSubmitting = true
        error = nil
        
        // Format the analysis ID for submission
        let formattedAnalysisId: String
        if let numericId = Int(feedbackData.analysisId) {
            formattedAnalysisId = String(numericId)
        } else if let numericMatch = feedbackData.analysisId.range(of: #"\d+"#, options: .regularExpression) {
            formattedAnalysisId = String(feedbackData.analysisId[numericMatch])
        } else {
            // Fallback to a hash of the string if no numeric part
            let hashValue = abs(feedbackData.analysisId.hash % 1000000)
            formattedAnalysisId = String(hashValue)
        }
        
        // Create a copy of the feedback data with the formatted ID
        var submissionData = feedbackData
        submissionData.analysisId = formattedAnalysisId
        
        Task {
            do {
                try await apiService.submitFeedback(feedback: submissionData)
                
                await MainActor.run {
                    self.isSubmitting = false
                    self.isSubmitted = true
                    
                    // Reset form after 3 seconds if still showing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if self.isSubmitted {
                            self.resetForm()
                        }
                    }
                }
            } catch let apiError as APIError {
                await MainActor.run {
                    self.isSubmitting = false
                    self.error = apiError.message
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func resetForm() {
        isSubmitted = false
        showDetailedFeedback = false
        error = nil
        feedbackData = FeedbackModel(analysisId: feedbackData.analysisId, isPositive: true)
    }
}
