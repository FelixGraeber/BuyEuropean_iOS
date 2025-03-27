//
//  ShareOptionsView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI
import UIKit

struct ShareOptionsView: View {
    @Binding var isVisible: Bool
    let onShare: () -> UIActivityViewController
    let onCopyText: () -> String
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
                    
                    // Present the share sheet
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        // Configure excluded activity types (optional)
                        activityVC.excludedActivityTypes = [
                            .assignToContact,
                            .addToReadingList
                        ]
                        
                        // Set completion handler
                        activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
                            // Dismiss the share sheet when done
                            withAnimation {
                                isVisible = false
                            }
                        }
                        
                        rootViewController.present(activityVC, animated: true)
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
                    // Get the text directly from the provided closure
                    let shareText = onCopyText()
                    UIPasteboard.general.string = shareText
                    
                    // Show feedback (could be enhanced with a toast notification)
                    // For now, just dismiss the sheet
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