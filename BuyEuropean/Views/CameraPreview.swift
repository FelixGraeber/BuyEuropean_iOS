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
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Camera Service
class CameraService: NSObject, ObservableObject {
    @Published private(set) var state: Camera.State = .initializing
    @Published private(set) var session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var completionHandler: ((Result<UIImage, Camera.Error>) -> Void)?
    
    // Add a flag to track if setup is in progress
    private var isSettingUp = false
    
    override init() {
        super.init()
        // Don't set state to initializing here, as it will be set in checkPermissionsAndSetup
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
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
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
        
        completionHandler?(.success(image))
    }
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