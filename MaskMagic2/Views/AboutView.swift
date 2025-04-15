//
//  AboutView.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/15/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                
                VStack(spacing: 0) {
                    // Fixed header outside ScrollView
                    Text("About MaskMagic2")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: Configuration.Colors.secondary))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                        .background(Color(hex: Configuration.Colors.primary).opacity(0.1))
                    
                    // Scrollable content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Learning project section
                            SectionView(title: "Learning Project",
                                       icon: "graduationcap",
                                       content: "MaskMagic2 was developed as a learning project focusing on:")
                            
                            BulletPointView(text: "App Store deployment process and requirements")
                            BulletPointView(text: "Secure API integration with Google Cloud Functions")
                            BulletPointView(text: "Working with advanced image processing and AI technologies")
                            BulletPointView(text: "SwiftUI interface design and animations")
                            
                            // Tech Stack
                            SectionView(title: "Technology",
                                       icon: "cpu",
                                       content: "This app leverages several modern technologies:")
                                .padding(.top, 8)
                            
                            BulletPointView(text: "SwiftUI for the user interface")
                            BulletPointView(text: "OpenAI API for image generation")
                            BulletPointView(text: "Combine framework for reactive programming")
                            BulletPointView(text: "Google Cloud Functions for secure API key management")
                            
                            // Current Development
                            SectionView(title: "Ongoing Development",
                                       icon: "hammer",
                                       content: "Currently working on improving:")
                                .padding(.top, 8)
                            
                            BulletPointView(text: "Image orientation preservation during processing")
                            BulletPointView(text: "AI image generation quality and reliability")
                            BulletPointView(text: "User experience and interface refinements")
                            
                            // Version info
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 30)
                            
                            Spacer().frame(height: 50)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                    .background(Color(hex: Configuration.Colors.primary).opacity(0.1))
                }
                
                Button(action:{
                    dismiss()
                    presentationMode.wrappedValue.dismiss()
                
                }){
                    HStack{
                        Image(systemName: "house.fill")
                        Text("Home")
                            .fontWeight(.medium)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: Configuration.Colors.accent))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                .background(
                    // Gradient background behind button for better visibility
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: Configuration.Colors.primary).opacity(0.0),
                            Color(hex: Configuration.Colors.primary).opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 90)
                    .ignoresSafeArea()
                )
            }
            .background(Color(hex: Configuration.Colors.primary).opacity(0.1).ignoresSafeArea())
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: Configuration.Colors.accent))
                        .imageScale(.large)
                }
            )
        }
    }
}

// Helper Views remain the same
struct SectionView: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: Configuration.Colors.primary))
                    .font(.title2)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: Configuration.Colors.primary))
            }
            
            Text(content)
                .foregroundColor(Color(hex: Configuration.Colors.primary))
                .padding(.leading, 4)
        }
        .padding(.vertical, 5)
    }
}

struct BulletPointView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .foregroundColor(Color(hex: Configuration.Colors.secondary))
            
            Text(text)
                .foregroundColor(Color(hex: Configuration.Colors.primary))
        }
        .padding(.leading, 20)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
