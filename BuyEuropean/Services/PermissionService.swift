import AVFoundation
import SwiftUI

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
}

class PermissionService: ObservableObject {
    static let shared = PermissionService()
    
    @Published private(set) var cameraPermissionStatus: PermissionStatus = .notDetermined
    @AppStorage("hasShownCameraPermissionPrompt") private var hasShownPrompt = false
    
    private init() {
        updateCameraPermissionStatus()
    }
    
    func updateCameraPermissionStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async {
            switch status {
            case .notDetermined:
                self.cameraPermissionStatus = .notDetermined
            case .authorized:
                self.cameraPermissionStatus = .granted
            case .denied, .restricted:
                self.cameraPermissionStatus = .denied
            @unknown default:
                self.cameraPermissionStatus = .denied
            }
        }
    }
    
    func requestCameraPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            hasShownPrompt = true
            cameraPermissionStatus = granted ? .granted : .denied
        }
        return granted
    }
    
    var shouldShowPermissionPrompt: Bool {
        !hasShownPrompt && cameraPermissionStatus == .notDetermined
    }
}
