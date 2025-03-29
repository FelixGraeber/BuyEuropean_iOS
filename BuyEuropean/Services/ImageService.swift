import Foundation
import SwiftUI
import UIKit

class ImageService {
    static let shared = ImageService()
    
    /// Ensures the image is square by cropping from the center
    func ensureSquareImage(image: UIImage) -> UIImage {
        let size = min(image.size.width, image.size.height)
        let x = (image.size.width - size) / 2
        let y = (image.size.height - size) / 2
        
        // Create a square CGRect to crop the image
        let cropRect = CGRect(x: x, y: y, width: size, height: size)
        
        // Perform the crop
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        // Return original image if cropping fails
        return image
    }
    
    /// Resizes the image to a maximum dimension while preserving aspect ratio
    func resizeImage(image: UIImage, maxDimension: CGFloat = 768) -> UIImage {
        let originalSize = image.size
        var newSize: CGSize
        
        if originalSize.width > originalSize.height {
            newSize = CGSize(width: maxDimension, height: maxDimension * originalSize.height / originalSize.width)
        } else {
            newSize = CGSize(width: maxDimension * originalSize.width / originalSize.height, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    /// Converts an image to base64 string
    func convertImageToBase64(image: UIImage, compressionQuality: CGFloat = 0.7) -> String? {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
}