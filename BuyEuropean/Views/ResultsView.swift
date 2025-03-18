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
        // Pass the actual ID from the API response, or fallback to a UUID string if ID is nil
        _feedbackViewModel = StateObject(wrappedValue: FeedbackViewModel(analysisId: response.id != nil ? String(response.id!) : UUID().uuidString))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top bar with centered title and balanced layout
                HStack {
                    // Empty space with same width as the Done button for balance
                    Button("") { }
                        .opacity(0)
                        .padding(.leading, 16)
                        .frame(width: 60, alignment: .leading)
                    
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
                    .frame(width: 60, alignment: .trailing)
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
        }
    }
}