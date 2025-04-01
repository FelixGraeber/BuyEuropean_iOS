//
//  FeedbackViewModel.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import Foundation
import Combine
import UIKit // Import UIKit for UIImage

@MainActor
class FeedbackViewModel: ObservableObject, @unchecked Sendable {
    // Feedback data
    @Published var feedbackData: FeedbackModel
    let analysisImage: UIImage? // Add property to hold the optional image
    
    // UI state
    @Published var isSubmitting = false
    @Published var isSubmitted = false
    @Published var error: String? = nil
    @Published var showDetailedFeedback = false
    
    private let apiService = APIService.shared
    
    init(analysisId: String, initialPositive: Bool = true, analysisImage: UIImage? = nil) {
        self.feedbackData = FeedbackModel(analysisId: analysisId, isPositive: initialPositive)
        self.analysisImage = analysisImage // Initialize the image property
    }
    
    func toggleFeedbackType(isPositive: Bool) {
        feedbackData.isPositive = isPositive
        
        // If positive feedback, auto-submit without showing detailed form
        if isPositive {
            // Pass false for consent since the detailed form is skipped
            submitFeedback(sharePhotoConsent: false)
        } else {
            showDetailedFeedback = true
        }
    }
    
    func submitFeedback(sharePhotoConsent: Bool) {
        // Reset base64 field before potential assignment
        feedbackData.imageData = nil
        
        // Check for consent and image existence using the passed parameter
        if sharePhotoConsent, let image = analysisImage {
            print("Consent given, attempting to convert image to base64.")
            // Convert UIImage to Data (e.g., JPEG with compression)
            // Use a reasonable compression quality (0.0 = max compression, 1.0 = least)
            if let imageData = image.jpegData(compressionQuality: 0.7) {
                // Encode Data to base64 String
                let base64String = imageData.base64EncodedString()
                feedbackData.imageData = base64String
                print("Successfully added base64 image data to feedback.")
            } else {
                print("Warning: Could not convert analysis image to JPEG data.")
            }
        } else {
             print("Photo not shared. Consent: \(sharePhotoConsent), Image exists: \(analysisImage != nil)")
        }
        
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                        guard let self = self else { return }
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
        // Reset feedbackData, but keep the analysisId and potentially the image reference
        feedbackData = FeedbackModel(analysisId: feedbackData.analysisId, isPositive: true) 
        // Note: We are NOT resetting the analysisImage here, it stays the same for this feedback session.
    }
}
