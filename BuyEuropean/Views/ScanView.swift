import AVFoundation
import Combine
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

// Assume these custom components and types are correctly defined elsewhere:
// PhotoPreviewView, CameraPreview, ImagePicker, CameraPermissionView,
// ResultsView, ErrorView, ScanViewModel, CameraService, PermissionService,
// BuyEuropeanResponse (DEFINED ONLY ONCE IN YOUR PROJECT), APIService, ImageService, APIError

struct ScanView: View {
    enum InputMode: CaseIterable {
        case camera
        case manual
    }
    @StateObject private var viewModel = ScanViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    // Get IAP Manager from environment
    @EnvironmentObject var iapManager: IAPManager 
    // State vars derived from viewModel for sheet/haptic triggers
    @State private var showResultsHapticTrigger = false
    @State private var showErrorHapticTrigger = false
    @State private var showSupportSheet = false // State to present the SupportView
    @State private var showHistory = false // State to present the HistoryView

    @State private var manualInputText = ""
    @State private var selectedMode: InputMode = .camera
    @StateObject private var cameraService = CameraService()
    @FocusState private var isTextFieldFocused: Bool

    @Namespace private var animation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Computed properties for sizes (can be adjusted or replaced with GeometryReader values)
    private var cameraPreviewWidth: CGFloat {
        #if canImport(UIKit)
            return min(UIScreen.main.bounds.width - 40, 400)  // Allow padding
        #else
            return 400
        #endif
    }

    private var cameraPreviewHeight: CGFloat {
        #if canImport(UIKit)
            return min((UIScreen.main.bounds.width - 40) * 1.35, 540)  // Taller aspect ratio
        #else
            return 540
        #endif
    }

 

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // MARK: - Header
                    HStack(spacing: 10) {
                        // History button
                        Button {
                            showHistory = true
                        } label: {
                            Image(systemName: "clock.fill")
                                .font(.title3)
                                .foregroundColor(Color.brandPrimary)
                        }
                        Image("AppIconImage")  // Ensure this asset exists
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text("BuyEuropean")
                            .font(geometry.size.width < 350 ? .headline : .title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.brandPrimary)

                        Spacer()

                        // --- Add Support Button --- 
                        Button {
                            showSupportSheet = true
                        } label: {
                            Text("Support")
                                .font(.caption.weight(.semibold))
                                .padding(.vertical, 6)   // Re-add padding for background
                                .padding(.horizontal, 10)
                        }
                        // .buttonStyle(.bordered) // Remove button style
                        .background( // Add specific background
                            Color.brandPrimary
                        )
                        .foregroundColor(.white) // Set text color for contrast
                        .clipShape(Capsule())         // Keep capsule shape
                        // --------------------------
                    }
                    .padding(.horizontal, geometry.size.width < 350 ? 12 : 16)
                    .padding(.vertical, 10)
                    .padding(
                        .top,
                        geometry.safeAreaInsets.top > 20
                            ? max(10, geometry.safeAreaInsets.top * 0.1) : 12
                    )
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)

                    // MARK: - Main Content Area
                    ZStack {
                        // --- CAMERA MODE ---
                        if selectedMode == .camera {
                            Group {
                                // Camera preview container
                                ZStack {
                                    Color.clear

                                    VStack(spacing: 16) {
                                        Spacer().frame(height: 16)

                                        ZStack {
                                            CameraPreview(session: cameraService.session)
                                                .frame(
                                                    width: cameraPreviewWidth,
                                                    height: cameraPreviewHeight
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(
                                                            Color(.systemGray5), lineWidth: 1)
                                                )
                                                .overlay(cameraStateOverlay())  // Make sure this uses correct state name
                                        }
                                        .frame(
                                            width: cameraPreviewWidth,
                                            height: cameraPreviewHeight
                                        )
                                        .shadow(
                                            color: Color.black.opacity(0.1), radius: 8, x: 0,
                                            y: 4)

                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .onChange(of: scenePhase) { newPhase in
                                if newPhase == .active {
                                    print("[ScanView] App became active. Checking camera setup.")
                                    cameraService.checkPermissionsAndSetup()
                                } else if newPhase == .background {
                                    print("[ScanView] App went to background. Stopping camera session.")
                                    cameraService.stopSession()
                                }
                            }
                            .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                        }
                        // --- MANUAL INPUT MODE ---
                        else if selectedMode == .manual {
                            ScrollView {
                                VStack(spacing: geometry.size.width < 375 ? 20 : 28) {
                                    Spacer().frame(height: geometry.size.width < 375 ? 16 : 24)

                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.cardBackground)
                                            .frame(
                                                width: min(geometry.size.width - 40, 512) + 12,
                                                height: max(
                                                    240, min(geometry.size.width - 40, 256) + 12)
                                            )
                                            .shadow(
                                                color: Color.black.opacity(0.1), radius: 10, x: 0,
                                                y: 4)

                                        VStack(spacing: 16) {
                                            Text("Enter a brand or product name")
                                                .font(.headline)
                                                .foregroundColor(Color.brandPrimary)
                                                .padding(.top, 16)

                                            VStack(spacing: 12) {
                                                TextField(
                                                    "e.g., iPhone, Samsung, Nestlé, Zara...",
                                                    text: $manualInputText
                                                )
                                                .font(.body)  // Dynamic Type friendly
                                                .focused($isTextFieldFocused)
                                                .padding(12)
                                                .foregroundColor(.primary)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(Color.inputBackground)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .stroke(Color.inputBorder, lineWidth: 1)
                                                        )
                                                        .shadow(
                                                            color: Color.black.opacity(0.04),
                                                            radius: 3, x: 0, y: 1)
                                                )
                                                .submitLabel(.search)
                                                .onSubmit {
                                                    submitManualInput()
                                                }

                                                Button(action: submitManualInput) {
                                                    HStack(spacing: 10) {
                                                        Image(systemName: "magnifyingglass")
                                                            .font(.headline)
                                                        Text("Analyze")
                                                            .font(.headline)
                                                            .fontWeight(.semibold)
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 14)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(
                                                                manualInputText.isEmpty
                                                                    ? Color.brandPrimary.opacity(0.5)
                                                                    : Color.brandPrimary
                                                            )
                                                            .shadow(
                                                                color: Color.brandPrimary.opacity(0.25),
                                                                radius: 5, x: 0, y: 2)
                                                    )
                                                    .foregroundColor(.white)
                                                }
                                                .disabled(manualInputText.isEmpty)
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.bottom, 16)
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .frame(maxWidth: min(geometry.size.width - 40, 512) + 12)

                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .scrollDismissesKeyboard(.interactively)
                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                        }

                        // MARK: - Loading Indicator Overlay
                        // Use viewModel states directly
                        if viewModel.scanState == .scanning
                            // Remove background scanning from here:
                            // || viewModel.scanState == .backgroundScanning
                        {
                            ZStack {
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .ignoresSafeArea()

                                ProgressView(
                                    viewModel.scanState == .scanning
                                        ? "Analyzing..." : "Processing..."
                                )
                                .padding(20)
                                .background(.thickMaterial)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            .zIndex(10)
                            .transition(.opacity.animation(.easeInOut))
                        }

                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // MARK: - Bottom Controls
                    VStack(spacing: geometry.size.width < 375 ? 10 : 16) {

                        // --- Camera Controls ---
                        if selectedMode == .camera && viewModel.capturedImage == nil {
                            HStack(spacing: calculateButtonSpacing(geometry: geometry)) {
                                // Gallery button
                                controlButton(icon: "photo.on.rectangle.fill", geometry: geometry) {
                                    viewModel.showPhotoLibrary = true
                                }
                                .disabled(
                                    cameraService.state != .ready
                                        || viewModel.scanState == .scanning
                                        || viewModel.scanState == .backgroundScanning)

                                // Capture button
                                captureButton(geometry: geometry) {
                                    viewModel.handleCameraButtonTap(cameraService: cameraService)
                                }
                                .disabled(
                                    cameraService.state != .ready
                                        || viewModel.scanState == .scanning
                                        || viewModel.scanState == .backgroundScanning)

                                // Flip camera button
                                controlButton(
                                    icon: "arrow.triangle.2.circlepath.camera.fill",
                                    geometry: geometry
                                ) {
                                    cameraService.toggleCameraPosition()
                                }
                                .disabled(
                                    viewModel.scanState == .scanning
                                        || viewModel.scanState == .backgroundScanning)
                            }
                            .padding(.bottom, geometry.size.width < 375 ? 8 : 12)
                            .transition(.opacity.animation(.easeInOut))
                        }

                        // --- Mode Toggle ---
                        // Show toggle only when ready and no image is captured
                        if viewModel.capturedImage == nil && viewModel.scanState == .ready {
                            modeToggleButton(geometry: geometry)
                                .padding(
                                    .bottom,
                                    geometry.safeAreaInsets.bottom > 0
                                        ? 0 : (geometry.size.width < 375 ? 12 : 16)
                                )
                                .padding(.bottom, geometry.safeAreaInsets.bottom)  // Respect safe area
                                .transition(.opacity.animation(.easeInOut))
                        } else if viewModel.capturedImage == nil {
                            // Add safe area spacer even if toggle is hidden (e.g., during analysis)
                            Spacer().frame(height: geometry.safeAreaInsets.bottom)
                                .transition(.opacity.animation(.easeInOut))
                        } else {
                            // Spacer for when photo preview is shown
                            Spacer().frame(height: geometry.safeAreaInsets.bottom)
                        }
                    }
                    .padding(.top, 8)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)  // Keep header fixed
            }
            // .animation(.easeInOut(duration: 0.3), value: selectedMode)
            .animation(.easeInOut(duration: 0.2), value: viewModel.scanState)
            .animation(.default, value: cameraService.state)
             // Add sheet modifier for the SupportView
            .sheet(isPresented: $showSupportSheet) {
                // Pass the IAPManager from the environment
                SupportView()
                    .environmentObject(iapManager)
            }
            // History sheet
            .sheet(isPresented: $showHistory) {
                NavigationView {
                    HistoryView { item in
                        viewModel.scanState = .result(item.response, nil)
                        showHistory = false
                    }
                    .navigationTitle("History")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showHistory = false }
                        }
                    }
                }
            }
        }
        .onAppear {
            print("[ScanView] .onAppear triggered.")
            // Check initial permission status WITHOUT requesting
            // Use the correct property and enum case from PermissionService
            if permissionService.cameraPermissionStatus == .granted {
                print("[ScanView] Camera permission already granted.")
                 // If already granted, setup the camera immediately
                cameraService.checkPermissionsAndSetup()
                // THEN check for location permission
                print("[ScanView] Calling viewModel.checkLocationPermission() from .onAppear")
                viewModel.checkLocationPermission()
            } else {
                 print("[ScanView] Camera permission is \(permissionService.cameraPermissionStatus). Not setting up camera yet.")
            }
            // If .notDetermined, the viewModel's init logic will show the camera permission sheet.
            // If .denied or .restricted, the cameraService state overlay might handle showing an error.
        }
        // Use onChange variant appropriate for your iOS target
        .onChange(of: viewModel.scanState) { newState in  // For iOS 14/15/16
            // .onChange(of: viewModel.scanState) { oldState, newState in // For iOS 17+
            showResultsHapticTrigger = false
            showErrorHapticTrigger = false
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000)
                if case .result = newState {
                    showResultsHapticTrigger = true
                } else if case .error = newState {
                    showErrorHapticTrigger = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showPhotoLibrary) {
            ImagePicker(
                selectedImage: $viewModel.capturedImage,
                isPresented: $viewModel.showPhotoLibrary,
                sourceType: .photoLibrary
            ) {
                // Start background analysis as soon as image is selected from library
                viewModel.startBackgroundAnalysis()
            }
        }
        .sheet(isPresented: $viewModel.showPermissionRequest) {
            CameraPermissionView {
                print("[ScanView] CameraPermissionView 'Continue' tapped.")
                if await viewModel.requestCameraPermission() {
                    print("[ScanView] Camera permission GRANTED via sheet.")
                    cameraService.checkPermissionsAndSetup()
                    // After camera permission granted and setup, check location permission
                     print("[ScanView] Calling viewModel.checkLocationPermission() from Camera sheet completion.")
                    viewModel.checkLocationPermission()
                } else {
                    print("[ScanView] Camera permission DENIED via sheet.")
                }
            }
        }
        // Add sheet for Location Permission
        .sheet(isPresented: $viewModel.showLocationPermissionSheet) {
            LocationPermissionView {
                 print("[ScanView] LocationPermissionView 'Allow Location Access' tapped.")
                // Call the view model function to request location permission
                await viewModel.requestLocationPermission()
            }
        }
        // Ensure sheetDestination is accessible here
        .sheet(item: sheetDestination) { destination in
            switch destination {
            case .results(let response, let image):
                ResultsView(
                    response: response,
                    analysisImage: image,
                    onDismiss: {
                        viewModel.scanState = .ready // Set to ready state to dismiss sheet
                    })
            case .error(let message):
                ErrorView(
                    message: message,
                    onDismiss: {
                        viewModel.scanState = .ready // Set to ready state to dismiss sheet
                    })
            }
        }
    }

    // MARK: - Helper Functions / Subviews

    private func submitManualInput() {
        if !manualInputText.isEmpty {
            isTextFieldFocused = false
            viewModel.analyzeManualText(manualInputText)
        }
    }

    private func calculateButtonSpacing(geometry: GeometryProxy) -> CGFloat {
        let availableWidth = geometry.size.width - (2 * 20)
        let buttonCount: CGFloat = 3
        let totalButtonWidth =
            (2 * controlButtonSize(geometry: geometry)) + captureButtonSize(geometry: geometry)
        let spacing = max(20, (availableWidth - totalButtonWidth) / (buttonCount - 1))
        return min(spacing, 60)
    }

    // Dynamic Sizes based on geometry
    private func controlButtonSize(geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 375 ? 50 : 56
    }
    private func captureButtonSize(geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 375 ? 72 : 78
    }
    private func innerCaptureButtonSize(geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 375 ? 58 : 64
    }
    private func iconSize(geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 375 ? 20 : 22
    }
    private func captureIconSize(geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 375 ? 24 : 26
    }

    // Refactored Control Button
    @ViewBuilder
    private func controlButton(icon: String, geometry: GeometryProxy, action: @escaping () -> Void)
        -> some View
    {
        let size = controlButtonSize(geometry: geometry)
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)  // Use material
                    .frame(width: size, height: size)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)

                Image(systemName: icon)
                    .font(.system(size: iconSize(geometry: geometry), weight: .medium))
                    .foregroundColor(Color.brandPrimary)
            }
        }
    }

    // Refactored Capture Button
    @ViewBuilder
    private func captureButton(geometry: GeometryProxy, action: @escaping () -> Void) -> some View {
        let outerSize = captureButtonSize(geometry: geometry)
        let innerSize = innerCaptureButtonSize(geometry: geometry)
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(
                        Color.brandPrimary.opacity(0.5),
                        lineWidth: 3
                    )
                    .frame(width: outerSize, height: outerSize)

                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: innerSize, height: innerSize)

                Image(systemName: "viewfinder")
                    .font(.system(size: captureIconSize(geometry: geometry), weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    // Refactored Mode Toggle Button
    @ViewBuilder
    private func modeToggleButton(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            ForEach(InputMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedMode = mode
                        isTextFieldFocused = (mode == .manual)
                    }
                } label: {
                    modeToggleLabel(mode: mode, geometry: geometry)
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.thinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    // Label for Mode Toggle
    @ViewBuilder
    private func modeToggleLabel(mode: InputMode, geometry: GeometryProxy) -> some View {
        let isSelected = selectedMode == mode
        let iconName = (mode == .camera) ? "camera.fill" : "square.and.pencil"
        let text = (mode == .camera) ? "Photo" : "Text"
        let iconFontSize = geometry.size.width < 375 ? 12.0 : 14.0
        let textFont: Font = geometry.size.width < 375 ? .caption : .footnote

        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: iconFontSize, weight: .medium))
            Text(text)
                .font(textFont)
                .fontWeight(.semibold)
        }
        .padding(.vertical, geometry.size.width < 375 ? 9 : 11)
        .padding(.horizontal, geometry.size.width < 375 ? 14 : 18)
        .frame(minWidth: geometry.size.width * 0.3)
        .foregroundColor(isSelected ? .white : .secondary)
        .background {
            if isSelected {
                Capsule()
                    .fill(Color.brandPrimary)
                    .matchedGeometryEffect(id: "ModeBackground", in: animation)
                    .shadow(
                        color: Color.brandPrimary.opacity(0.3),
                        radius: 4, x: 0, y: 2)
            }
        }
    }

    // Overlay for Camera State Feedback
    @ViewBuilder
    private func cameraStateOverlay() -> some View {
        // Ensure overlay shows only when appropriate (not ready AND no image preview)
        if cameraService.state != .ready && viewModel.capturedImage == nil {
            ZStack {
                Color.black.opacity(0.4).blur(radius: 3)  // Background dim/blur

                VStack(spacing: 5) {
                    // Check the specific state using a switch
                    switch cameraService.state {
                    case .initializing:
                        ProgressView()  // Spinner for initializing
                        Text("Initializing Camera...")

                    case .error(let cameraError):  // Check if state is .error and extract the inner Camera.Error
                        // Now check the specific type of Camera.Error
                        switch cameraError {
                        case .notAuthorized:
                            // UI for permission denied
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(
                                .yellow)
                            Text("Camera Access Needed")
                        case .setupFailed, .captureFailed, .noCamera:
                            // UI for other camera errors
                            Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                            // Display the specific error message from Camera.Error
                            Text(cameraError.localizedDescription)
                                .multilineTextAlignment(.center)  // Allow wrapping if message is long
                        }

                    // No specific overlay needed for .ready or .capturing in this View's logic
                    case .ready, .capturing:
                        EmptyView()  // Explicitly handle other cases
                    }
                }
                .foregroundColor(.white)  // Text color for overlay
                .font(.caption)  // Font size for overlay text
                .padding(10)  // Padding inside the overlay box
                .background(.ultraThinMaterial)  // Background material for the box
                .cornerRadius(8)  // Rounded corners for the box
                .shadow(radius: 3)  // Subtle shadow for the box
            }
            .transition(.opacity.animation(.easeInOut))  // Animate the overlay's appearance
        }
    }

    // *** Ensure this is defined within struct ScanView scope ***
    // Computed binding for sheet presentation logic
    private var sheetDestination: Binding<SheetDestination?> {
        Binding<SheetDestination?>(
            get: {
                switch viewModel.scanState {
                case .result(let response, let image):
                    return .results(response, image)
                case .error(let message):
                    return .error(message)
                case .ready, .scanning, .backgroundScanning:
                    return nil
                }
            },
            set: { newValue in
                if newValue == nil {
                    // Reset state when sheet is dismissed, clear text only on result dismiss
                    let wasResult: Bool
                    if case .result = viewModel.scanState {
                        wasResult = true
                    } else {
                        wasResult = false
                    }
                    viewModel.resetScan()
                    if wasResult {
                        manualInputText = ""
                    }
                }
            }
        )
    }
}

// Enum to handle different sheet destinations
// Ensure this is defined, either here or globally, but only once accessible to ScanView
enum SheetDestination: Identifiable, Equatable {
    case results(BuyEuropeanResponse, UIImage?)
    case error(String)

    var id: String {
        switch self {
        case .results(let response, _):
            return "results-\(response.id)"  // Assumes BuyEuropeanResponse has stable `id`
        case .error(let message):
            // Consider hashing message or using a UUID if messages aren't unique enough for ID
            return "error-\(message.hashValue)"
        }
    }

    // Equatable needed for Binding item comparison
    static func == (lhs: SheetDestination, rhs: SheetDestination) -> Bool {
        lhs.id == rhs.id
    }
}

// REMOVED the placeholder BuyEuropeanResponse definition from here.
// Ensure it's defined properly in your main models file.