//
//  DiagnosticsView.swift
//  MaskMagic2
//
//  Created by Jessy  Martinez  on 4/13/25.
//
import SwiftUI

struct DiagnosticsView: View {
    // DiagnosticsView is a SwiftUI view that provides information about the device and app, and allows testing the OpenAI connection.
    @State private var logMessages: [String] = []
    @State private var isRefreshing = false
    
    // Basic device info
    let deviceInfo = [
        "Device": UIDevice.current.model,
        "iOS Version": UIDevice.current.systemVersion,
        "Device Name": UIDevice.current.name
    ]
    
    // App info
    var appInfo: [String: String] {
        let info = Bundle.main.infoDictionary
        return [
            "App Name": info?["CFBundleName"] as? String ?? "Unknown",
            "App Version": info?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "Build Number": info?["CFBundleVersion"] as? String ?? "Unknown"
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Device Information")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: Configuration.Colors.text))
                    
                    ForEach(deviceInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key + ":")
                                .fontWeight(.semibold)
                                .frame(width: 120, alignment: .leading)
                            Text(value)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                Divider()
                
                Group {
                    Text("App Information")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: Configuration.Colors.text))
                    
                    ForEach(appInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key + ":")
                                .fontWeight(.semibold)
                                .frame(width: 120, alignment: .leading)
                            Text(value)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                Divider()
                
                Button(action: {
                    testOpenAIConnection()
                }) {
                    Text("Test OpenAI Connection")
                        .padding()
                        .background(Color(hex: Configuration.Colors.accent))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                if !logMessages.isEmpty {
                    Divider()
                    
                    Text("Connection Test Results:")
                        .font(.headline)
                        .foregroundColor(Color(hex: Configuration.Colors.text))
                    
                    ForEach(logMessages, id: \.self) { message in
                        Text(message)
                            .font(.system(.footnote, design: .monospaced))
                            .padding(.vertical, 2)
                    }
                }
                
                if isRefreshing {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Diagnostics")
    }
    
    func testOpenAIConnection() {
        isRefreshing = true
        logMessages.append("📱 Starting OpenAI connection test...")
        
        // Create a simple request to test the API connection
        let url = URL(string: "https://api.openai.com/v1/models")!
        var request = URLRequest(url: url)
        Text("API Key: [Securely stored in Firebase]")
        
        logMessages.append("📱 Sending request to \(url)...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    logMessages.append("❌ Connection error: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    logMessages.append("📱 Received response with status code: \(httpResponse.statusCode)")
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        if responseString.count > 100 {
                            let truncated = responseString.prefix(100)
                            logMessages.append("📱 Response (truncated): \(truncated)...")
                        } else {
                            logMessages.append("📱 Response: \(responseString)")
                        }
                    } else {
                        logMessages.append("⚠️ No data in response")
                    }
                }
                isRefreshing = false
            }
        }.resume()
    }
}

struct DiagnosticsView_Previews: PreviewProvider {
    static var previews: some View {
        DiagnosticsView()
    }
}
