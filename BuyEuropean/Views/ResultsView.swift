import SwiftUI
import Foundation // For NSLocalizedString, if needed

// Assume these are defined elsewhere:
// ResultsViewModel, FeedbackViewModel, ClassificationBadgeView, ProductInfoCardView,
// AlternativesHeaderView, AlternativeCardView, FeedbackView, BuyEuropeanResponse

struct ResultsView: View {
    let response: BuyEuropeanResponse
    let analysisImage: UIImage?
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
        let line1 = NSLocalizedString("share.text.line1", comment: "Share text line 1")
        let line2 = NSLocalizedString("share.text.line2", comment: "Share text line 2")
        return """
        \(line1)
        \(line2)
        \(appStoreLink)
        """
    }

    init(response: BuyEuropeanResponse, analysisImage: UIImage?, onDismiss: @escaping () -> Void) {
        self.response = response
        self.analysisImage = analysisImage
        self.onDismiss = onDismiss

        // Initialize ViewModels
        let initialViewModel = ResultsViewModel(response: response, analysisImage: analysisImage)
        _viewModel = StateObject(wrappedValue: initialViewModel)
        // Pass the image to FeedbackViewModel as well
        _feedbackViewModel = StateObject(wrappedValue: FeedbackViewModel(analysisImage: analysisImage))
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
                    .tint(Color.accentColor)

                    Spacer()

                    Text(LocalizedStringKey("results.title"))
                        .font(.headline)
                        .fontWeight(.semibold) // Slightly bolder title

                    Spacer()

                    Button(LocalizedStringKey("common.done")) {
                        onDismiss()
                    }
                    .fontWeight(.medium)
                    .frame(width: 60, alignment: .trailing) // Ensure consistent frame
                    .tint(Color.accentColor) 

                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 12) // Standard vertical padding
                .background(.regularMaterial) // Use material background
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1) // Subtle shadow consistent with ScanView header


                // MARK: - Scrollable Content
                ScrollView {
                    VStack(spacing: sectionSpacing) { // Consistent spacing between sections
                        // --- Section 1: Classification + Product/Info ---
                        ClassificationBadgeView(style: viewModel.classificationStyle)
                            .padding(.top, sectionSpacing) // Add space below header

                        // Conditionally show Product Info or a generic message
                        if viewModel.isProductAnalysis {
                            ProductInfoCardView(
                                product: viewModel.productName, // Use ViewModel
                                company: viewModel.companyName, // Use ViewModel
                                headquarters: viewModel.headquartersCountry, // Use ViewModel
                                rationale: viewModel.identificationRationale, // Use ViewModel
                                countryFlag: viewModel.countryFlag(for: viewModel.headquartersCountry), // Use ViewModel
                                // Add the required arguments from the viewModel
                                parentCompany: viewModel.parentCompany,
                                parentCompanyHeadquarters: viewModel.parentCompanyHeadquarters, // Pass the HQ code
                                parentCompanyFlag: viewModel.parentCompanyFlag,
                                shouldShowParentCompany: viewModel.shouldShowParentCompany
                            )
                            .padding(.horizontal, horizontalPadding)
                        } else {
                            // Special display for non-product classifications (animal, human, etc.)
                            VStack(alignment: .center, spacing: 12) {
                                // Determine emoji using helper function
                                Text(emoji(for: viewModel.displayClassification))
                                    .font(.system(size: 60))
                                    .padding(.bottom, 5)

                                Text(LocalizedStringKey("classification.\(viewModel.displayClassification.rawValue).name"))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)

                                Text(LocalizedStringKey(viewModel.identificationRationale))
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }
                            .padding(.vertical, 30) // Add vertical padding for spacing
                            // Optional background: .background(Color(.secondarySystemBackground).cornerRadius(12))
                            .padding(.horizontal, horizontalPadding) // Maintain horizontal padding
                        }

                        // --- Section 2: Alternatives ---
                        // Only show this section if appropriate and alternatives exist
                        if viewModel.shouldShowAlternatives {
                            VStack(alignment: .leading, spacing: 16) { // Align header left, consistent spacing
                                AlternativesHeaderView()
                                    .padding(.horizontal, horizontalPadding) // Add padding to header

                                // Use ForEach directly with alternatives from ViewModel
                                ForEach(viewModel.alternatives) { alternative in
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
                                // Note: The case where alternatives array is empty but shouldShowAlternatives was true
                                // might need a specific message, but shouldShowAlternatives should handle this.
                                // If viewModel.alternatives is empty here, ForEach does nothing.

                            } // Alternatives VStack
                        } else if viewModel.isProductAnalysis {
                             // Show message only if it was a product analysis but no alternatives are shown
                             CenteredMessageView(message: LocalizedStringKey("results.no_alternatives"))
                                .padding(.horizontal, horizontalPadding)
                        }

                        // --- Section 3: Feedback ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedStringKey("results.feedback.title"))
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

    // MARK: - Helper Functions
    private func emoji(for classification: Classification) -> String {
        switch classification {
        case .cat: return NSLocalizedString("classification.cat.emoji", comment: "Emoji for cat classification") 
        case .dog: return NSLocalizedString("classification.dog.emoji", comment: "Emoji for dog classification")
        case .animal: return NSLocalizedString("classification.animal.emoji", comment: "Emoji for animal classification")
        case .human: return NSLocalizedString("classification.human.emoji", comment: "Emoji for human classification")
        // For "Product", we usually show ProductInfoCardView, not an emoji.
        // However, if Classification.product can reach here, we might need a fallback.
        default: return NSLocalizedString("classification.product.emoji", comment: "Emoji for product classification or fallback") 
        }
    }
}

// Helper View for Centered Text Messages
struct CenteredMessageView: View {
    let message: LocalizedStringKey // Changed to LocalizedStringKey to support direct localization

    var body: some View {
        Text(message) // Text view can take LocalizedStringKey directly
            .font(.subheadline) // Use subheadline for secondary info
            .foregroundColor(.secondary) // Use secondary color
            .multilineTextAlignment(.center)
            .padding(.vertical) // Add vertical padding
            .padding(.horizontal, 30) // More horizontal padding for centering effect
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
