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
            // Enhanced background with subtle pattern for more elegant square design theme
            ZStack {
                // Base background color
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                // Subtle grid pattern for square theme (very light)
                VStack(spacing: 0) {
                    ForEach(0..<40) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<20) { column in
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 20, height: 20)
                                    .border(Color(.systemGray6), width: 0.5)
                            }
                        }
                    }
                }
                .opacity(0.2)
                
                // Top and bottom fade
                VStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemBackground), Color(.systemBackground).opacity(0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                }
                .edgesIgnoringSafeArea(.all)
            }
            
            VStack(spacing: 0) {
                // App title with enhanced styling for square design theme
                HStack(spacing: 10) {
                    Image("AppIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("BuyEuropean")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                        
                    Spacer()
                    
        
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    Color.white
                        .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
                )
                
                // Back button when image is captured - enhanced styling for square design theme
                if viewModel.capturedImage != nil {
                    HStack {
                        Button(action: {
                            // Cancel background analysis and reset
                            viewModel.cancelBackgroundAnalysis()
                            viewModel.resetScan()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left.square.fill")
                                    .font(.body.weight(.semibold))
                                Text("Back to Camera")
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                                    .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                            )
                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                        }
                        
                        Spacer()
                        
                        // Dimension indicator
                        Text("512×512")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(Color(.systemGray2))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                }
                
                // Main content area based on selected mode
                ZStack {
                    // CAMERA MODE CONTENT
                    if selectedMode == .camera {
                        if let image = viewModel.capturedImage {
                            // Display captured image in square format with enhanced styling
                            ZStack {
                                // Modern light background
                                Color(.systemBackground)
                                    .edgesIgnoringSafeArea(.all)
                                
                                VStack(spacing: 24) {
                                    // Title for review screen with improved styling
                                    VStack(spacing: 6) {
                                        Image(systemName: "checkmark.square.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.8))
                                        
                                        Text("Review Image")
                                            .font(.headline)
                                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255))
                                    }
                                    
                                    // Explanation subtitle
                                    Text("Captured image ready for analysis")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 8)
                                    
                                    // Square container with enhanced multi-layered styling
                                    ZStack {
                                        // Outer decorative frame with visual depth
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .frame(width: (UIScreen.main.bounds.width - 40) + 6,
                                                   height: (UIScreen.main.bounds.width - 40) + 6)
                                            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
                                        
                                        // Second decorative frame for layered effect
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(red: 245/255, green: 247/255, blue: 250/255))
                                            .frame(width: min(UIScreen.main.bounds.width - 40, 512) + 6,
                                                   height: min(UIScreen.main.bounds.width - 40, 512) + 6)
                                        
                                        // Image displayed in a square container - exactly 512x512 max
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: UIScreen.main.bounds.width - 40,
                                                   height: UIScreen.main.bounds.width - 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                            
    
                                    }
                                    
                                    // Instruction text with improved styling
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        
                                        Text("Ready to analyze product")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.top, 8)
                                }
                                .padding()
                            }
                        } else {
                            // Camera preview with square viewfinder and state overlays
                            ZStack {
                                // Modern light background
                                Color(.systemBackground)
                                    .edgesIgnoringSafeArea(.all)
                                
                                VStack(spacing: 24) {
                                    // Instruction text above viewfinder with improved styling
                                    VStack(spacing: 6) {
                                        Image(systemName: "viewfinder")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.8))
                                        
                                        Text("Center product in square frame")
                                            .font(.headline)
                                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255))
                                    }
                                    .padding(.bottom, 4)
                                    
                                    // Explanation subtitle
                                    Text("Image will be uploaded in square format")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 8)
                                    
                                    // Square camera viewfinder - exactly 512x512 or width-based if smaller
                                    ZStack {
                                        // Outer decorative frame with visual depth
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .frame(width: min(UIScreen.main.bounds.width - 40, 512) + 12,
                                                   height: min(UIScreen.main.bounds.width - 40, 512) + 12)
                                            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
                                        
                                        // Second decorative frame for layered effect
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(red: 245/255, green: 247/255, blue: 250/255))
                                            .frame(width: min(UIScreen.main.bounds.width - 40, 512) + 6,
                                                   height: min(UIScreen.main.bounds.width - 40, 512) + 6)
                                        
                                        // Camera preview in a square container - exactly 512x512 max
                                        CameraPreview(session: cameraService.session, isSquare: true)
                                            .frame(width: min(UIScreen.main.bounds.width - 40, 512),
                                                   height: min(UIScreen.main.bounds.width - 40, 512))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                        
                                        // Enhanced stylish corner marks with modern design
                                        ZStack {
                                            // Top left corner
                                            Path { path in
                                                path.move(to: CGPoint(x: 0, y: 40))
                                                path.addLine(to: CGPoint(x: 0, y: 0))
                                                path.addLine(to: CGPoint(x: 40, y: 0))
                                            }
                                            .stroke(Color.white.opacity(0.9), lineWidth: 4)
                                            
                                            // Top right corner
                                            Path { path in
                                                let width = min(UIScreen.main.bounds.width - 40, 512)
                                                path.move(to: CGPoint(x: width, y: 40))
                                                path.addLine(to: CGPoint(x: width, y: 0))
                                                path.addLine(to: CGPoint(x: width - 40, y: 0))
                                            }
                                            .stroke(Color.white.opacity(0.9), lineWidth: 4)
                                            
                                            // Bottom left corner
                                            Path { path in
                                                let height = min(UIScreen.main.bounds.width - 40, 512)
                                                path.move(to: CGPoint(x: 0, y: height - 40))
                                                path.addLine(to: CGPoint(x: 0, y: height))
                                                path.addLine(to: CGPoint(x: 40, y: height))
                                            }
                                            .stroke(Color.white.opacity(0.9), lineWidth: 4)
                                            
                                            // Bottom right corner
                                            Path { path in
                                                let width = min(UIScreen.main.bounds.width - 40, 512)
                                                let height = min(UIScreen.main.bounds.width - 40, 512)
                                                path.move(to: CGPoint(x: width, y: height - 40))
                                                path.addLine(to: CGPoint(x: width, y: height))
                                                path.addLine(to: CGPoint(x: width - 40, y: height))
                                            }
                                            .stroke(Color.white.opacity(0.9), lineWidth: 4)
                                            
    
                                        }
                                        
                                        // Camera state overlays
                                        switch cameraService.state {
                                        case .initializing:
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.8))
                                                .overlay(
                                                    VStack {
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                            .scaleEffect(1.5)
                                                        Text("Initializing camera...")
                                                            .foregroundColor(.white)
                                                            .padding(.top)
                                                    }
                                                )
                                        case .error(let error):
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.8))
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
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.2))
                                        default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: min(UIScreen.main.bounds.width - 40, 512),
                                           height: min(UIScreen.main.bounds.width - 40, 512))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    // MANUAL INPUT MODE CONTENT with enhanced styling
                    else if selectedMode == .manual {
                        // Modern gradient background
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.systemGray6), Color(.systemBackground)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 28) {
                            // Square frame to maintain consistent design with camera mode
                            ZStack {
                                // Outer decorative frame with visual depth
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .frame(width: min(UIScreen.main.bounds.width - 40, 512) + 12,
                                           height: min(UIScreen.main.bounds.width - 40, 512) + 12)
                                    .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
                                
                                // Second decorative frame for layered effect
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 245/255, green: 247/255, blue: 250/255))
                                    .frame(width: min(UIScreen.main.bounds.width - 40, 512) + 6,
                                           height: min(UIScreen.main.bounds.width - 40, 512) + 6)
                                
                                VStack(spacing: 20) {
                                    // European flag icon with square theme
                                    Image(systemName: "eurozonesign.square.fill")
                                        .font(.system(size: 70))
                                        .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.1))
                                                .frame(width: 150, height: 150)
                                        )
                                    
    
                                    
                                    // Text prompt
                                    Text("Enter a brand or product name")
                                        .font(.headline)
                                        .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                                        .padding(.top, 10)
                                    
                                    // Text input field with enhanced styling
                                    VStack(spacing: 16) {
                                        TextField("e.g., iPhone, Samsung, Nestlé, Zara...", text: $manualInputText)
                                            .font(.system(size: 17))
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(.systemGray6))
                                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                            )
                                            .submitLabel(.search)
                                            .onSubmit {
                                                if !manualInputText.isEmpty {
                                                    viewModel.analyzeManualText(manualInputText)
                                                }
                                            }
                                        
                                        // Analyze button with European theme
                                        Button(action: {
                                            if !manualInputText.isEmpty {
                                                viewModel.analyzeManualText(manualInputText)
                                            }
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "magnifyingglass")
                                                    .font(.headline)
                                                Text("Analyze")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(manualInputText.isEmpty ?
                                                          Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.5) :
                                                          Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                                                    .shadow(color: Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.3), radius: 5, x: 0, y: 3)
                                            )
                                            .foregroundColor(.white)
                                        }
                                        .disabled(manualInputText.isEmpty)
                                    }
                                    .padding(.horizontal, 24)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    
                    // Scanning overlay with square design theme
                    if case .scanning = viewModel.scanState {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            // Progress indicator with square outline
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 100, height: 100)
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(2)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Analyzing Image")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Processing square product image...")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 280, height: 240)
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom controls section with enhanced styling
                VStack(spacing: 16) {
                    // Tagline above buttons with improved styling
                    VStack(spacing: 4) {
                        Text("Vote with your Money")
                            .font(.headline)
                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                        
                        Text("Buy European")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.8))
                            .italic()
                    }
                    .padding(.bottom, 6)
                    
                    // Camera mode buttons or Analyze button depending on state
                    if selectedMode == .camera && viewModel.capturedImage == nil {
                        // Camera mode buttons with square design theme
                        HStack(spacing: 50) {
                            // Gallery button - square design theme
                            Button(action: {
                                viewModel.showPhotoLibrary = true
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .frame(width: 56, height: 56)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    
                                    Image(systemName: "photo.on.rectangle.fill")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                                }
                            }
                            .disabled(!cameraService.state.isReady)
                            
                            // Capture button - square design theme
                            Button(action: {
                                viewModel.handleCameraButtonTap(cameraService: cameraService)
                            }) {
                                ZStack {
                                    // Outer square
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color(red: 0/255, green: 51/255, blue: 153/255), lineWidth: 4) // European blue
                                        .frame(width: 78, height: 78)
                                    
                                    // Inner square
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                                        .frame(width: 64, height: 64)
                                        
                                    // Square icon
                                    Image(systemName: "viewfinder")
                                        .font(.system(size: 26, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            .disabled(cameraService.state != .ready)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
                            
                            // Flip camera button - square design theme
                            Button(action: {
                                cameraService.toggleCameraPosition()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .frame(width: 56, height: 56)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    
                                    Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                                }
                            }
                        }
                    } else if viewModel.capturedImage != nil {
                        // Enhanced Analyze Image button for review screen with square design theme
                        Button(action: {
                            // Use handleCameraButtonTap which will check for cached results
                            viewModel.handleCameraButtonTap()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up.on.square.fill")
                                    .font(.headline)
                                
                                Text("Analyze 512×512 Image")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                                    .shadow(color: Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.4), radius: 10, x: 0, y: 4)
                            )
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                    }
                    
                    // Only show mode toggle when no image captured
                    if viewModel.capturedImage == nil && viewModel.scanState == .ready {
                        // Enhanced mode toggle with square design theme
                        HStack(spacing: 0) {
                            // Camera mode button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMode = .camera
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "viewfinder")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Scan")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .foregroundColor(selectedMode == .camera ? .white : Color(.systemGray2))
                                .background(
                                    ZStack {
                                        if selectedMode == .camera {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
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
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Type")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .foregroundColor(selectedMode == .manual ? .white : Color(.systemGray2))
                                .background(
                                    ZStack {
                                        if selectedMode == .manual {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                                                .matchedGeometryEffect(id: "ModeBackground", in: animation)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        )
                        .padding(.top, 12)
                        .padding(.bottom, 24)
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