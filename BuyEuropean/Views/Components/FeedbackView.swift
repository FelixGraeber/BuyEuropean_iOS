import SwiftUI

// Assume FeedbackViewModel and its FeedbackData struct are defined:
// class FeedbackViewModel: ObservableObject {
//    @Published var isSubmitted = false
//    @Published var showDetailedFeedback = false
//    @Published var isSubmitting = false
//    @Published var error: String?
//    @Published var feedbackData = FeedbackData()
//    func toggleFeedbackType(isPositive: Bool) { ... }
//    func submitFeedback() { ... }
// }
// struct FeedbackData { var wrongProduct = false ... var feedbackText = "" }

struct FeedbackView: View {
    @ObservedObject var viewModel: FeedbackViewModel
    @State private var isAnimated = false // For success animation
    @State private var sharePhotoConsent: Bool = false // State for consent toggle
    @Environment(\.colorScheme) private var colorScheme
    
    // Styling constants
    private let cornerRadius: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if viewModel.hasSubmittedFeedback {
                    successView()
                } else if viewModel.isSubmitted {
                    successView()
                } else {
                    if viewModel.showDetailedFeedback {
                        detailedFeedbackForm()
                    } else {
                        initialFeedbackOptions()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 0)
        .padding(.bottom, 8)
        .onChange(of: viewModel.isSubmitted) { submitted in
            if submitted {
                isAnimated = false // Reset first
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isAnimated = true
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func successView() -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 54, height: 54)
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.green)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.5)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: isAnimated)
            Text("Thank you for your feedback!")
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .opacity(isAnimated ? 1.0 : 0.0)
                .offset(y: isAnimated ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: isAnimated)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func initialFeedbackOptions() -> some View {
        VStack(spacing: 20) { // Increased spacing
            Text("Was this analysis helpful?")
                .font(.headline) // Keep headline
                .foregroundColor(.primary) // Use primary

            HStack(spacing: 30) { // Increased spacing between buttons
                feedbackButton(isPositive: true)
                feedbackButton(isPositive: false)
            }
        }
        .padding(.vertical, 10) // Add some vertical padding
    }

    // Helper for Thumbs Up/Down Buttons
    private func feedbackButton(isPositive: Bool) -> some View {
        Button {
            if isPositive {
                // Show immediate visual feedback for thumbs up
                viewModel.isSubmitted = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isAnimated = true
                }
                // Submit feedback in the background
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    viewModel.toggleFeedbackType(isPositive: true)
                }
            } else {
                // For thumbs down, show detailed feedback form only
                viewModel.toggleFeedbackType(isPositive: false)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        viewModel.feedbackData.isPositive == isPositive && viewModel.feedbackData.isPositive != nil
                            ? Color.brandPrimary.opacity(0.15)
                            : Color.gray.opacity(0.1)
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: isPositive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .font(.system(size: 22))
                    .foregroundColor(
                        viewModel.feedbackData.isPositive == isPositive && viewModel.feedbackData.isPositive != nil
                            ? Color.brandPrimary
                            : .gray
                    )
            }
        }
    }

    @ViewBuilder
    private func detailedFeedbackForm() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.feedbackData.isPositive ? "What was helpful?" : "What was incorrect?")
                .font(.headline)
                .foregroundColor(.primary)
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Product Identification", isOn: $viewModel.feedbackData.wrongProduct)
                Toggle("Brand/Company Identification", isOn: $viewModel.feedbackData.wrongBrand)
                Toggle("Country Identification (HQ)", isOn: $viewModel.feedbackData.wrongCountry)
                Toggle("Overall Classification", isOn: $viewModel.feedbackData.wrongClassification)
                Toggle("Suggested Alternatives", isOn: $viewModel.feedbackData.wrongAlternatives)
                if viewModel.analysisImage != nil {
                    Toggle("Share photo to improve analysis (optional)", isOn: $sharePhotoConsent)
                        .toggleStyle(CheckboxToggleStyle(tintColor: Color.brandPrimary))
                        .padding(.top, 8)
                }
            }
            .toggleStyle(CheckboxToggleStyle(tintColor: Color.brandPrimary))
            .padding(.horizontal, 12)
            .padding(.top, 8)
            VStack(alignment: .leading, spacing: 6) {
                Text("Additional details (optional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                TextEditor(text: $viewModel.feedbackData.feedbackText)
                    .frame(minHeight: 80, maxHeight: 150)
                    .font(.body)
                    .padding(8)
                    .background(Color.inputBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.inputBorder, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 12)
            if let error = viewModel.error {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            HStack {
                Spacer()
                Button(action: {
                    viewModel.submitFeedback(sharePhotoConsent: sharePhotoConsent)
                }) {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(height: 20)
                    } else {
                        Text("Submit Feedback")
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(minHeight: 44)
                .background(Color.brandPrimary)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .disabled(viewModel.isSubmitting)
                .opacity(viewModel.isSubmitting ? 0.6 : 1.0)
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.cardBackground)
        .cornerRadius(cornerRadius)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.12) : Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// Custom checkbox toggle style - updated to accept tint color
struct CheckboxToggleStyle: ToggleStyle {
    var tintColor: Color = .blue // Default tint

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? tintColor : Color.gray) // Use standard gray color
                    .font(.system(size: 20)) // Slightly larger checkbox

                configuration.label
                    .font(.body) // Use body font for label
                    .foregroundColor(.primary)

                Spacer()
            }
        }
        .buttonStyle(.plain) // Use plain button style to avoid interference
    }
}