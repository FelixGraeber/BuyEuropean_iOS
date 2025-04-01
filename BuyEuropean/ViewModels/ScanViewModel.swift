//
//  ScanViewModel.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI
import Combine
import CoreLocation

#if canImport(UIKit)
import UIKit
#endif

// Import our models and services
import Foundation

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
    @Published var showLocationPermissionSheet = false
    
    private let apiService = APIService.shared
    private let imageService = ImageService.shared
    private let permissionService = PermissionService.shared
    private let locationService = LocationService.shared
    
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
    
    func checkLocationPermission() {
        print("[ViewModel] Checking location permission. Current status: \(locationService.authorizationStatus)")
        if locationService.authorizationStatus == .notDetermined {
            print("[ViewModel] Location status is notDetermined. Setting showLocationPermissionSheet = true")
            showLocationPermissionSheet = true
        } else {
            print("[ViewModel] Location status is \(locationService.authorizationStatus). Not showing sheet.")
        }
    }
    
    func requestLocationPermission() async {
        print("[ViewModel] Requesting location permission via LocationService.")
        locationService.requestWhenInUseAuthorization()
    }
    
    func handleCameraButtonTap(cameraService: CameraService? = nil) {
        if let cameraService = cameraService {
            // Take photo from live preview
            cameraService.capturePhoto { [weak self] result in
                switch result {
                case .success(let image):
                    DispatchQueue.main.async {
                        self?.capturedImage = image
                        // Start analysis immediately without showing preview
                        Task {
                            await self?.analyzeImage()
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.errorMessage = error.localizedDescription
                        self?.scanState = .error(error.localizedDescription)
                    }
                }
            }
        } else {
            // This case should no longer be needed since we removed the preview
            Task {
                await analyzeImage()
            }
        }
    }
    
    // Remove background analysis since we're going straight to analysis
    func startBackgroundAnalysis() {
        Task {
            await analyzeImage()
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
        
        // Resize image to have the longest side of 768 pixels while maintaining aspect ratio
        let resizedImage = imageService.resizeImage(image: image, maxDimension: 768)
        
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
}