import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PhotoPreviewView: View {
    let image: UIImage
    let previewWidth: CGFloat // Passed from ScanView
    let previewHeight: CGFloat // Passed from ScanView
    let onBackToCamera: () -> Void
    let onAnalyze: () -> Void

    // Consistent Button Styling Values (can be adjusted)
    private let buttonCornerRadius: CGFloat = 12
    private let buttonVerticalPadding: CGFloat = 14
    private let buttonHorizontalPadding: CGFloat = 16 // Can be adjusted if needed
    private let buttonSpacing: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {

                // Main content area (Image Preview)
                // Use ZStack to center the preview vertically like the camera view
                ZStack {
                    Color(.systemBackground)
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 16) { // Add spacing if needed above/below image
                        Spacer().frame(height: 16) // Consistent top spacing like Camera mode

                        // Image preview matching CameraPreview appearance
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill() // Fill the frame, might crop slightly
                            .frame(width: previewWidth, height: previewHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 16)) // Match corner radius
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray5), lineWidth: 1) // Match border
                            )
                            .shadow( // Match shadow
                                color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4
                            )
                            .frame(width: previewWidth, height: previewHeight) // Ensure frame holds the size

                        Spacer() // Pushes image towards the top
                    }
                    .padding(.horizontal, 20) // Match horizontal padding of camera preview container
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)


                // Bottom Controls Area
                VStack(spacing: geometry.size.width < 375 ? 10 : 16) {
                    HStack(spacing: buttonSpacing) {
                        // Back Button (using material background)
                        Button(action: onBackToCamera) {
                            Label("Back", systemImage: "arrow.left")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, buttonVerticalPadding)
                                // .padding(.horizontal, buttonHorizontalPadding) // Add if needed
                        }
                        .buttonStyle(.bordered) // Use bordered style for a nice look
                        .tint(.secondary) // Grayish tint for secondary action
                        .controlSize(.large) // Consistent large size
                        .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius)) // Consistent corner radius


                        // Analyze Button (using brand color)
                        Button(action: onAnalyze) {
                             Label("Analyze Now", systemImage: "viewfinder") // Changed icon slightly
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, buttonVerticalPadding)
                                // .padding(.horizontal, buttonHorizontalPadding) // Add if needed
                                .background(
                                    RoundedRectangle(cornerRadius: buttonCornerRadius)
                                        .fill(Color(red: 0/255, green: 51/255, blue: 153/255)) // Brand color
                                        .shadow(color: Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.3), radius: 5, x: 0, y: 3)
                                )
                                .foregroundColor(.white)
                        }
                         .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius)) // Ensure clip shape applies if background doesn't
                         .controlSize(.large)
                    }
                    .padding(.horizontal, 20) // Consistent horizontal padding
                }
                .padding(.top, geometry.size.width < 375 ? 8 : 12) // Space above buttons
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, geometry.size.width < 375 ? 12 : 16)) // Respect safe area + minimum padding
                .background(.regularMaterial) // Subtle material background for controls
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: -1) // Subtle top shadow
            }
            .edgesIgnoringSafeArea(.bottom) // Allow controls to go into bottom safe area bg
        }
    }
}

// MARK: - Preview Provider

struct PhotoPreviewView_Previews: PreviewProvider {
    // Simulate dimensions for preview
    static let previewWidth: CGFloat = 360
    static let previewHeight: CGFloat = previewWidth * 1.35

    static var previews: some View {
        PhotoPreviewView(
            image: UIImage(systemName: "photo.fill")!, // Use a filled icon for better visibility
            previewWidth: previewWidth,
            previewHeight: previewHeight,
            onBackToCamera: { print("Back Tapped") },
            onAnalyze: { print("Analyze Tapped") }
        )
        .previewDisplayName("iPhone 14 Pro")
        .previewDevice("iPhone 14 Pro")

        PhotoPreviewView(
            image: UIImage(systemName: "photo.fill")!,
            previewWidth: 300, // Smaller width
            previewHeight: 300 * 1.35,
            onBackToCamera: {},
            onAnalyze: {}
        )
        .previewDisplayName("iPhone SE")
        .previewDevice("iPhone SE (3rd generation)")
    }
}