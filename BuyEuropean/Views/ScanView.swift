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
    @State private var selectedMode: InputMode = .camera
    @StateObject private var cameraService = CameraService()
    @State private var showingActionSheet = false
    
    // Animation states
    @State private var animateModeSwitching = false
    @Namespace private var animation
    
    enum InputMode {
        case camera
        case manual
    }
    
    var body: some View {
        ZStack {
            // Background color based on selected mode
            (selectedMode == .camera ? Color.black : Color(.systemBackground))
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // App title - always show at top
                Text("BuyEuropean")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(selectedMode == .camera ? .white : .primary)
                    .padding(.top)
                    .padding(.bottom, 8)
                
                // Back button when image is captured
                if viewModel.capturedImage != nil {
                    HStack {
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
                    }
                }
                
                // Main content area based on selected mode
                ZStack {
                    // CAMERA MODE CONTENT
                    if selectedMode == .camera {
                        if let image = viewModel.capturedImage {
                            // Display captured image
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
                    }
                    // MANUAL INPUT MODE CONTENT
                    else if selectedMode == .manual {
                        VStack(spacing: 24) {
                            Spacer()
                            
                            // European flag icon
                            Image(systemName: "flag.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.blue)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 120, height: 120)
                                )
                                .padding(.bottom, 20)
                            
                            // Text prompt
                            Text("Enter a brand or product name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Text input field
                            VStack {
                                TextField("e.g., iPhone, Samsung, Nestlé, Zara...", text: $manualInputText)
                                    .font(.system(size: 17))
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    .submitLabel(.search)
                                    .onSubmit {
                                        if !manualInputText.isEmpty {
                                            viewModel.analyzeManualText(manualInputText)
                                        }
                                    }
                                
                                // Analyze button
                                Button(action: {
                                    if !manualInputText.isEmpty {
                                        viewModel.analyzeManualText(manualInputText)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                        Text("Analyze")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(manualInputText.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                                    )
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                }
                                .disabled(manualInputText.isEmpty)
                            }
                            
                            Spacer()
                            Spacer()
                        }
                        .padding()
                    }
                    
                    // Scanning overlay (shown for both modes)
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
                
                // Bottom controls section - conditional based on state
                VStack(spacing: 12) {
                    // Tagline above buttons
                    Text("Vote with your Money.\nBuy European.")
                        .font(.subheadline)
                        .foregroundColor(selectedMode == .camera ? .white : .primary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)
                    
                    // Camera mode buttons or Analyze button depending on state
                    if selectedMode == .camera && viewModel.capturedImage == nil {
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
                    } else if viewModel.capturedImage != nil {
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
                    }
                    
                    // Only show mode toggle when no image captured
                    if viewModel.capturedImage == nil && viewModel.scanState == .ready {
                        // Pixel-style smaller mode toggle
                        HStack(spacing: 0) {
                            // Camera mode button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMode = .camera
                                }
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                    Text("Scan")
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .foregroundColor(selectedMode == .camera ? .white : .gray)
                                .background(
                                    ZStack {
                                        if selectedMode == .camera {
                                            Capsule()
                                                .fill(Color.blue.opacity(0.3))
                                                .matchedGeometryEffect(id: "ModeBackground", in: animation)
                                        }
                                    }
                                )
                            }
                            
                            // Manual mode button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMode = .manual
                                }
                            }) {
                                HStack {
                                    Image(systemName: "keyboard")
                                        .font(.system(size: 14))
                                    Text("Type")
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .foregroundColor(selectedMode == .manual ? .primary : .gray)
                                .background(
                                    ZStack {
                                        if selectedMode == .manual {
                                            Capsule()
                                                .fill(Color.blue.opacity(0.15))
                                                .matchedGeometryEffect(id: "ModeBackground", in: animation)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(4)
                        .background(
                            Capsule()
                                .fill(selectedMode == .camera ? Color.white.opacity(0.15) : Color(.systemGray6))
                        )
                        .fixedSize()
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedMode)
        }
        .onAppear {
            cameraService.checkPermissionsAndSetup()
        }
        .onChange(of: selectedMode) { newMode in
            // Reset scan state when switching modes
            if viewModel.scanState == .ready {
                viewModel.resetScan()
            }
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
                        // Reset manual input text after analysis
                        manualInputText = ""
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