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

// Forward declaration of BuyEuropeanResponse to resolve circular dependency
// The actual type is defined in Models.swift
enum ScanState: Equatable {
    case ready
    case scanning
    case result(BuyEuropeanResponse)
    case error(String)
}

class ScanViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var scanState: ScanState = .ready
    @Published var showCamera = false
    @Published var showPhotoLibrary = false
    @Published var errorMessage: String?
    @Published var showPermissionRequest = false
    
    private let apiService = APIService.shared
    private let imageService = ImageService.shared
    private let permissionService = PermissionService.shared
    
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
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.errorMessage = error.localizedDescription
                        self?.scanState = .error(error.localizedDescription)
                    }
                }
            }
        } else if capturedImage != nil {
            // Analyze existing image
            Task {
                await analyzeImage()
            }
        }
    }
    
    func analyzeImage() async {
        guard let image = capturedImage else {
            DispatchQueue.main.async {
                self.errorMessage = "No image selected"
                self.scanState = .error("No image selected")
            }
            return
        }
        
        // Resize image to reduce upload size
        let resizedImage = imageService.resizeImage(image: image, targetSize: CGSize(width: 800, height: 800))
        
        guard let base64Image = imageService.convertImageToBase64(image: resizedImage) else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to process image"
                self.scanState = .error("Failed to process image")
            }
            return
        }
        
        DispatchQueue.main.async {
            self.scanState = .scanning
        }
        
        do {
            let response = try await apiService.analyzeProduct(imageBase64: base64Image)
            
            DispatchQueue.main.async {
                self.scanState = .result(response)
            }
        } catch let error as APIError {
            DispatchQueue.main.async {
                self.errorMessage = error.message
                self.scanState = .error(error.message)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.scanState = .error(error.localizedDescription)
            }
        }
    }
    
    func resetScan() {
        capturedImage = nil
        scanState = .ready
        errorMessage = nil
    }
}