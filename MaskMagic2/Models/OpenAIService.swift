//
//  OpenAIService.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//

import Foundation
import UIKit
import Combine

class OpenAIService {
    private let apiKey = Configuration.openAIAPIKey
    
    func generateImage(originalImage: UIImage, mask: UIImage, prompt: String) -> AnyPublisher<UIImage, Error> {
        print("📱 OpenAIService: Starting image generation with prompt: \(prompt)")

        // Fix the orientation of the original image
        let uprightImage = fixOrientation(for: originalImage)

        // Log the corrected image size and orientation
        print("📱 OpenAIService: Image size after orientation fix: \(uprightImage.size), scale: \(uprightImage.scale)")

        // Ensure the mask and image sizes match
        if uprightImage.size != mask.size {
            print("⚠️ OpenAIService: ERROR - Image size (\(uprightImage.size)) and mask size (\(mask.size)) don't match")
            return Fail(error: NSError(domain: "OpenAIService", code: 1008, userInfo: [NSLocalizedDescriptionKey: "Image size and mask size don't match"]))
                .eraseToAnyPublisher()
        }

        // Prepare the image data
        guard let imageData = uprightImage.pngData() else {
            print("⚠️ OpenAIService: Failed to convert image to PNG data")
            return Fail(error: NSError(domain: "OpenAIService", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG format"]))
                .eraseToAnyPublisher()
        }

        guard let maskData = mask.pngData() else {
            print("⚠️ OpenAIService: Failed to convert mask to PNG data")
            return Fail(error: NSError(domain: "OpenAIService", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Failed to convert mask to PNG format"]))
                .eraseToAnyPublisher()
        }

        // Check file sizes
        let imageSizeMB = Double(imageData.count) / (1024 * 1024)
        let maskSizeMB = Double(maskData.count) / (1024 * 1024)

        print("📱 OpenAIService: Image file size: \(imageSizeMB) MB")
        print("📱 OpenAIService: Mask file size: \(maskSizeMB) MB")

        if imageSizeMB >= 4.0 {
            print("⚠️ OpenAIService: Image size exceeds 4MB limit (\(imageSizeMB) MB)")
            return Fail(error: NSError(domain: "OpenAIService", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Image size exceeds 4MB limit (\(String(format: "%.2f", imageSizeMB)) MB)"]))
                .eraseToAnyPublisher()
        }

        if maskSizeMB >= 4.0 {
            print("⚠️ OpenAIService: Mask size exceeds 4MB limit (\(maskSizeMB) MB)")
            return Fail(error: NSError(domain: "OpenAIService", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Mask size exceeds 4MB limit (\(String(format: "%.2f", maskSizeMB)) MB)"]))
                .eraseToAnyPublisher()
        }

        let url = URL(string: Configuration.openAIEndpoint)!
        print("📱 OpenAIService: Making request to \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Create multipart form data with already-checked data
        print("📱 OpenAIService: Creating multipart form data with boundary \(boundary)")
        let httpBody = createMultipartFormData(
            boundary: boundary,
            imageData: imageData,
            maskData: maskData,
            prompt: prompt
        )

        print("📱 OpenAIService: Form data size: \(httpBody.count) bytes")
        request.httpBody = httpBody

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                // Log response status code and headers
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "OpenAIService", code: 1007, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
                }

                print("📱 OpenAIService: Received response with status code: \(httpResponse.statusCode)")
                print("📱 OpenAIService: Response headers: \(httpResponse.allHeaderFields)")

                // Log response data
                print("📱 OpenAIService: Received data of size: \(data.count) bytes")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📱 OpenAIService: Response JSON: \(jsonString)")
                }

                // Check for error responses
                if !(200...299).contains(httpResponse.statusCode) {
                    // Try to extract error message
                    if let jsonString = String(data: data, encoding: .utf8),
                       jsonString.contains("error") {
                        
                        // Try to extract error message
                        if let errorMessage = self.extractErrorMessage(from: data) {
                            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [
                                NSLocalizedDescriptionKey: errorMessage
                            ])
                        }
                    }

                    // If we can't decode the specific error, throw a generic one
                    throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "API error with status code: \(httpResponse.statusCode)"
                    ])
                }

                return data
            }
            .decode(type: OpenAIResponse.self, decoder: JSONDecoder())
            .handleEvents(receiveOutput: { response in
                print("📱 OpenAIService: Decoded response successfully")
                if let url = response.data.first?.url {
                    print("📱 OpenAIService: Image URL received: \(url)")
                } else {
                    print("⚠️ OpenAIService: No image URL in response")
                }
            })
            .flatMap { response -> AnyPublisher<UIImage, Error> in
                guard let imageUrl = URL(string: response.data.first?.url ?? "") else {
                    print("⚠️ OpenAIService: Invalid image URL")
                    return Fail(error: NSError(domain: "OpenAIService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid image URL"]))
                        .eraseToAnyPublisher()
                }

                print("📱 OpenAIService: Downloading image from: \(imageUrl)")
                return URLSession.shared.dataTaskPublisher(for: imageUrl)
                    .map { $0.data }
                    .tryMap { data -> UIImage in
                        print("📱 OpenAIService: Received image data of size: \(data.count) bytes")
                        if let image = UIImage(data: data) {
                            print("📱 OpenAIService: Successfully created UIImage from data")
                            return self.fixOrientation(for: image)
                        } else {
                            print("⚠️ OpenAIService: Failed to create UIImage from data")
                            throw NSError(domain: "OpenAIService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func createMultipartFormData(boundary: String, imageData: Data, maskData: Data, prompt: String) -> Data {
        var body = Data()

        // Add the image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add the mask
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"mask\"; filename=\"mask.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(maskData)
        body.append("\r\n".data(using: .utf8)!)

        // Add the prompt
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(prompt)".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add the model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("dall-e-2".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add the size
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"size\"\r\n\r\n".data(using: .utf8)!)
        body.append("1024x1024".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add the response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("url".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add the boundary end marker
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
    }
    
    private func fixOrientation(for image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image // Already upright
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let uprightImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return uprightImage ?? image
    }
    
    private func extractErrorMessage(from data: Data) -> String? {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDict = json["error"] as? [String: Any],
               let message = errorDict["message"] as? String {
                return message
            }
        } catch {
            print("⚠️ OpenAIService: Error parsing error response: \(error)")
        }
        return nil
    }
}

// Response model for OpenAI API
struct OpenAIResponse: Decodable {
    let created: Int
    let data: [ImageData]
    
    struct ImageData: Decodable {
        let url: String?
    }
}
