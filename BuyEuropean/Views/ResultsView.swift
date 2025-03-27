import SwiftUI

// Assume these are defined elsewhere:
// ResultsViewModel, FeedbackViewModel, ClassificationBadgeView, ProductInfoCardView,
// AlternativesHeaderView, AlternativeCardView, FeedbackView, BuyEuropeanResponse

struct ResultsView: View {
    let response: BuyEuropeanResponse
    let onDismiss: () -> Void

    @StateObject private var viewModel: ResultsViewModel
    @StateObject private var feedbackViewModel: FeedbackViewModel

    // Use a standard spacing value
    private let sectionSpacing: CGFloat = 24
    private let horizontalPadding: CGFloat = 16 // Consistent horizontal padding

    // App Store Link (can be defined directly in ShareLink if preferred)
    private let appStoreLink = "https://apps.apple.com/de/app/buyeuropean/id6743128862?l=en-GB"

    // Share Text (can be defined directly in ShareLink if preferred)
    private var shareText: String {
        """
        Check out the BuyEuropean app that quickly identifies products from European companies.
        Vote with your money and support European businesses and values.
        Download the app: \(appStoreLink)
        """
    }

    init(response: BuyEuropeanResponse, onDismiss: @escaping () -> Void) {
        self.response = response
        self.onDismiss = onDismiss

        // Initialize ViewModels
        _viewModel = StateObject(wrappedValue: ResultsViewModel(response: response))
        _feedbackViewModel = StateObject(wrappedValue: FeedbackViewModel(analysisId: response.id != nil ? String(response.id!) : UUID().uuidString))
    }

    var body: some View {
        // Use ZStack for background layer (overlay no longer needed)
        ZStack {
            // Use grouped background for the main area
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // MARK: - Header Bar
                HStack {
                    // ShareLink (Replaces Button)
                    ShareLink(item: shareText) { // Provide the text directly
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3) // Match Done button size
                    }
                    .frame(width: 60, alignment: .leading) // Ensure consistent frame
                    .tint(Color(red: 0/255, green: 51/255, blue: 153/255)) // Use brand color

                    Spacer()

                    Text("Analysis Results")
                        .font(.headline)
                        .fontWeight(.semibold) // Slightly bolder title

                    Spacer()

                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.medium)
                    .frame(width: 60, alignment: .trailing) // Ensure consistent frame
                    .tint(Color(red: 0/255, green: 51/255, blue: 153/255)) // Use brand color for dismiss emphasis

                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 12) // Standard vertical padding
                .background(.regularMaterial) // Use material background
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1) // Subtle shadow consistent with ScanView header


                // MARK: - Scrollable Content
                ScrollView {
                    VStack(spacing: sectionSpacing) { // Consistent spacing between sections
                        // --- Section 1: Classification + Product ---
                        ClassificationBadgeView(style: viewModel.classificationStyle)
                            .padding(.top, sectionSpacing) // Add space below header

                        ProductInfoCardView(
                            product: response.identifiedProductName,
                            company: response.identifiedCompany,
                            headquarters: response.identifiedHeadquarters,
                            rationale: response.identificationRationale,
                            countryFlag: viewModel.countryFlag(for: response.identifiedHeadquarters)
                        )
                        .padding(.horizontal, horizontalPadding)

                        // --- Section 2: Alternatives ---
                        VStack(alignment: .leading, spacing: 16) { // Align header left, consistent spacing
                            AlternativesHeaderView()
                                .padding(.horizontal, horizontalPadding) // Add padding to header

                            // Center text content if no alternatives or European
                            if response.classification == .europeanCountry {
                                CenteredMessageView(message: "This product is from a European country. No specific alternatives are suggested based on origin.")
                            } else {
                                if let alternatives = response.potentialAlternatives, !alternatives.isEmpty {
                                    // Use ForEach directly for cards
                                    ForEach(alternatives) { alternative in
                                        AlternativeCardView(
                                            alternative: alternative,
                                            countryFlag: viewModel.countryFlag(for: alternative.country),
                                            onLearnMore: {
                                                viewModel.openWebSearch(for: alternative)
                                            }
                                        )
                                        .padding(.horizontal, horizontalPadding)
                                        // Add spacing below each card if needed, or rely on VStack spacing
                                    }
                                } else {
                                     CenteredMessageView(message: "No specific European alternatives could be identified for this product.")
                                }
                            }
                        } // Alternatives VStack

                        // --- Section 3: Feedback ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Feedback")
                                .font(.title3) // Slightly larger section header
                                .fontWeight(.semibold)
                                .padding(.horizontal, horizontalPadding)

                            FeedbackView(viewModel: feedbackViewModel)
                                .padding(.horizontal, horizontalPadding)
                        } // Feedback VStack

                    } // Main Content VStack
                    .padding(.bottom, sectionSpacing) // Add padding at the very bottom
                } // ScrollView
            } // Main VStack

        } // ZStack
        // Consider adding .ignoresSafeArea(.keyboard) if feedback includes text editor
    }
}

// Helper View for Centered Text Messages
struct CenteredMessageView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline) // Use subheadline for secondary info
            .foregroundColor(.secondary) // Use secondary color
            .multilineTextAlignment(.center)
            .padding(.vertical) // Add vertical padding
            .padding(.horizontal, 30) // More horizontal padding for centering effect
            .frame(maxWidth: .infinity, alignment: .center)
    }
}