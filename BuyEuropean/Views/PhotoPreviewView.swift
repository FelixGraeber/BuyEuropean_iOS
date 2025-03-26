import SwiftUI

struct PhotoPreviewView: View {
    let image: UIImage
    let onBackToCamera: () -> Void
    let onAnalyze: () -> Void
    
    // Device metrics for responsive design
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Computed properties for responsive layout
    private var isSmallDevice: Bool {
        #if canImport(UIKit)
        return UIScreen.main.bounds.width < 375
        #else
        return false // Default for non-UIKit platforms
        #endif
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Back button with enhanced styling for square design theme
                HStack {
                    Button(action: onBackToCamera) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.square.fill")
                                .font(.body.weight(.semibold))
                            Text("Back to Camera")
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        )
                        .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                    }
                    
                    Spacer()
                    
                    // Dimension indicator
                    Text("512×512")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(Color(.systemGray2))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
                
                // Main preview content
                ZStack {
                    // Modern light background
                    Color(.systemBackground)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 24) {
                        // Title for review screen with improved styling
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.8))
                            
                            Text("Review Image")
                                .font(.headline)
                                .foregroundColor(Color(red: 0/255, green: 51/255, blue: 153/255))
                        }
                        
                        // Explanation subtitle
                        Text("Captured image ready for analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        // Square container with enhanced multi-layered styling
                        ZStack {
                            // Outer decorative frame with visual depth
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .frame(width: min(geometry.size.width - 40, 512) + 6,
                                       height: min(geometry.size.width - 40, 512) + 6)
                                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
                            
                            // Second decorative frame for layered effect
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 245/255, green: 247/255, blue: 250/255))
                                .frame(width: min(geometry.size.width - 40, 512) + 6,
                                       height: min(geometry.size.width - 40, 512) + 6)
                            
                            // Image displayed in a square container - exactly 512x512 max
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: min(geometry.size.width - 40, 512),
                                       height: min(geometry.size.width - 40, 512))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        
                        // Instruction text with improved styling
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Ready to analyze product")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
                
                // Enhanced Analyze Image button for review screen with square design theme
                Button(action: onAnalyze) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up.on.square.fill")
                            .font(.headline)
                        
                        Text("Analyze")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if geometry.size.width >= 375 {
                            Text("512×512 Image")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, geometry.size.width < 375 ? 16 : 18)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                            .shadow(color: Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.4), radius: 10, x: 0, y: 4)
                    )
                    .foregroundColor(.white)
                }
                .padding(.horizontal, geometry.size.width < 375 ? 20 : 32)
                .padding(.vertical, geometry.size.width < 375 ? 12 : 16)
                
                // Add padding below the Analyze button
                Spacer().frame(height: geometry.safeAreaInsets.bottom > 0 ? 0 : (geometry.size.width < 375 ? 16 : 20))
            }
        }
    }
}

// Preview
struct PhotoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPreviewView(
            image: UIImage(systemName: "photo")!,
            onBackToCamera: {},
            onAnalyze: {}
        )
        .previewDevice("iPhone 14 Pro")
        .previewDisplayName("iPhone 14 Pro")
    }
} 