//
//  ImageCompression.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//

import UIKit

class ImageCompression {
    static func compressImageToMaxSizeInMB(image: UIImage, maxSizeMB: Double = 3.9) -> UIImage? {
        // Start with PNG data to check if it's already small enough
        guard let pngData = image.pngData() else {
            print("⚠️ ImageCompression: Failed to get PNG data from image")
            return nil
        }
        
        let pngSizeMB = Double(pngData.count) / (1024 * 1024)
        print("📱 ImageCompression: Original PNG size: \(pngSizeMB) MB")
        
        if pngSizeMB <= maxSizeMB {
            return image
        }
        
        // If PNG is too large, try resizing
        let currentSize = image.size
        var newSize = currentSize
        var scaleFactor: CGFloat = 1.0
        
        // Try different scale factors until we find one that works
        while true {
            scaleFactor *= 0.8
            newSize = CGSize(width: currentSize.width * scaleFactor, height: currentSize.height * scaleFactor)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let imageData = resizedImage?.pngData() else {
                break
            }
            
            let newSizeMB = Double(imageData.count) / (1024 * 1024)
            print("📱 ImageCompression: Resized image to \(newSize.width)x\(newSize.height), size: \(newSizeMB) MB")
            
            if newSizeMB <= maxSizeMB || scaleFactor < 0.3 {
                return resizedImage
            }
        }
        
        // If resizing doesn't work, try JPEG compression
        var compressionQuality: CGFloat = 0.9
        while compressionQuality > 0.1 {
            guard let jpegData = image.jpegData(compressionQuality: compressionQuality),
                  let compressedImage = UIImage(data: jpegData) else {
                compressionQuality -= 0.1
                continue
            }
            
            let jpegSizeMB = Double(jpegData.count) / (1024 * 1024)
            print("📱 ImageCompression: JPEG compression quality \(compressionQuality), size: \(jpegSizeMB) MB")
            
            if jpegSizeMB <= maxSizeMB {
                return compressedImage
            }
            
            compressionQuality -= 0.1
        }
        
        print("⚠️ ImageCompression: Failed to compress image below \(maxSizeMB) MB")
        return nil
    }
    
    static func ensureValidMaskFormat(mask: UIImage) -> UIImage? {
        let size = mask.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        mask.draw(at: .zero)
        
        let validMask = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Make sure the mask has an alpha channel
        if let pngData = validMask?.pngData(), let pngMask = UIImage(data: pngData) {
            return pngMask
        }
        
        return nil
    }
}
