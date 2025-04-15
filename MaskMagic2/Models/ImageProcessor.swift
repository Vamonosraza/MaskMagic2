//
//  ImageProcessor.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//

import UIKit
import Combine

class ImageProcessor {
    private let openAIService = OpenAIService()
    private let maskGenerator = MaskGenerator()
    
    func processImage(originalImage: UIImage, prompt: String, maskType: MaskType) -> AnyPublisher<UIImage, Error> {
        print("📱 ImageProcessor: Processing image with prompt: \(prompt), maskType: \(maskType)")
        
        // First prepare the image (crop to square and resize)
        guard let preparedImage = maskGenerator.prepareImageForOpenAI(image: originalImage) else {
            print("⚠️ ImageProcessor: Failed to prepare image")
            return Fail(error: NSError(domain: "ImageProcessor", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare image"]))
                .eraseToAnyPublisher()
        }
        print("📱 ImageProcessor: Successfully prepared image for OpenAI with size: \(preparedImage.size)")
        
        // Check if the image needs compression
        guard let imageData = preparedImage.pngData() else {
            print("⚠️ ImageProcessor: Failed to convert image to PNG data")
            return Fail(error: NSError(domain: "ImageProcessor", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG format"]))
                .eraseToAnyPublisher()
        }
        
        let imageSizeMB = Double(imageData.count) / (1024 * 1024)
        print("📱 ImageProcessor: Image size: \(imageSizeMB) MB")
        
        // Compress if needed
        var finalImage = preparedImage
        if imageSizeMB > 3.9 {
            print("📱 ImageProcessor: Image is too large, resizing to reduce size")
            // Resize to smaller dimensions
            let targetSize = CGSize(width: 512, height: 512) // Try a smaller size
            
            UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)  // Scale 1.0 for exact pixel dimensions
            preparedImage.draw(in: CGRect(origin: .zero, size: targetSize))
            if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                finalImage = resizedImage
                print("📱 ImageProcessor: Resized image to \(finalImage.size) with scale \(finalImage.scale)")
            }
            UIGraphicsEndImageContext()
            
            // Check if its still too large
            if let resizedData = finalImage.pngData(), Double(resizedData.count) / (1024 * 1024) > 3.9 {
                print("⚠️ ImageProcessor: Image is still too large after resizing")
                return Fail(error: NSError(domain: "ImageProcessor", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Image is too large for the API (>4MB)"]))
                    .eraseToAnyPublisher()
            }
        }
        
        // Generate the mask based on type
        guard let mask = maskType == .circle ?
                  maskGenerator.generateCenterMask(for: finalImage) :
                  maskGenerator.generateCenterRectMask(for: finalImage) else {
            print("⚠️ ImageProcessor: Failed to generate mask")
            return Fail(error: NSError(domain: "ImageProcessor", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to generate mask"]))
                .eraseToAnyPublisher()
        }
        print("📱 ImageProcessor: Generated mask with size: \(mask.size)")
        
        // ADDITIONAL CHECK: Make sure the mask size matches the image size exactly
        if mask.size != finalImage.size || mask.scale != finalImage.scale {
            print("⚠️ ImageProcessor: Mask size (\(mask.size) scale \(mask.scale)) doesn't match image size (\(finalImage.size) scale \(finalImage.scale)) - attempting to fix")
            
            guard let fixedMask = ensureMaskMatchesImageSize(mask: mask, image: finalImage) else {
                print("⚠️ ImageProcessor: Failed to fix mask size")
                return Fail(error: NSError(domain: "ImageProcessor", code: 1004, userInfo: [NSLocalizedDescriptionKey: "The mask and image sizes don't match and couldn't be fixed"]))
                    .eraseToAnyPublisher()
            }
            
            print("📱 ImageProcessor: Fixed mask to match image size (\(fixedMask.size) scale \(fixedMask.scale))")
            
            // Call OpenAI API to generate the image with fixed mask
            print("📱 ImageProcessor: Calling OpenAI API to generate image with fixed mask")
            return openAIService.generateImage(originalImage: finalImage, mask: fixedMask, prompt: prompt)
                .handleEvents(
                    receiveOutput: { _ in
                        print("📱 ImageProcessor: Received generated image")
                    },
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("📱 ImageProcessor: Image generation completed successfully")
                        case .failure(let error):
                            print("⚠️ ImageProcessor: Image generation failed with error: \(error.localizedDescription)")
                        }
                    }
                )
                .eraseToAnyPublisher()
        }
        
        // Call OpenAI API to generate the image
        print("📱 ImageProcessor: Calling OpenAI API to generate image")
        return openAIService.generateImage(originalImage: finalImage, mask: mask, prompt: prompt)
            .handleEvents(
                receiveOutput: { _ in
                    print("📱 ImageProcessor: Received generated image")
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("📱 ImageProcessor: Image generation completed successfully")
                    case .failure(let error):
                        print("⚠️ ImageProcessor: Image generation failed with error: \(error.localizedDescription)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    // Helper function to ensure mask size matches image size exactly
    private func ensureMaskMatchesImageSize(mask: UIImage, image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        mask.draw(in: CGRect(origin: .zero, size: image.size))
        let newMask = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newMask
    }
}

enum MaskType {
    case circle
    case rectangle
}
