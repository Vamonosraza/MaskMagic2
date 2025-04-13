//
//  ImageEditView.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//

import SwiftUI
import Combine

struct ImageEditView: View {
    let image: UIImage
    
    // Make sure initializer is explicitly public
    public init(image: UIImage) {
        self.image = image
        print("📱 ImageEditView: Initialized with image size: \(image.size)")
    }
    
    @State private var prompt: String = ""
    @State private var maskType: MaskType = .circle
    @State private var isProcessing = false
    @State private var resultImage: UIImage?
    @State private var showResult = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private let imageProcessor = ImageProcessor()
    // Use a class to store cancellables instead of directly on the struct
    private let cancellableStorage = CancellableStorage()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Edit Your Image")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: Configuration.Colors.text))
                    .padding(.top)
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe what you want to generate:")
                        .font(.headline)
                        .foregroundColor(Color(hex: Configuration.Colors.text))
                    
                    TextEditor(text: $prompt)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: Configuration.Colors.accent), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select mask shape:")
                        .font(.headline)
                        .foregroundColor(Color(hex: Configuration.Colors.text))
                    
                    Picker("Mask Shape", selection: $maskType) {
                        Text("Circle").tag(MaskType.circle)
                        Text("Rectangle").tag(MaskType.rectangle)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                
                Button(action: generateImage) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                            Text("Processing...")
                        } else {
                            Image(systemName: "wand.and.stars")
                            Text("Generate Image")
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(isProcessing ? Color.gray : Color(hex: Configuration.Colors.accent))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .disabled(isProcessing || prompt.isEmpty)
                .padding(.horizontal, 40)
                .padding(.vertical)
            }
        }
        .background(Color(hex: Configuration.Colors.primary).opacity(0.1).ignoresSafeArea())
        .navigationTitle("Edit Image")
        .sheet(isPresented: $showResult) {
            if let resultImage = resultImage {
                ResultView(originalImage: image, generatedImage: resultImage)
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func generateImage() {
        print("📱 ImageEditView: Generate image button pressed")
        guard !prompt.isEmpty else {
            print("⚠️ ImageEditView: Prompt is empty, cannot generate image")
            return
        }
        
        print("📱 ImageEditView: Starting image generation with prompt: \(prompt)")
        isProcessing = true
        
        imageProcessor.processImage(originalImage: image, prompt: prompt, maskType: maskType)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    print("📱 ImageEditView: Received completion: \(completion)")
                    isProcessing = false
                    
                    if case .failure(let error) = completion {
                        print("⚠️ ImageEditView: Error: \(error.localizedDescription)")
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                },
                receiveValue: { image in
                    print("📱 ImageEditView: Received generated image of size: \(image.size)")
                    resultImage = image
                    showResult = true
                }
            )
            .store(in: &cancellableStorage.cancellables)
    }
}

// Helper class to store cancellables
class CancellableStorage {
    var cancellables = Set<AnyCancellable>()
}
