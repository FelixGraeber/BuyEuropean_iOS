//
//  FeedbackViewModel.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import Foundation
import Combine
import UIKit // Import UIKit for UIImage
import StoreKit // Import StoreKit for SKStoreReviewController

// MARK: - UIImage Extension for Resizing
extension UIImage {
    /// Resizes the image so its longest side matches the given length, preserving aspect ratio.
    /// - Parameter maxLength: The maximum desired length for the longest side of the image.
    /// - Returns: A new resized UIImage instance, or nil if resizing fails.
    func resized(toLongestSide maxLength: CGFloat) -> UIImage? {
        let currentSize = self.size
        // Ensure valid size and maxLength
        guard currentSize.width > 0, currentSize.height > 0, maxLength > 0 else {
             print("Warning: Cannot resize image with zero dimensions or zero maxLength.")
             return nil
        }

        let aspectRatio = currentSize.width / currentSize.height
        var newSize: CGSize

        if currentSize.width > currentSize.height {
            // Width is longest
            let newWidth = min(currentSize.width, maxLength) // Don't scale up
            let newHeight = newWidth / aspectRatio
            newSize = CGSize(width: newWidth, height: newHeight)
        } else {
            // Height is longest (or sides are equal)
            let newHeight = min(currentSize.height, maxLength) // Don't scale up
            let newWidth = newHeight * aspectRatio
            newSize = CGSize(width: newWidth, height: newHeight)
        }

        // Ensure dimensions are at least 1x1 pixel
        newSize.width = max(1, round(newSize.width))
        newSize.height = max(1, round(newSize.height))

        // Use UIGraphicsImageRenderer for high-quality rendering
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        print("Image resized from \(currentSize) to \(newSize)")
        return resizedImage
    }
}

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
    @Published var showRatingPrompt: Bool = false
    @Published var sharePhotoConsent: Bool = false
    
    private let hasRatedOrSharedKey = "hasRatedOrSharedApp"
    
    // Helper to check if user has rated/shared
    var hasRatedOrSharedApp: Bool {
        UserDefaults.standard.bool(forKey: hasRatedOrSharedKey)
    }
    
    var canSharePhoto: Bool { analysisImage != nil }
    
    // Call this after a successful positive feedback submission
    func promptForRatingIfNeeded() {
        if !hasRatedOrSharedApp {
            // Get the current foreground scene
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                print("Could not find active scene to request review.")
                return // Cannot request review without a scene
            }

            // Use the new API
            SKStoreReviewController.requestReview(in: scene)

            setHasRatedOrSharedApp()
        }
    }
    
    // Call this after user rates or shares
    func setHasRatedOrSharedApp() {
        UserDefaults.standard.set(true, forKey: hasRatedOrSharedKey)
        showRatingPrompt = false
    }
    
    private let apiService = APIService.shared
    
    // --- FEEDBACK SUBMISSION CALLBACKS ---
    var markFeedbackSubmittedCallback: ((Int) -> Void)?
    var hasSubmittedFeedbackCallback: ((Int) -> Bool)?
    var analysisId: Int { feedbackData.analysisId }
    var hasSubmittedFeedback: Bool {
        hasSubmittedFeedbackCallback?(analysisId) ?? false
    }
    
    init(initialPositive: Bool = true, analysisImage: UIImage? = nil) {
        // Generate a random integer ID for feedback
        let randomId = Int.random(in: 1_000_000...9_999_999) // Example range for a random ID
        self.feedbackData = FeedbackModel(analysisId: randomId, isPositive: initialPositive)
        self.analysisImage = analysisImage // Initialize the image property
    }
    
    func toggleFeedbackType(isPositive: Bool) {
        feedbackData.isPositive = isPositive
        
        // If positive feedback, auto-submit without showing detailed form
        if isPositive {
            // Pass false for consent since the detailed form is skipped
            submitFeedback(sharePhotoConsent: sharePhotoConsent)
            promptForRatingIfNeeded()
        } else {
            showDetailedFeedback = true
        }
    }
    
    func submitFeedback() {
        submitFeedback(sharePhotoConsent: sharePhotoConsent)
    }
    
    func submitFeedback(sharePhotoConsent: Bool) {
        // Reset base64 field before potential assignment
        feedbackData.imageData = nil
        
        // Check for consent and image existence using the passed parameter
        if sharePhotoConsent, let image = analysisImage {
            print("Consent given. Attempting to resize and convert image.")
            
            // 1. Resize the image
            if let resizedImage = image.resized(toLongestSide: 420.0) {
                // 2. Convert RESIZED UIImage to Data (JPEG with compression)
                // Use a reasonable compression quality (0.0 = max compression, 1.0 = least)
                if let imageData = resizedImage.jpegData(compressionQuality: 0.7) {
                    // 3. Encode Data to base64 String
                    let base64String = imageData.base64EncodedString()
                    feedbackData.imageData = base64String
                    print("Successfully added resized base64 image data to feedback.")
                } else {
                    print("Warning: Could not convert *resized* analysis image to JPEG data.")
                    // Optionally handle this error, e.g., inform the user or proceed without image
                }
            } else {
                 print("Warning: Failed to resize analysis image. Proceeding without image data.")
                 // Optionally handle this error
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
                    // Mark feedback as submitted for this analysisId
                    self.markFeedbackSubmittedCallback?(self.analysisId)
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
}
