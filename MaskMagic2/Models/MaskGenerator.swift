//
//  MaskGenerator.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//

import UIKit
import CoreImage

class MaskGenerator {
    // Generate a mask with a transparent circle in the center
    func generateCenterMask(for image: UIImage, centerPercentage: CGFloat = 0.5) -> UIImage? {
        print("📱 MaskGenerator: Generating circle mask for image size: \(image.size), centerPercentage: \(centerPercentage)")
        
        // CRITICAL: Use the exact same size as the input image
        let size = image.size
        
        // Ensure we have a valid size
        guard size.width > 0 && size.height > 0 else {
            print("⚠️ MaskGenerator: Invalid image size: \(size)")
            return nil
        }
        
        // Use the same scale as the original image to ensure same pixel dimensions
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            print("⚠️ MaskGenerator: Failed to get graphics context")
            return nil
        }
        
        // Fill the entire context with black (opaque)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Create a transparent circle in the center
        let centerX = size.width / 2
        let centerY = size.height / 2
        let circleRadius = min(size.width, size.height) * centerPercentage / 2
        
        print("📱 MaskGenerator: Creating transparent circle at center (\(centerX), \(centerY)) with radius \(circleRadius)")
        
        context.setBlendMode(.clear)
        context.setFillColor(UIColor.clear.cgColor)
        context.fillEllipse(in: CGRect(
            x: centerX - circleRadius,
            y: centerY - circleRadius,
            width: circleRadius * 2,
            height: circleRadius * 2
        ))
        
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if maskImage == nil {
            print("⚠️ MaskGenerator: Failed to create mask image")
        } else {
            print("📱 MaskGenerator: Successfully generated circle mask with size: \(maskImage!.size)")
            
            // Verify size matches
            if maskImage!.size != image.size {
                print("⚠️ MaskGenerator: WARNING - Mask size (\(maskImage!.size)) doesn't match image size (\(image.size))")
            }
        }
        
        return maskImage
    }
    
    // Generate a mask with a transparent rectangle in the center
    func generateCenterRectMask(for image: UIImage, centerPercentage: CGFloat = 0.5) -> UIImage? {
        print("📱 MaskGenerator: Generating rectangle mask for image size: \(image.size), centerPercentage: \(centerPercentage)")
        
        // CRITICAL: Use the exact same size as the input image
        let size = image.size
        
        // Ensure we have a valid size
        guard size.width > 0 && size.height > 0 else {
            print("⚠️ MaskGenerator: Invalid image size: \(size)")
            return nil
        }
        
        // Use the same scale as the original image to ensure same pixel dimensions
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            print("⚠️ MaskGenerator: Failed to get graphics context")
            return nil
        }
        
        // Fill the entire context with black (opaque)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Create a transparent rectangle in the center
        let centerX = size.width / 2
        let centerY = size.height / 2
        let rectWidth = size.width * centerPercentage
        let rectHeight = size.height * centerPercentage
        
        print("📱 MaskGenerator: Creating transparent rectangle at center (\(centerX), \(centerY)) with size \(rectWidth) x \(rectHeight)")
        
        context.setBlendMode(.clear)
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(CGRect(
            x: centerX - rectWidth / 2,
            y: centerY - rectHeight / 2,
            width: rectWidth,
            height: rectHeight
        ))
        
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if maskImage == nil {
            print("⚠️ MaskGenerator: Failed to create mask image")
        } else {
            print("📱 MaskGenerator: Successfully generated rectangle mask with size: \(maskImage!.size)")
            
            // Verify size matches
            if maskImage!.size != image.size {
                print("⚠️ MaskGenerator: WARNING - Mask size (\(maskImage!.size)) doesn't match image size (\(image.size))")
            }
        }
        
        return maskImage
    }
    
    // Ensure image is square and correctly sized for OpenAI API
    func prepareImageForOpenAI(image: UIImage) -> UIImage? {
        print("📱 MaskGenerator: Preparing image for OpenAI, original size: \(image.size)")
        
        // Check for valid input
        guard image.size.width > 0 && image.size.height > 0 else {
            print("⚠️ MaskGenerator: Invalid image size: \(image.size)")
            return nil
        }
        
        // OpenAI requires square images
        let size = min(image.size.width, image.size.height)
        let x = (image.size.width - size) / 2
        let y = (image.size.height - size) / 2
        
        print("📱 MaskGenerator: Cropping to square size: \(size)x\(size) at position: (\(x), \(y))")
        
        let cropRect = CGRect(x: x, y: y, width: size, height: size)
        
        // Try to safely crop the image
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            print("⚠️ MaskGenerator: Failed to crop image")
            return nil
        }
        
        let croppedImage = UIImage(cgImage: cgImage)
        print("📱 MaskGenerator: Successfully cropped image to size: \(croppedImage.size)")
        
        // Target a size that works well with OpenAI's API
        // We'll use 1024x1024 which is a standard size for DALL-E
        let targetSize = CGSize(width: 1024, height: 1024)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0) // Set scale to 1.0 for exact pixel dimensions
        croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let resizedImage = resizedImage {
            print("📱 MaskGenerator: Successfully resized image to \(resizedImage.size) with scale \(resizedImage.scale)")
            
            // Check final image size
            if let data = resizedImage.pngData() {
                let sizeInMB = Double(data.count) / (1024 * 1024)
                print("📱 MaskGenerator: Final prepared image size: \(sizeInMB) MB")
                
                if sizeInMB > 3.9 {
                    print("⚠️ MaskGenerator: Image is still too large (\(sizeInMB) MB), trying to make smaller")
                    
                    // If still too large, try a smaller size
                    let smallerSize = CGSize(width: 512, height: 512)
                    UIGraphicsBeginImageContextWithOptions(smallerSize, false, 1.0)
                    resizedImage.draw(in: CGRect(origin: .zero, size: smallerSize))
                    let smallerImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    if let smallerImage = smallerImage {
                        print("📱 MaskGenerator: Resized to smaller image: \(smallerImage.size) with scale \(smallerImage.scale)")
                        return smallerImage
                    }
                }
            }
            
            return resizedImage
        } else {
            print("⚠️ MaskGenerator: Failed to resize image")
            return nil
        }
    }
}
