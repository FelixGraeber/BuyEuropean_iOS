import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String?
    @Published var currentCountry: String?

    override init() {
        #if os(iOS)
        self.authorizationStatus = locationManager.authorizationStatus
        #else
        self.authorizationStatus = .notDetermined // Example default
        #endif
        super.init()
        locationManager.delegate = self
        #if os(iOS)
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        #endif
    }

    // MARK: - Permission Handling
    
    /// Call this, for example, on app launch if status is notDetermined
    func requestLocationPermissionIfNeeded() {
        #if os(iOS)
        if authorizationStatus == .notDetermined {
            print("Location Manager: Status is notDetermined, requesting WhenInUse authorization.")
            locationManager.requestWhenInUseAuthorization()
        } else if isAuthorized {
             print("Location Manager: Already authorized. Requesting initial location.")
             requestSingleLocationUpdate() // Request location if already authorized on init
        } else {
            print("Location Manager: Status is \(authorizationStatus.description), permission previously denied or restricted.")
        }
        #else
        print("Location permission request not supported on this platform.")
        #endif
    }

    #if os(iOS)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("Location authorization status changed to: \(self.authorizationStatus.description)")
            
            // If permission granted, request location (no setting check needed)
            if self.isAuthorized {
                self.requestSingleLocationUpdate()
            } else {
                // If permission revoked, clear location data
                self.currentLocation = nil
                self.currentCity = nil
                self.currentCountry = nil
            }
        }
    }
    #endif
    
    var isAuthorized: Bool {
        #if os(iOS)
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        #else
        false
        #endif
    }

    // MARK: - Location Updates

    /// Requests a single location update.
    func requestSingleLocationUpdate() {
        // Ensure permission is granted before requesting
        guard isAuthorized else {
            print("Cannot request location: Not authorized.")
            // Don't request permission here automatically, let it be triggered explicitly
            // (e.g., by requestLocationPermissionIfNeeded)
            return
        }
        print("Requesting single location update...")
        #if os(iOS)
        locationManager.requestLocation() // Fetches one location fix
        #else
        print("requestLocation() not supported on this platform.")
        #endif
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            // Only update if still authorized (user could revoke between request and update)
            if self.isAuthorized {
                self.currentLocation = location
                print("Location updated: \(location.coordinate)")
                self.reverseGeocode(location: location)
            } else {
                 print("Location received but authorization revoked. Clearing data.")
                 self.currentLocation = nil
                 self.currentCity = nil
                 self.currentCountry = nil
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.currentLocation = nil
            self.currentCity = nil
            self.currentCountry = nil
        }
    }

    // MARK: - Reverse Geocoding

    private func reverseGeocode(location: CLLocation) {
        guard !geocoder.isGeocoding else { return }
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                 // Check authorization again in the callback
                 guard self.isAuthorized else {
                     print("Reverse geocode completed but authorization revoked. Clearing data.")
                     self.currentCity = nil
                     self.currentCountry = nil
                     return
                 }

                if let error = error {
                    print("Reverse geocoding failed: \(error.localizedDescription)")
                    self.currentCity = nil
                    self.currentCountry = nil
                    return
                }
                
                if let placemark = placemarks?.first {
                    self.currentCity = placemark.locality
                    self.currentCountry = placemark.country
                    print("Reverse geocoded: City - \(self.currentCity ?? "N/A"), Country - \(self.currentCountry ?? "N/A")")
                } else {
                    print("No placemark found for the location.")
                    self.currentCity = nil
                    self.currentCountry = nil
                }
            }
        }
    }
}

// Helper extension for CLAuthorizationStatus description
#if os(iOS)
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
}
#endif 