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

    // Styling constants
    private let cornerRadius: CGFloat = 16
    private let brandColor = Color(red: 0/255, green: 51/255, blue: 153/255) // Use brand color

    var body: some View {
        VStack(spacing: 16) { // Main container spacing
            if viewModel.isSubmitted {
                successView()
            } else {
                if viewModel.showDetailedFeedback {
                    detailedFeedbackForm()
                } else {
                    initialFeedbackOptions()
                }
            }
        }
        .padding() // Padding inside the card
        .background(Color(white: 1.0)) // White background
        .cornerRadius(cornerRadius)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4) // Consistent shadow
        .onChange(of: viewModel.isSubmitted) { submitted in
            // Trigger animation only when submitted becomes true
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
                    .fill(Color.green.opacity(0.15)) // Consistent opacity
                    .frame(width: 54, height: 54) // Slightly larger circle

                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold)) // Bolder checkmark
                    .foregroundColor(.green)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.5)
            .opacity(isAnimated ? 1.0 : 0.0)
            // Apply animation directly using the modifier
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: isAnimated)

            Text("Thank you for your feedback!")
                .font(.headline) // Keep headline
                .foregroundColor(.primary) // Use primary color
                .multilineTextAlignment(.center)
                .opacity(isAnimated ? 1.0 : 0.0)
                .offset(y: isAnimated ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: isAnimated)
        }
        .padding(.vertical, 16) // Add vertical padding to success message
         // .onAppear/onDisappear removed, handled by onChange
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
            viewModel.toggleFeedbackType(isPositive: isPositive)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                         // Use gray background, highlighted on selection? Or keep colored.
                        .fill((isPositive ? Color.green : Color.red).opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: isPositive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                        .font(.system(size: 22))
                        .foregroundColor(isPositive ? .green : .red)
                }
                Text(isPositive ? "Yes" : "No")
                    .font(.subheadline)
                    .foregroundColor(.primary) // Use primary text color
            }
        }
        .buttonStyle(.plain) // Ensure no default button styling interferes
    }


    @ViewBuilder
    private func detailedFeedbackForm() -> some View {
        VStack(alignment: .leading, spacing: 20) { // Consistent spacing
            Text(viewModel.feedbackData.isPositive ? "What was helpful?" : "What was incorrect?")
                .font(.headline)
                .foregroundColor(.primary)

            // Checkboxes/Toggles
            VStack(alignment: .leading, spacing: 12) {
                 Toggle("Product Identification", isOn: $viewModel.feedbackData.wrongProduct)
                 Toggle("Brand/Company Identification", isOn: $viewModel.feedbackData.wrongBrand)
                 Toggle("Country Identification (HQ)", isOn: $viewModel.feedbackData.wrongCountry)
                 Toggle("Overall Classification", isOn: $viewModel.feedbackData.wrongClassification)
                 Toggle("Suggested Alternatives", isOn: $viewModel.feedbackData.wrongAlternatives)
            }
             .toggleStyle(CheckboxToggleStyle(tintColor: brandColor)) // Apply custom style with brand color

            // Add the consent toggle here
            if viewModel.analysisImage != nil { // Only show if there is an image
                Toggle("Share photo to improve analysis (optional)", isOn: $sharePhotoConsent)
                    .toggleStyle(CheckboxToggleStyle(tintColor: brandColor))
                    .padding(.top, 8) // Add some space above
            }

            // Additional Feedback TextEditor
            VStack(alignment: .leading, spacing: 6) {
                Text("Additional details (optional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                TextEditor(text: $viewModel.feedbackData.feedbackText)
                    .frame(minHeight: 80, maxHeight: 150) // Adjusted height
                    .font(.body)
                    .padding(8)
                    .background(Color.gray.opacity(0.1)) // Use light gray background
                    .cornerRadius(8) // Rounded corners for editor
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1) // Subtle border
                    )
            }

            // Error Message
            if let error = viewModel.error {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }

            // Submit Button - Centered
            HStack {
                Spacer()
                Button(action: {
                    viewModel.submitFeedback(sharePhotoConsent: sharePhotoConsent)
                }) {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white) // Make spinner white on colored background
                            .frame(height: 20) // Match text height approx
                    } else {
                        Text("Submit Feedback")
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12) // Standard button padding
                .frame(minHeight: 44) // Ensure minimum tap target size
                .background(brandColor) // Use brand color
                .foregroundColor(.white)
                .clipShape(Capsule()) // Use capsule shape for submit button
                .disabled(viewModel.isSubmitting) // Remove isFeedbackDataValid check as it's not implemented
                .opacity(viewModel.isSubmitting ? 0.6 : 1.0) // Dim when disabled
                Spacer()
            }
            .padding(.top, 8) // Space above button
        }
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