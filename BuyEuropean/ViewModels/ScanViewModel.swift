//
//  ScanViewModel.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

// Import our models and services
@_implementationOnly import Foundation

// Forward declaration of BuyEuropeanResponse to resolve circular dependency
// The actual type is defined in Models.swift
enum ScanState: Equatable {
    case ready
    case scanning
    case backgroundScanning
    case result(BuyEuropeanResponse)
    case error(String)
    
    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready),
             (.scanning, .scanning),
             (.backgroundScanning, .backgroundScanning):
            return true
        case let (.result(lhsResponse), .result(rhsResponse)):
            return lhsResponse == rhsResponse
        case let (.error(lhsError), .error(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

@MainActor
class ScanViewModel: ObservableObject, @unchecked Sendable {
    @Published var capturedImage: UIImage?
    @Published var scanState: ScanState = .ready
    @Published var showCamera = false
    @Published var showPhotoLibrary = false
    @Published var errorMessage: String?
    @Published var showPermissionRequest = false
    
    private let apiService = APIService.shared
    private let imageService = ImageService.shared
    private let permissionService = PermissionService.shared
    
    // Task to keep track of background processing
    private var backgroundAnalysisTask: Task<Void, Never>?
    
    // Store the analysis result for immediate access
    private var cachedAnalysisResult: BuyEuropeanResponse?
    
    init() {
        checkCameraPermission()
    }
    
    func checkCameraPermission() {
        if permissionService.shouldShowPermissionPrompt {
            showPermissionRequest = true
        }
    }
    
    func requestCameraPermission() async -> Bool {
        return await permissionService.requestCameraPermission()
    }
    
    func handleCameraButtonTap(cameraService: CameraService? = nil) {
        if let cameraService = cameraService {
            // Take photo from live preview
            cameraService.capturePhoto { [weak self] result in
                switch result {
                case .success(let image):
                    DispatchQueue.main.async {
                        self?.capturedImage = image
                        // Start background analysis as soon as image is captured
                        self?.startBackgroundAnalysis()
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.errorMessage = error.localizedDescription
                        self?.scanState = .error(error.localizedDescription)
                    }
                }
            }
        } else if capturedImage != nil {
            // If we already have a cached result, use it immediately
            if let cachedResult = cachedAnalysisResult {
                DispatchQueue.main.async {
                    self.scanState = .result(cachedResult)
                }
                return
            }
            
            // If background analysis is already in progress, just update UI state to show loading
            if case .backgroundScanning = scanState {
                DispatchQueue.main.async {
                    self.scanState = .scanning
                }
                
                // No need to start new analysis - it's already happening in the background
                // The background task will update the state when complete
            } else {
                // Otherwise start a new analysis
                Task {
                    await analyzeImage()
                }
            }
        }
    }
    
    // Start background analysis when image is displayed
    func startBackgroundAnalysis() {
        // Cancel any existing task first
        cancelBackgroundAnalysis()
        
        // Clear any cached result
        cachedAnalysisResult = nil
        
        // Start a new background task
        backgroundAnalysisTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Set state to background scanning
            await MainActor.run {
                self.scanState = .backgroundScanning
            }
            
            guard let image = self.capturedImage else {
                await MainActor.run {
                    self.errorMessage = "No image selected"
                    self.scanState = .error("No image selected")
                }
                return
            }
            
            // Ensure image is cropped to square if needed - always square for the 512x512 requirement
            let squareImage = self.imageService.ensureSquareImage(image: image)
            
            // Resize image to exactly 512x512 for the API requirement
            // Force exact 512x512 dimensions rather than using maxDimension
            let resizedImage = self.imageService.resizeImage(image: squareImage, maxDimension: 512)
            
            // Compress the resized image to reduce file size
            guard let base64Image = self.imageService.convertImageToBase64(image: resizedImage, compressionQuality: 0.6) else {
                await MainActor.run {
                    self.errorMessage = "Failed to process image"
                    self.scanState = .error("Failed to process image")
                }
                return
            }
            
            do {
                // Check if task was cancelled before making API call
                if Task.isCancelled {
                    return
                }
                
                let response = try await self.apiService.analyzeProduct(imageBase64: base64Image)
                
                // Check again if task was cancelled after API call
                if Task.isCancelled {
                    return
                }
                
                await MainActor.run {
                    // Store the result in our cache
                    self.cachedAnalysisResult = response
                    
                    // Only update UI state if we're in scanning mode (user clicked analyze)
                    if case .scanning = self.scanState {
                        self.scanState = .result(response)
                    }
                    // Otherwise keep the state as backgroundScanning
                }
            } catch let error as APIError {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.errorMessage = error.message
                        self.scanState = .error(error.message)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.scanState = .error(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    // Cancel background analysis task
    func cancelBackgroundAnalysis() {
        backgroundAnalysisTask?.cancel()
        backgroundAnalysisTask = nil
        cachedAnalysisResult = nil
        
        // Only reset state if we're in background scanning
        if case .backgroundScanning = scanState {
            scanState = .ready
        }
    }
    
    func analyzeImage() async {
        // If we already have a result from background processing, just return
        if case .result = scanState {
            return
        }
        
        // Cancel any background task and start a new foreground one
        cancelBackgroundAnalysis()
        
        guard let image = capturedImage else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "No image selected"
                self.scanState = .error("No image selected")
            }
            return
        }
        
        // Ensure image is a perfect 512x512 square
        let squareImage = imageService.ensureSquareImage(image: image)
        
        // Resize image to exactly 512x512 for the API requirement
        // Using fixed 512x512 size for consistency with square design theme
        let resizedImage = imageService.resizeImage(image: squareImage, maxDimension: 512)
        
        // Compress the resized image to reduce file size
        guard let base64Image = imageService.convertImageToBase64(image: resizedImage, compressionQuality: 0.6) else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Failed to process image"
                self.scanState = .error("Failed to process image")
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.scanState = .scanning
        }
        
        do {
            let response = try await apiService.analyzeProduct(imageBase64: base64Image)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.scanState = .result(response)
            }
        } catch let error as APIError {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = error.message
                self.scanState = .error(error.message)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = error.localizedDescription
                self.scanState = .error(error.localizedDescription)
            }
        }
    }
    
    func resetScan() {
        cancelBackgroundAnalysis()
        capturedImage = nil
        scanState = .ready
        errorMessage = nil
        cachedAnalysisResult = nil
    }
    
    func toggleCameraPosition(cameraService: CameraService) {
        cameraService.toggleCameraPosition()
    }
    
    // Add manual text analysis function
    func analyzeManualText(_ text: String, prompt: String? = nil) {
        Task {
            await MainActor.run {
                self.scanState = .scanning
            }
            
            do {
                let response = try await apiService.analyzeText(
                    text: text,
                    prompt: prompt
                )
                
                await MainActor.run {
                    self.scanState = .result(response)
                }
            } catch let error as APIError {
                await MainActor.run {
                    self.errorMessage = error.message
                    self.scanState = .error(error.message)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.scanState = .error(error.localizedDescription)
                }
            }
        }
    }
}