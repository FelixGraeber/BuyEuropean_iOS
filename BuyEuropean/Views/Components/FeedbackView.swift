//
//  FeedbackView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI

struct FeedbackView: View {
    @ObservedObject var viewModel: FeedbackViewModel
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isSubmitted {
                // Success state
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .scaleEffect(isAnimated ? 1.0 : 0.5)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isAnimated)
                    
                    Text("Thank you for your feedback!")
                        .font(.headline)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .opacity(isAnimated ? 1.0 : 0.0)
                        .offset(y: isAnimated ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: isAnimated)
                }
                .padding()
                .onAppear {
                    isAnimated = true
                }
                .onDisappear {
                    isAnimated = false
                }
            } else {
                // Initial feedback options or detailed form
                if !viewModel.showDetailedFeedback {
                    // Initial thumbs up/down options
                    VStack(spacing: 16) {
                        Text("Was this analysis helpful?")
                            .font(.headline)
                            .foregroundColor(Color(.secondaryLabel))
                        
                        HStack(spacing: 24) {
                            // Thumbs up button
                            Button(action: {
                                viewModel.toggleFeedbackType(isPositive: true)
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "hand.thumbsup.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.green)
                                    }
                                    
                                    Text("Yes")
                                        .font(.subheadline)
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Thumbs down button
                            Button(action: {
                                viewModel.toggleFeedbackType(isPositive: false)
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "hand.thumbsdown.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.red)
                                    }
                                    
                                    Text("No")
                                        .font(.subheadline)
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                } else {
                    // Detailed feedback form
                    VStack(alignment: .leading, spacing: 16) {
                        // Form header
                        Text("What was incorrect?")
                            .font(.headline)
                            .foregroundColor(Color(.label))
                        
                        // Checkboxes for specific issues
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Product identification", isOn: $viewModel.feedbackData.wrongProduct)
                                .toggleStyle(CheckboxToggleStyle())
                            
                            Toggle("Brand identification", isOn: $viewModel.feedbackData.wrongBrand)
                                .toggleStyle(CheckboxToggleStyle())
                            
                            Toggle("Country identification", isOn: $viewModel.feedbackData.wrongCountry)
                                .toggleStyle(CheckboxToggleStyle())
                            
                            Toggle("Classification", isOn: $viewModel.feedbackData.wrongClassification)
                                .toggleStyle(CheckboxToggleStyle())
                            
                            Toggle("Suggested alternatives", isOn: $viewModel.feedbackData.wrongAlternatives)
                                .toggleStyle(CheckboxToggleStyle())
                        }
                        
                        // Additional feedback text field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional feedback (optional)")
                                .font(.subheadline)
                                .foregroundColor(Color(.secondaryLabel))
                            
                            TextEditor(text: $viewModel.feedbackData.feedbackText)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        // Error message if any
                        if let error = viewModel.error {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                        
                        // Submit button
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                viewModel.submitFeedback()
                            }) {
                                if viewModel.isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                        .frame(width: 24, height: 24)
                                        .padding(.horizontal, 8)
                                } else {
                                    Text("Submit Feedback")
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .disabled(viewModel.isSubmitting)
                            
                            Spacer()
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .onAppear {
            isAnimated = viewModel.isSubmitted
        }
        .onChange(of: viewModel.isSubmitted) { newValue in
            isAnimated = newValue
        }
    }
}

// Custom checkbox toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : Color(.systemGray))
                .font(.system(size: 16, weight: .semibold))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
                .font(.subheadline)
                .foregroundColor(Color(.label))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            Spacer()
        }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Initial state
            FeedbackView(viewModel: createInitialViewModel())
                .previewDisplayName("Initial State")
            
            // Detailed feedback state
            FeedbackView(viewModel: createDetailedViewModel())
                .previewDisplayName("Detailed Feedback")
            
            // Submitted state
            FeedbackView(viewModel: createSubmittedViewModel())
                .previewDisplayName("Submitted")
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // Helper methods to create view models in different states
    static func createInitialViewModel() -> FeedbackViewModel {
        return FeedbackViewModel(analysisId: "12345")
    }
    
    static func createDetailedViewModel() -> FeedbackViewModel {
        let viewModel = FeedbackViewModel(analysisId: "12345")
        viewModel.showDetailedFeedback = true
        return viewModel
    }
    
    static func createSubmittedViewModel() -> FeedbackViewModel {
        let viewModel = FeedbackViewModel(analysisId: "12345")
        viewModel.isSubmitted = true
        return viewModel
    }
}
