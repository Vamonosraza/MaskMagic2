//
//  ResultView.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//

import SwiftUI

struct ResultView: View {
    let originalImage: UIImage
    let generatedImage: UIImage
    @State private var showingOriginal = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Your Generated Image")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: Configuration.Colors.text))
                        .padding(.top)
                    
                    ZStack {
                        Image(uiImage: showingOriginal ? originalImage : generatedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            .animation(.default, value: showingOriginal)
                        
                        VStack {
                            Spacer()
                            Button(action: {
                                showingOriginal.toggle()
                            }) {
                                Text(showingOriginal ? "Show Generated" : "Show Original")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: Configuration.Colors.secondary).opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                            .padding(.bottom, 10)
                        }
                    }
                    .padding()
                    
                    HStack(spacing: 20) {
                        Button(action: saveImage) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save Image")
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: Configuration.Colors.accent))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showingShareSheet = true
                        
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: Configuration.Colors.secondary))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .sheet(isPresented: $showingShareSheet) {
                        ShareSheet(activityItems: [generatedImage])
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Create Another")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: Configuration.Colors.primary))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 30)
            }
            .background(Color(hex: Configuration.Colors.primary).opacity(0.1).ignoresSafeArea())
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: Configuration.Colors.accent))
                        .imageScale(.large)
                }
            )
            .navigationBarTitle("", displayMode: .inline)
        }
    }
    
    func saveImage() {
        UIImageWriteToSavedPhotosAlbum(generatedImage, nil, nil, nil)
    }
    
    func shareImage() {
        // Share the actual UIImage instead of jpeg data
        let imageToShare = generatedImage
        
        let av = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
        
        // iPad support - prevent crashes on iPad
        if let popoverController = av.popoverPresentationController {
            // Anchor to the center of the screen
            popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popoverController.sourceRect = CGRect(
                x: UIScreen.main.bounds.midX,
                y: UIScreen.main.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(av, animated: true)
        } else {
            print("Could not find root view controller to present share sheet")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to do here
    }
}
