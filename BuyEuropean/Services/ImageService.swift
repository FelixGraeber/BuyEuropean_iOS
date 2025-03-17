import UIKit
import SwiftUI

class ImageService {
    static let shared = ImageService()
    
    init() {}
    
    func convertImageToBase64(image: UIImage, compressionQuality: CGFloat = 0.7) -> String? {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
    
    func resizeImage(image: UIImage) -> UIImage {
        let maxSize: CGFloat = 512
        let originalSize = image.size
        
        // Calculate the scale factor based on the longest side.
        let scaleFactor = maxSize / max(originalSize.width, originalSize.height)
        let newSize = CGSize(width: originalSize.width * scaleFactor,
                             height: originalSize.height * scaleFactor)
        
        // Use UIGraphicsImageRenderer for modern image drawing.
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let newImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return newImage
    }
}