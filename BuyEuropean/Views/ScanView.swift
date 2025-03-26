import SwiftUI
import AVFoundation
import Combine

#if canImport(UIKit)
import UIKit
#endif

// Import our custom components
import Foundation

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @State private var isShowingImagePicker = false
    @State private var isShowingResults = false
    @State private var isShowingError = false
    @State private var manualInputText = ""
    @State private var isManualInputExpanded = false
    @StateObject private var cameraService = CameraService()
    @State private var showingActionSheet = false
    @State private var isTextInputExpanded = false
    
    var body: some View {
        ZStack {
            // Background and camera view
            if !isTextInputExpanded {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                // Top area with title/logo - Only show when image is captured
                if viewModel.capturedImage != nil {
                    HStack {
                        // Back button
                        Button(action: {
                            // Cancel background analysis and reset
                            viewModel.cancelBackgroundAnalysis()
                            viewModel.resetScan()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                    .font(.title2)
                                Text("Back")
                                    .font(.headline)
                            }
                            .padding(10)
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        Text("BuyEuropean")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        
                        // Empty view for balance when back button is visible
                        Color.clear
                            .frame(width: 80, height: 10)
                    }
                    .padding(.top)
                }
                
                // Main content area - camera preview or captured image
                ZStack {
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Camera preview with state overlays
                        ZStack {
                            CameraPreview(session: cameraService.session)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .edgesIgnoringSafeArea(.all)
                            
                            // Camera state overlays
                            switch cameraService.state {
                            case .initializing:
                                Color.black.opacity(0.8)
                                    .overlay(
                                        VStack {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(2)
                                            Text("Initializing camera...")
                                                .foregroundColor(.white)
                                                .padding(.top)
                                        }
                                    )
                            case .error(let error):
                                Color.black.opacity(0.8)
                                    .overlay(
                                        VStack(spacing: 16) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.yellow)
                                            Text(error.localizedDescription)
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                            Button("Try Again") {
                                                cameraService.checkPermissionsAndSetup()
                                            }
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                        }
                                    )
                            case .capturing:
                                Color.white.opacity(0.1)
                            default:
                                EmptyView()
                            }
                        }
                    }
                    
                    // Scanning overlay
                    if case .scanning = viewModel.scanState {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2)
                            
                            Text("Analyzing product...")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Tagline
                Text("Vote with your Money.\nBuy European.")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                
                // Bottom navigation or action buttons
                if viewModel.capturedImage == nil {
                    // Camera mode buttons
                    HStack(spacing: 60) {
                        // Gallery button
                        Button(action: {
                            viewModel.showPhotoLibrary = true
                        }) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "photo.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(!cameraService.state.isReady)
                        
                        // Capture button
                        Button(action: {
                            viewModel.handleCameraButtonTap(cameraService: cameraService)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .strokeBorder(Color.black, lineWidth: 2)
                                    .frame(width: 70, height: 70)
                            }
                        }
                        .disabled(cameraService.state != .ready)
                        
                        // Selfie button
                        Button(action: {
                            cameraService.toggleCameraPosition()
                        }) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "camera.rotate")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                } else {
                    // Full-width Analyze Image button for review screen
                    Button(action: {
                        // Use handleCameraButtonTap which will check for cached results
                        viewModel.handleCameraButtonTap()
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.headline)
                            Text("Analyze Image")
                                .font(.headline)
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            
            }
            
            // Floating text input button - always visible when no image is captured
            if viewModel.capturedImage == nil {
                FloatingTextInput(
                    text: $manualInputText,
                    isExpanded: $isTextInputExpanded
                ) {
                    // Handle text submission
                    if !manualInputText.isEmpty {
                        viewModel.analyzeManualText(manualInputText)
                        // Don't clear text here - FloatingTextInput handles animation
                        // and we'll reset after analysis completes
                    }
                }
            }
        }
        .onAppear {
            cameraService.checkPermissionsAndSetup()
        }
        .sheet(isPresented: $viewModel.showPhotoLibrary) {
            ImagePicker(
                selectedImage: $viewModel.capturedImage,
                isPresented: $viewModel.showPhotoLibrary,
                sourceType: .photoLibrary
            ) {
                // Start background analysis as soon as image is selected from photo library
                viewModel.startBackgroundAnalysis()
            }
        }
        .sheet(isPresented: $viewModel.showPermissionRequest) {
            CameraPermissionView {
                if await viewModel.requestCameraPermission() {
                    cameraService.checkPermissionsAndSetup()
                }
            }
        }
        .sheet(item: sheetDestination) { destination in
            switch destination {
            case .results(let response):
                ResultsView(response: response, onDismiss: {
                    // First reset the sheet destination to nil to ensure proper dismissal
                    DispatchQueue.main.async {
                        // Reset the scan state which will cause the sheet to dismiss
                        viewModel.resetScan()
                    }
                })
            case .error(let message):
                ErrorView(message: message, onDismiss: {
                    viewModel.resetScan()
                })
            }
        }
    }
    
    // Helper to determine which sheet to show
    private var sheetDestination: Binding<SheetDestination?> {
        Binding<SheetDestination?>(
            get: {
                switch viewModel.scanState {
                case .result(let response):
                    return .results(response)
                case .error(let message):
                    return .error(message)
                default:
                    return nil
                }
            },
            set: { _ in }
        )
    }
}

// Enum to handle different sheet destinations
enum SheetDestination: Identifiable {
    case results(BuyEuropeanResponse)
    case error(String)
    
    var id: String {
        switch self {
        case .results:
            return "results"
        case .error:
            return "error"
        }
    }
}

// Preview
struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
    }
}