import Foundation
import SwiftUI

/// A centralized registry for all services in the BuyEuropean app.
/// This class is marked as @MainActor to ensure all service access happens on the main thread.
@MainActor
class ServiceRegistry: ObservableObject {
    static let shared = ServiceRegistry()
    
    let apiService: APIService
    let imageService: ImageService
    let permissionService: PermissionService
    
    private init() {
        self.apiService = APIService.shared
        self.imageService = ImageService()
        self.permissionService = PermissionService()
    }
}
