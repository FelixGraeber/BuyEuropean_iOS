import CoreLocation
import SwiftUI

// Enum to represent location permission status, similar to Camera's
enum LocationPermissionStatus {
    case notDetermined
    case authorized
    case denied
}

// Service to manage location permissions and requests
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    
    // Defer initialization of locationManager until needed
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    // Track if locationManager was accessed
    private var isLocationManagerInitialized = false
    
    @Published private(set) var authorizationStatus: LocationPermissionStatus = .notDetermined
    
    override init() {
        super.init()
        // DON'T initialize the location manager here
        // Instead, just check the current status without accessing locationManager
        updateAuthorizationStatusWithoutManager()
    }
    
    // Update status without initializing the location manager
    private func updateAuthorizationStatusWithoutManager() {
        let currentStatus = CLLocationManager().authorizationStatus

        DispatchQueue.main.async {
            switch currentStatus {
            case .notDetermined:
                self.authorizationStatus = .notDetermined
            case .authorizedAlways, .authorizedWhenInUse:
                self.authorizationStatus = .authorized
            case .denied, .restricted:
                self.authorizationStatus = .denied
            @unknown default:
                self.authorizationStatus = .denied
            }
        }
    }
    
    // Only call this when updating status is needed after manager is initialized
    private func updateAuthorizationStatus() {
        let currentStatus: CLAuthorizationStatus
        
        if isLocationManagerInitialized {
            currentStatus = locationManager.authorizationStatus
            
            DispatchQueue.main.async {
                switch currentStatus {
                case .notDetermined:
                    self.authorizationStatus = .notDetermined
                case .authorizedAlways, .authorizedWhenInUse:
                    self.authorizationStatus = .authorized
                case .denied, .restricted:
                    self.authorizationStatus = .denied
                @unknown default:
                    self.authorizationStatus = .denied
                }
            }
        } else {
            updateAuthorizationStatusWithoutManager()
        }
    }
    
    // Request "When In Use" authorization - ONLY this method should trigger the prompt
    func requestWhenInUseAuthorization() {
        print("[LocationService] requestWhenInUseAuthorization called. Current status: \(authorizationStatus)")
        
        // Only request if status is not determined
        if authorizationStatus == .notDetermined {
            print("[LocationService] Status is notDetermined. Calling locationManager.requestWhenInUseAuthorization()")
            // This will initialize the location manager and trigger the prompt
            isLocationManagerInitialized = true
            locationManager.requestWhenInUseAuthorization()
        } else {
            print("[LocationService] Status is already \(authorizationStatus). Not requesting.")
        }
    }
    
    // CLLocationManagerDelegate method - called when authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus()
    }
    
    // Older delegate method for iOS < 14
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if #unavailable(iOS 14.0) {
            updateAuthorizationStatus()
        }
    }
}
