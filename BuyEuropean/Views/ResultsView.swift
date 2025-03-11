//
//  ResultsView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI

struct ResultsView: View {
    let response: BuyEuropeanResponse
    let onDismiss: () -> Void
    
    @StateObject private var viewModel: ResultsViewModel
    @StateObject private var feedbackViewModel: FeedbackViewModel
    
    init(response: BuyEuropeanResponse, onDismiss: @escaping () -> Void) {
        self.response = response
        self.onDismiss = onDismiss
        
        // Initialize ViewModels
        _viewModel = StateObject(wrappedValue: ResultsViewModel(response: response))
        _feedbackViewModel = StateObject(wrappedValue: FeedbackViewModel(analysisId: UUID().uuidString))
    }
    
    var body: some View {
        ZStack {
            // Main content
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Classification badge
                        ClassificationBadgeView(style: viewModel.classificationStyle)
                            .padding(.top, 8)
                        
                        // Product information card
                        ProductInfoCardView(
                            product: response.identifiedProductName,
                            company: response.identifiedCompany,
                            headquarters: response.identifiedHeadquarters,
                            rationale: response.identificationRationale,
                            countryFlag: viewModel.countryFlag(for: response.identifiedHeadquarters)
                        )
                        .padding(.horizontal)
                        
                        // European alternatives section
                        if viewModel.shouldShowAlternatives {
                            VStack(alignment: .leading, spacing: 16) {
                                AlternativesHeaderView()
                                    .padding(.horizontal)
                                
                                if let alternatives = response.potentialAlternatives, !alternatives.isEmpty {
                                    ForEach(alternatives) { alternative in
                                        AlternativeCardView(
                                            alternative: alternative,
                                            countryFlag: viewModel.countryFlag(for: alternative.country),
                                            onLearnMore: {
                                                viewModel.openWebSearch(for: alternative)
                                            }
                                        )
                                        .padding(.horizontal)
                                    }
                                } else if !response.potentialAlternative.isEmpty {
                                    // Fallback for string alternative
                                    Text(response.potentialAlternative)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Feedback section
                        VStack(spacing: 16) {
                            if !viewModel.showFeedback {
                                Button(action: {
                                    viewModel.toggleFeedback()
                                }) {
                                    HStack {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 16))
                                        
                                        Text("Provide Feedback")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(25)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Feedback")
                                            .font(.headline)
                                            .foregroundColor(Color(.label))
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            viewModel.toggleFeedback()
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(Color(.systemGray3))
                                        }
                                    }
                                    
                                    FeedbackView(viewModel: feedbackViewModel)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
                .navigationBarTitle("Analysis Results", displayMode: .inline)
                .navigationBarItems(
                    leading: Button(action: {
                        viewModel.toggleShareOptions()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                    },
                    trailing: Button("Done") {
                        onDismiss()
                    }
                )
                .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            }
            
            // Share options overlay
            if viewModel.showShareOptions {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            viewModel.toggleShareOptions()
                        }
                    
                    ShareOptionsView(
                        isVisible: $viewModel.showShareOptions,
                        onShare: {
                            viewModel.shareResult()
                        }
                    )
                    .padding(.horizontal, 20)
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showShareOptions)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showFeedback)
    }
}
