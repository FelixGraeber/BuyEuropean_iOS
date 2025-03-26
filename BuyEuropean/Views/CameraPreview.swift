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

// Custom UIView subclass to automatically update the previewLayer frame during layout
class CameraPreviewView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let previewLayer = self.layer.sublayers?.compactMap({ $0 as? AVCaptureVideoPreviewLayer }).first {
            previewLayer.frame = self.bounds
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    // Use isSquare to determine if the viewfinder should be square with rounded corners
    let isSquare: Bool
    
    init(session: AVCaptureSession, isSquare: Bool = false) {
        self.session = session
        self.isSquare = isSquare
    }
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        if isSquare {
            view.layer.cornerRadius = 12
            view.clipsToBounds = true
        }
        
        view.layer.addSublayer(previewLayer)
        
        // Notify CameraService if needed (optional)
        _ = findCameraService(for: session)
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.setNeedsLayout()
    }
    
    // Helper to notify about creation of the previewLayer. Returns nil by default.
    private func findCameraService(for session: AVCaptureSession) -> CameraService? {
        NotificationCenter.default.post(name: .didCreatePreviewLayer, object: session)
        return nil
    }
}

// MARK: - Camera Service
// The CameraService code remains unchanged below.

class CameraService: NSObject, ObservableObject {
    @Published private(set) var state: Camera.State = .initializing
    @Published private(set) var session = AVCaptureSession()
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    private let output = AVCapturePhotoOutput()
    private var completionHandler: ((Result<UIImage, Camera.Error>) -> Void)?
    
    // Reference to the preview layer for cropping purposes
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var isSettingUp = false
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handlePreviewLayerCreation(_:)), name: .didCreatePreviewLayer, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handlePreviewLayerCreation(_ notification: Notification) {
        if let notifiedSession = notification.object as? AVCaptureSession, notifiedSession === session {
            // The previewLayer is set in CameraPreview; further handling can be done here if needed.
        }
    }
    
    func checkPermissionsAndSetup() {
        guard !isSettingUp else {
            print("Camera setup already in progress, ignoring duplicate call")
            return
        }
        
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
        isSettingUp = true
        state = .initializing
        
        if session.isRunning {
            print("Camera session already running, stopping before reconfiguration")
            session.stopRunning()
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.configureCameraSession()
                
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
        guard !session.isRunning else {
            print("Session already running, skipping configuration")
            return
        }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            throw Camera.Error.noCamera
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw Camera.Error.setupFailed(NSError(domain: "CameraService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"]))
        }
        session.addInput(input)
        
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
        
        let processedImage = processImage(image)
        
        if let previewLayer = self.previewLayer, let croppedImage = cropImageToMatchPreview(processedImage, previewLayer: previewLayer) {
            completionHandler?(.success(croppedImage))
        } else {
            completionHandler?(.success(processedImage))
        }
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        if cameraPosition == .front {
            if let cgImage = image.cgImage {
                return UIImage(
                    cgImage: cgImage,
                    scale: image.scale,
                    orientation: image.imageOrientation == .right ? .leftMirrored : .rightMirrored
                )
            }
        }
        return image
    }
    
    private func cropImageToMatchPreview(_ image: UIImage, previewLayer: AVCaptureVideoPreviewLayer) -> UIImage? {
        guard let connection = output.connection(with: .video) else {
            return nil
        }
        let cropRect = calculateCropRect(for: image, previewLayer: previewLayer, connection: connection)
        
        guard let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func calculateCropRect(for image: UIImage, previewLayer: AVCaptureVideoPreviewLayer, connection: AVCaptureConnection) -> CGRect {
        let imageWidth = CGFloat(image.cgImage?.width ?? 0)
        let imageHeight = CGFloat(image.cgImage?.height ?? 0)
        
        let layerBounds = previewLayer.bounds
        
        let layerRatio = layerBounds.width / layerBounds.height
        let imageRatio = imageWidth / imageHeight
        
        var cropRect: CGRect
        
        if imageRatio > layerRatio {
            let cropWidth = imageHeight * layerRatio
            let cropX = (imageWidth - cropWidth) / 2
            cropRect = CGRect(x: cropX, y: 0, width: cropWidth, height: imageHeight)
        } else {
            let cropHeight = imageWidth / layerRatio
            let cropY = (imageHeight - cropHeight) / 2
            cropRect = CGRect(x: 0, y: cropY, width: imageWidth, height: cropHeight)
        }
        
        let deviceOrientation = UIDevice.current.orientation
        if cameraPosition == .front && !deviceOrientation.isPortrait {
            cropRect.origin.x = imageWidth - cropRect.maxX
        }
        
        return cropRect
    }
}

extension Notification.Name {
    static let didCreatePreviewLayer = Notification.Name("CameraService.didCreatePreviewLayer")
}

extension Camera.State: Equatable {
    public static func == (lhs: Camera.State, rhs: Camera.State) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing),
             (.ready, .ready),
             (.capturing, .capturing):
            return true
        case (.error(let e1), .error(let e2)):
            return e1.localizedDescription == e2.localizedDescription
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