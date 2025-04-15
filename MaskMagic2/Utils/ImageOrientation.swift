//
//  ImageOrientation.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/15/25.
//

import UIKit

extension UIImage {
    static func logImageDetails(_ image: UIImage?, label: String) {
        guard let image = image else {
            print("⚠️ \(label): Image is nil")
            return
        }
        
        print("📱 \(label): Orientation: \(describeOrientation(image.imageOrientation))")
        print("📱 \(label): Size: \(image.size.width)x\(image.size.height)")
        print("📱 \(label): Scale: \(image.scale)")
    }
    
    static func describeOrientation(_ orientation: UIImage.Orientation) -> String {
        switch orientation {
        case .up: return "UP (0°)"
        case .down: return "DOWN (180°)"
        case .left: return "LEFT (90° CCW)"
        case .right: return "RIGHT (90° CW)"
        case .upMirrored: return "UP MIRRORED"
        case .downMirrored: return "DOWN MIRRORED"
        case .leftMirrored: return "LEFT MIRRORED"
        case .rightMirrored: return "RIGHT MIRRORED"
        @unknown default: return "UNKNOWN"
        }
    }
}
