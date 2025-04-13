//
//  ImagePicker.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("📱 ImagePicker: Creating UIImagePickerController with sourceType: \(sourceType)")
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            print("📱 ImagePicker: Source type \(sourceType) is available")
            picker.sourceType = sourceType
        } else {
            print("⚠️ ImagePicker: Source type \(sourceType) is NOT available, falling back to .photoLibrary")
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
            print("📱 ImagePicker.Coordinator: Initialized")
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📱 ImagePicker.Coordinator: Image selected")
            
            if let image = info[.originalImage] as? UIImage {
                print("📱 ImagePicker.Coordinator: Got image of size: \(image.size)")
                parent.selectedImage = image
                parent.onImagePicked()
            } else {
                print("⚠️ ImagePicker.Coordinator: Failed to get image from info dictionary")
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📱 ImagePicker.Coordinator: Image picker cancelled")
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
