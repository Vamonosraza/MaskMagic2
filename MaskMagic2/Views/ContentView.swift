//
//  ContentView.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var navigateToEditView = false
    @State private var showAboutView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: Configuration.Colors.primary)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("MaskMagic2")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: Configuration.Colors.text))
                        .padding()
                    
                    Image(systemName: "wand.and.stars")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color(hex: Configuration.Colors.accent))
                        .padding()
                    
                    Text("Transform your photos with AI")
                        .font(.title2)
                        .foregroundColor(Color(hex: Configuration.Colors.text))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            isShowingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: Configuration.Colors.accent))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose Photo")
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: Configuration.Colors.secondary))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        Button(action: {
                            showAboutView = true
                        }) {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("About")
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: Configuration.Colors.primary).opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $showAboutView) {
                AboutView()
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary) {
                    navigateToEditView = true
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera) {
                    navigateToEditView = true
                }
            }
            .background(
                NavigationLink(
                    destination: ImageEditView(image: selectedImage ?? UIImage()),
                    isActive: $navigateToEditView,
                    label: { EmptyView() }
                )
            )
        }
        .accentColor(Color(hex: Configuration.Colors.accent))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
