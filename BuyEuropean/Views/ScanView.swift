//
//  ScanView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @State private var showingActionSheet = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top area with title/logo
                HStack {
                    Spacer()
                    Text("BuyEuropean")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top)
                
                Spacer()
                
                // Main content area - camera preview or captured image
                ZStack {
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Scanning overlay
                    if case .scanning = viewModel.scanState {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2)
                            
                            Text("Analyzing product...")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Tagline
                Text("Vote with your money.\nBuy European.")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                
                // Bottom navigation bar
                HStack(spacing: 60) {
                    // Gallery button
                    Button(action: {
                        viewModel.showPhotoLibrary = true
                    }) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 2)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "photo.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Capture button
                    Button(action: {
                        if viewModel.capturedImage == nil {
                            viewModel.showCamera = true
                        } else {
                            Task {
                                await viewModel.analyzeImage()
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                            
                            if viewModel.capturedImage == nil {
                                Circle()
                                    .strokeBorder(Color.black, lineWidth: 2)
                                    .frame(width: 70, height: 70)
                            } else {
                                Image(systemName: "arrow.right")
                                    .font(.title)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    
                    // Info button
                    Button(action: {
                        // Show info or settings
                    }) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 2)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "info")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $viewModel.showCamera) {
            ImagePicker(selectedImage: $viewModel.capturedImage, isPresented: $viewModel.showCamera, sourceType: .camera)
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $viewModel.showPhotoLibrary) {
            ImagePicker(selectedImage: $viewModel.capturedImage, isPresented: $viewModel.showPhotoLibrary, sourceType: .photoLibrary)
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(item: sheetDestination) { destination in
            switch destination {
            case .results(let response):
                ResultsView(response: response, onDismiss: {
                    viewModel.resetScan()
                })
            case .error(let message):
                ErrorView(message: message, onDismiss: {
                    viewModel.resetScan()
                })
            }
        }
        .onChange(of: viewModel.scanState) { newState in
            if case .result(let response) = newState {
                // Navigate to results view
            }
        }
    }
    
    // Helper to determine which sheet to show
    private var sheetDestination: Binding<SheetDestination?> {
        Binding<SheetDestination?>(
            get: {
                switch viewModel.scanState {
                case .result(let response):
                    return .results(response)
                case .error(let message):
                    return .error(message)
                default:
                    return nil
                }
            },
            set: { _ in }
        )
    }
}

// Enum to handle different sheet destinations
enum SheetDestination: Identifiable {
    case results(BuyEuropeanResponse)
    case error(String)
    
    var id: String {
        switch self {
        case .results:
            return "results"
        case .error:
            return "error"
        }
    }
}

// Preview
struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
    }
}
