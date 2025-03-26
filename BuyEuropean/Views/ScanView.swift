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
    @FocusState private var isTextFieldFocused: Bool
    
    // Animation states
    @State private var animateModeSwitching = false
    @Namespace private var animation
    
    // Device metrics for responsive design
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isSmallDevice: Bool {
        #if canImport(UIKit)
        return UIScreen.main.bounds.width < 375
        #else
        return false
        #endif
    }
    
    // These computed properties remain unchanged, as they do not materially affect layout
    private var cameraPreviewWidth: CGFloat {
        #if canImport(UIKit)
        return min(UIScreen.main.bounds.width, 400)
        #else
        return 400
        #endif
    }
    
    private var cameraPreviewHeight: CGFloat {
        #if canImport(UIKit)
        return min(UIScreen.main.bounds.width * 1.28, 512)
        #else
        return 512
        #endif
    }
    
    private var squareImageSize: CGFloat {
        #if canImport(UIKit)
        return min(UIScreen.main.bounds.width - 40, 512)
        #else
        return 512
        #endif
    }
    
    private var buttonSpacing: CGFloat {
        return isSmallDevice ? 30 : 50
    }
    
    private var controlButtonSize: CGFloat {
        return isSmallDevice ? 50 : 56
    }
    
    private var captureButtonSize: CGFloat {
        return isSmallDevice ? 72 : 78
    }
    
    private var innerButtonSize: CGFloat {
        return isSmallDevice ? 58 : 64
    }
    
    private var iconSize: CGFloat {
        return isSmallDevice ? 20 : 22
    }
    
    private var captureIconSize: CGFloat {
        return isSmallDevice ? 24 : 26
    }
    
    private var verticalSpacing: CGFloat {
        return isSmallDevice ? 8 : 16
    }
    
    private var topPadding: CGFloat {
        return isSmallDevice ? 8 : 12
    }
    
    private var bottomPadding: CGFloat {
        return isSmallDevice ? 16 : 32
    }
    
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
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top bar with controlled safe-area spacing - FIXED HEADER OUTSIDE OF SCROLL VIEW
                    HStack(spacing: 10) {
                        Image("AppIconImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text("BuyEuropean")
                            .font(geometry.size.width < 350 ? .headline : .title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                            
                        Spacer()
                    }
                    // If there's a large safe-area inset (e.g., iPhone 16 Pro), reduce the extra top padding
                    .padding(.horizontal, geometry.size.width < 350 ? 12 : 16)
                    .padding(.vertical, 12)
                    .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top * 0.2 : 18)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.white
                            .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
                    )
                    
                    // Main content area based on selected mode
                    ZStack {
                        // CAMERA MODE CONTENT
                        if selectedMode == .camera {
                            if let image = viewModel.capturedImage {
                                PhotoPreviewView(
                                    image: image,
                                    onBackToCamera: {
                                        // Cancel background analysis and reset
                                        viewModel.cancelBackgroundAnalysis()
                                        viewModel.resetScan()
                                    },
                                    onAnalyze: {
                                        // Use handleCameraButtonTap which will check for cached results
                                        viewModel.handleCameraButtonTap()
                                    }
                                )
                            } else {
                                // Camera preview with square viewfinder and state overlays
                                ZStack {
                                    // Modern light background
                                    Color(.systemBackground)
                                        .edgesIgnoringSafeArea(.all)
                                    
                                    VStack(spacing: 16) {
                                        // Empty spacer to maintain consistent spacing above camera
                                        Spacer().frame(height: 16)
                                        
                                        // Camera viewfinder with taller rectangle
                                        ZStack {
                                            CameraPreview(session: cameraService.session, isSquare: false)
                                                .frame(width: cameraPreviewWidth, height: cameraPreviewHeight)
                                        }
                                        .frame(width: cameraPreviewWidth, height: cameraPreviewHeight)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 0)
                                }
                            }
                        }
                        // MANUAL INPUT MODE CONTENT
                        else if selectedMode == .manual {
                            // IMPORTANT: The ScrollView now only contains the content, not the header
                            // Provide some top space first to separate from header
                            ScrollView {
                                // Add some spacing at the top to separate from the header
                                Spacer().frame(height: 12)
                                
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(.systemGray6), Color(.systemBackground)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .edgesIgnoringSafeArea(.all)
                                .frame(height: 0) // To preserve the gradient fade at top

                                // Use a VStack to hold your custom frames, text fields, etc.
                                VStack(spacing: isSmallDevice ? 16 : 28) {
                                    ZStack {
                                        // Outer decorative frame
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .frame(width: min(geometry.size.width - 40, 512) + 12,
                                                   height: min(geometry.size.width - 40, 256) + 12)
                                            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)

                                        // Second decorative frame
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(red: 245/255, green: 247/255, blue: 250/255))
                                            .frame(width: min(geometry.size.width - 40, 512) + 6,
                                                   height: min(geometry.size.width - 40, 256) + 6)

                                        VStack(spacing: 20) {
                                    
                                            Text("Enter a brand or product name")
                                                .font(.headline)
                                                .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255))
                                                .padding(.top, 10)

                                            VStack(spacing: 16) {
                                                TextField("e.g., iPhone, Samsung, Nestlé, Zara...", text: $manualInputText)
                                                    .font(.system(size: 17))
                                                    .focused($isTextFieldFocused)
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
                                                                  Color(red: 0/255, green: 51/255, blue: 153/255))
                                                            .shadow(color: Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.3),
                                                                    radius: 5, x: 0, y: 3)
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
                            // iOS16+ method to dismiss keyboard by pulling down:
                            .scrollDismissesKeyboard(.interactively)
                        }
                        
                        
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom controls section
                    VStack(spacing: geometry.size.width < 375 ? 8 : 16) {
                        Spacer().frame(height: geometry.size.width < 375 ? 4 : 8)
                        
                        if selectedMode == .camera && viewModel.capturedImage == nil {
                            HStack(spacing: 50) {
                                // Gallery button
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
                                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255))
                                    }
                                }
                                .disabled(!cameraService.state.isReady)
                                
                                // Capture button
                                Button(action: {
                                    viewModel.handleCameraButtonTap(cameraService: cameraService)
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(Color(red: 0/255, green: 51/255, blue: 153/255), lineWidth: 4)
                                            .frame(width: 78, height: 78)
                                        
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0/255, green: 51/255, blue: 153/255))
                                            .frame(width: 64, height: 64)
                                        
                                        Image(systemName: "viewfinder")
                                            .font(.system(size: geometry.size.width < 375 ? 24 : 26, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                                .disabled(cameraService.state != .ready)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
                                
                                // Flip camera button
                                Button(action: {
                                    cameraService.toggleCameraPosition()
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .frame(width: geometry.size.width < 375 ? 50 : 56,
                                                   height: geometry.size.width < 375 ? 50 : 56)
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                        
                                        Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                            .font(.system(size: geometry.size.width < 375 ? 20 : 22, weight: .medium))
                                            .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255))
                                    }
                                }
                            }
                        }
                        
                        // Toggle between camera and manual modes only if no captured image
                        if viewModel.capturedImage == nil && viewModel.scanState == .ready {
                            HStack(spacing: 0) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedMode = .camera
                                        isTextFieldFocused = false
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "viewfinder")
                                            .font(.system(size: geometry.size.width < 375 ? 12 : 14, weight: .medium))
                                        Text("Scan")
                                            .font(geometry.size.width < 375 ? .caption : .footnote)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, geometry.size.width < 375 ? 8 : 10)
                                    .padding(.horizontal, geometry.size.width < 375 ? 12 : 16)
                                    .foregroundColor(selectedMode == .camera ? .white : Color(.systemGray2))
                                    .background(
                                        ZStack {
                                            if selectedMode == .camera {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(red: 0/255, green: 51/255, blue: 153/255))
                                                    .matchedGeometryEffect(id: "ModeBackground", in: animation)
                                            }
                                        }
                                    )
                                }
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedMode = .manual
                                        // Directly set focus rather than delaying
                                        isTextFieldFocused = true
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: geometry.size.width < 375 ? 12 : 14, weight: .medium))
                                        Text("Type")
                                            .font(geometry.size.width < 375 ? .caption : .footnote)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, geometry.size.width < 375 ? 8 : 10)
                                    .padding(.horizontal, geometry.size.width < 375 ? 12 : 16)
                                    .foregroundColor(selectedMode == .manual ? .white : Color(.systemGray2))
                                    .background(
                                        ZStack {
                                            if selectedMode == .manual {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(red: 0/255, green: 51/255, blue: 153/255))
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
                            .padding(.top, geometry.size.width < 375 ? 8 : 12)
                            // Always add safe-area bottom inset to avoid overflow on devices like iPhone X
                            .padding(.bottom, geometry.safeAreaInsets.bottom + (geometry.size.width < 375 ? 16 : 20))
                        } else {
                            // If the toggle is hidden, still provide bottom inset
                            Spacer().frame(height: geometry.safeAreaInsets.bottom + (geometry.size.width < 375 ? 16 : 20))
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedMode)
        }
        .onAppear {
            cameraService.checkPermissionsAndSetup()
            #if DEBUG
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                print("Top Safe Area: \(windowScene.windows.first?.safeAreaInsets.top ?? -1)")
                print("Bottom Safe Area: \(windowScene.windows.first?.safeAreaInsets.bottom ?? -1)")
            }
            #endif
        }
        .onChange(of: selectedMode) { newMode in
            // Reset scan state when switching modes if ready
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
                // Start background analysis once an image is selected
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
                    DispatchQueue.main.async {
                        viewModel.resetScan()
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
        case .results(let response):
            return "results-\(response.id)"
        case .error(let message):
            return "error-\(message)"
        }
    }
}

struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScanView()
                .previewDevice("iPhone 14 Pro")
                .previewDisplayName("iPhone 14 Pro")
            
            ScanView()
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("iPhone SE (3rd Gen)")
            
            ScanView()
                .previewDevice("iPhone 11")
                .previewDisplayName("iPhone 11")
        }
    }
}
