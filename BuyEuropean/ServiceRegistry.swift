import Foundation
import SwiftUI
// import UIKit // Removed as it seems unnecessary and caused an error

/// A centralized registry for all services in the BuyEuropean app.
/// This class is marked as @MainActor to ensure all service access happens on the main thread.
@MainActor
class ServiceRegistry: ObservableObject {
    static let shared = ServiceRegistry()
    
    let apiService: APIService
    let imageService: ImageService
    let permissionService: PermissionService
    let locationManager: LocationManager
    
    private init() {
        self.apiService = APIService.shared
        self.imageService = ImageService.shared
        self.permissionService = PermissionService.shared
        
        // Create and configure LocationManager
        let lm = LocationManager()
        self.locationManager = lm
        
        // Inject LocationManager into APIService
        self.apiService.setLocationManager(lm)
    }
}