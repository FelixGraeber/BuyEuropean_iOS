//
//  ShareOptionsView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI

struct ShareOptionsView: View {
    @Binding var isVisible: Bool
    let onShare: () -> UIActivityViewController
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Share Results")
                    .font(.headline)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color(.systemGray3))
                }
            }
            .padding()
            
            Divider()
            
            // Share options
            VStack(spacing: 16) {
                // System share
                Button(action: {
                    let activityVC = onShare()
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityVC, animated: true)
                    }
                    
                    withAnimation {
                        isVisible = false
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Share via...")
                            .font(.body)
                            .foregroundColor(Color(.label))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.systemGray2))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Copy to clipboard
                Button(action: {
                    // This would be implemented in the ViewModel
                    UIPasteboard.general.string = "Analysis results copied to clipboard"
                    
                    // Show toast or feedback
                    withAnimation {
                        isVisible = false
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }
                        
                        Text("Copy to clipboard")
                            .font(.body)
                            .foregroundColor(Color(.label))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.systemGray2))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .scaleEffect(isAnimated ? 1.0 : 0.9)
        .opacity(isAnimated ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAnimated = true
            }
        }
        .onDisappear {
            isAnimated = false
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        ShareOptionsView(
            isVisible: .constant(true),
            onShare: {
                UIActivityViewController(
                    activityItems: ["Sample share text"],
                    applicationActivities: nil
                )
            }
        )
        .padding()
    }
}
