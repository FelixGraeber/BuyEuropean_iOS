import SwiftUI
import AVFoundation

// MARK: - Camera Types
enum Camera {
    enum State {
        case initializing
        case ready
        case capturing
        case error(Error)
        
        var isReady: Bool {
            if case .ready = self { return true }
            return false
        }
    }
    
    enum Error: LocalizedError {
        case notAuthorized
        case setupFailed(Swift.Error)
        case captureFailed(Swift.Error)
        case noCamera
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access is not authorized. Please enable it in Settings."
            case .setupFailed(let error):
                return "Failed to set up camera: \(error.localizedDescription)"
            case .captureFailed(let error):
                return "Failed to capture photo: \(error.localizedDescription)"
            case .noCamera:
                return "No camera available on this device."
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Store the previewLayer in the associated CameraService if possible
        if let cameraService = findCameraService(for: session) {
            cameraService.previewLayer = previewLayer
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    // Helper to find the CameraService instance associated with this session
    private func findCameraService(for session: AVCaptureSession) -> CameraService? {
        // Use NotificationCenter to find the CameraService
        NotificationCenter.default.post(name: .didCreatePreviewLayer, object: session)
        return nil
    }
}

// MARK: - Camera Service
class CameraService: NSObject, ObservableObject {
    @Published private(set) var state: Camera.State = .initializing
    @Published private(set) var session = AVCaptureSession()
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    private let output = AVCapturePhotoOutput()
    private var completionHandler: ((Result<UIImage, Camera.Error>) -> Void)?
    
    // Add a reference to the preview layer for cropping
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Add a flag to track if setup is in progress
    private var isSettingUp = false
    
    override init() {
        super.init()
        // Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handlePreviewLayerCreation(_:)), name: .didCreatePreviewLayer, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handlePreviewLayerCreation(_ notification: Notification) {
        if let notifiedSession = notification.object as? AVCaptureSession, notifiedSession === session {
            // The notification was for our session, but we still need to find the layer
            // This will be handled by the CameraPreview directly setting our previewLayer property
        }
    }
    
    func checkPermissionsAndSetup() {
        // Guard against multiple setup attempts
        guard !isSettingUp else {
            print("Camera setup already in progress, ignoring duplicate call")
            return
        }
        
        // Only reset state if not already initializing
        if case .initializing = state {} else {
            state = .initializing
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.isSettingUp = false
                        self?.state = .error(.notAuthorized)
                    }
                }
            }
        case .denied, .restricted:
            isSettingUp = false
            state = .error(.notAuthorized)
        @unknown default:
            isSettingUp = false
            state = .error(.notAuthorized)
        }
    }
    
    private func setupCamera() {
        // Set flag to indicate setup is in progress
        isSettingUp = true
        state = .initializing
        
        // Check if session is already running
        if session.isRunning {
            print("Camera session already running, stopping before reconfiguration")
            session.stopRunning()
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.configureCameraSession()
                
                // Only start session if it's not already running
                if !self.session.isRunning {
                    self.session.startRunning()
                }
                
                DispatchQueue.main.async {
                    self.isSettingUp = false
                    self.state = .ready
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSettingUp = false
                    self.state = .error(.setupFailed(error))
                }
            }
        }
    }
    
    private func configureCameraSession() throws {
        // Only configure if not already running
        guard !session.isRunning else {
            print("Session already running, skipping configuration")
            return
        }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Reset any existing inputs/outputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        // Configure camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            throw Camera.Error.noCamera
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw Camera.Error.setupFailed(NSError(domain: "CameraService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"]))
        }
        session.addInput(input)
        
        // Configure photo output
        guard session.canAddOutput(output) else {
            throw Camera.Error.setupFailed(NSError(domain: "CameraService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot add photo output"]))
        }
        session.addOutput(output)
    }
    
    func capturePhoto(completion: @escaping (Result<UIImage, Camera.Error>) -> Void) {
        guard case .ready = state else {
            completion(.failure(.setupFailed(NSError(domain: "CameraService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Camera not ready"]))))
            return
        }
        
        state = .capturing
        completionHandler = completion
        
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
        isSettingUp = false
        state = .initializing
    }
    
    func toggleCameraPosition() {
        cameraPosition = cameraPosition == .back ? .front : .back
        setupCamera()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Swift.Error?) {
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.state = .ready
            }
        }
        
        if let error = error {
            completionHandler?(.failure(.captureFailed(error)))
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completionHandler?(.failure(.captureFailed(NSError(domain: "CameraService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to process captured photo"]))))
            return
        }
        
        // Crop the image to match the preview's aspect ratio
        if let previewLayer = self.previewLayer, let croppedImage = cropImageToMatchPreview(image, previewLayer: previewLayer) {
            completionHandler?(.success(croppedImage))
        } else {
            completionHandler?(.success(image))
        }
    }
    
    // Helper method to crop the captured image to match what's shown in the preview
    private func cropImageToMatchPreview(_ image: UIImage, previewLayer: AVCaptureVideoPreviewLayer) -> UIImage? {
        // Get the connection from the output
        guard let connection = output.connection(with: .video) else {
            return nil
        }
        
        // Calculate the crop rect based on the preview layer's bounds and the image dimensions
        let cropRect = calculateCropRect(for: image, previewLayer: previewLayer, connection: connection)
        
        // Create a cropped image
        guard let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return nil
        }
        
        // Create a new UIImage with the cropped CGImage
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // Calculate the crop rect based on the preview layer's bounds and the image dimensions
    private func calculateCropRect(for image: UIImage, previewLayer: AVCaptureVideoPreviewLayer, connection: AVCaptureConnection) -> CGRect {
        // Get the image dimensions
        let imageWidth = CGFloat(image.cgImage?.width ?? 0)
        let imageHeight = CGFloat(image.cgImage?.height ?? 0)
        
        // Get the preview layer's bounds
        let layerBounds = previewLayer.bounds
        
        // Calculate the aspect ratio of the preview layer
        let layerRatio = layerBounds.width / layerBounds.height
        
        // Calculate the aspect ratio of the image
        let imageRatio = imageWidth / imageHeight
        
        // Calculate the crop rect
        var cropRect: CGRect
        
        if imageRatio > layerRatio {
            // Image is wider than the preview layer
            let cropWidth = imageHeight * layerRatio
            let cropX = (imageWidth - cropWidth) / 2
            cropRect = CGRect(x: cropX, y: 0, width: cropWidth, height: imageHeight)
        } else {
            // Image is taller than the preview layer
            let cropHeight = imageWidth / layerRatio
            let cropY = (imageHeight - cropHeight) / 2
            cropRect = CGRect(x: 0, y: cropY, width: imageWidth, height: cropHeight)
        }
        
        // Adjust for device orientation and camera position
        let deviceOrientation = UIDevice.current.orientation
        let isUsingFrontCamera = cameraPosition == .front
        
        // Adjust the crop rect based on the device orientation and camera position
        if deviceOrientation.isPortrait || deviceOrientation.isLandscape {
            // No adjustment needed for portrait orientation with back camera
            if isUsingFrontCamera && !deviceOrientation.isPortrait {
                // Flip horizontally for front camera in landscape
                cropRect.origin.x = imageWidth - cropRect.maxX
            }
        }
        
        return cropRect
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didCreatePreviewLayer = Notification.Name("CameraService.didCreatePreviewLayer")
}

// MARK: - Equatable conformance
extension Camera.State: Equatable {
    public static func == (lhs: Camera.State, rhs: Camera.State) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing):
            return true
        case (.ready, .ready):
            return true
        case (.capturing, .capturing):
            return true
        case (.error(let e1), .error(let e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

extension Camera.Error: Equatable {
    public static func == (lhs: Camera.Error, rhs: Camera.Error) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized):
            return true
        case let (.setupFailed(e1), .setupFailed(e2)):
            return e1.localizedDescription == e2.localizedDescription
        case let (.captureFailed(e1), .captureFailed(e2)):
            return e1.localizedDescription == e2.localizedDescription
        case (.noCamera, .noCamera):
            return true
        default:
            return false
        }
    }
}