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
        
        // Use the analysis ID directly without any formatting
        // The ID is already properly formatted from ResultsView
        
        Task {
            do {
                try await apiService.submitFeedback(feedback: feedbackData)
                
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
