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
        // Provide a unique analysisId for the feedback here
        _feedbackViewModel = StateObject(wrappedValue: FeedbackViewModel(analysisId: UUID().uuidString))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top bar with share and close
                HStack {
                    // Share button on the leading side
                    Button {
                        viewModel.toggleShareOptions()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .padding(8)
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    // Title
                    Text("Analysis Results")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Done button on trailing side
                    Button("Done") {
                        onDismiss()
                    }
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 10)
                .background(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // SECTION 1: Classification + Product
                        ClassificationBadgeView(style: viewModel.classificationStyle)
                            .padding(.top, 16)
                        
                        ProductInfoCardView(
                            product: response.identifiedProductName,
                            company: response.identifiedCompany,
                            headquarters: response.identifiedHeadquarters,
                            rationale: response.identificationRationale,
                            countryFlag: viewModel.countryFlag(for: response.identifiedHeadquarters)
                        )
                        .padding(.horizontal)
                        
                        // SECTION 2: Alternatives
                        VStack(alignment: .center, spacing: 16) {
                            AlternativesHeaderView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal)
                            
                            if response.classification == .europeanCountry {
                                Text("This product is from a European Country, no alternatives needed.")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
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
                                        .padding(.bottom, 8)
                                    }
                                } else if !response.potentialAlternative.isEmpty {
                                    Text(response.potentialAlternative)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        .padding(.horizontal)
                                } else {
                                    Text("No alternative could be found.")
                                        .foregroundColor(.secondary)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                        
                        // SECTION 3: Feedback
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Feedback")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            FeedbackView(viewModel: feedbackViewModel)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            
            // SHARE OVERLAY
            if viewModel.showShareOptions {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                viewModel.toggleShareOptions()
                            }
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
    }
}