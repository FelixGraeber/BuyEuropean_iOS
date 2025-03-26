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

                // Main content area
                ZStack {
                    // Modern light background
                    Color(.systemBackground)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: 16)
                        
                        // Image preview in same position as viewfinder
                        ZStack {
                            // Image container matching camera viewfinder dimensions
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: min(UIScreen.main.bounds.width, 400),
                                       height: min(UIScreen.main.bounds.width * 1.28, 512))
                                .clipped()
                        }
                        .frame(width: min(UIScreen.main.bounds.width, 400),
                               height: min(UIScreen.main.bounds.width * 1.28, 512))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack(spacing: geometry.size.width < 375 ? 8 : 16) {
                    // Button row with Back and Analyze
                    HStack(spacing: 12) {
                        // Back button
                        Button(action: onBackToCamera) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.left")
                                    .font(.headline)
                                Text("Back")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                            )
                            .foregroundColor(.primary)
                        }
                        
                        // Analyze button
                        Button(action: onAnalyze) {
                            HStack(spacing: 12) {
                                Image(systemName: "viewfinder")
                                    .font(.headline)
                                Text("Analyze now")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0/255, green: 51/255, blue: 153/255)) // European blue
                                    .shadow(color: Color(red: 0/255, green: 51/255, blue: 153/255).opacity(0.3), radius: 5, x: 0, y: 3)
                            )
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Bottom spacing
                    Spacer().frame(height: geometry.safeAreaInsets.bottom > 0 ? 0 : (geometry.size.width < 375 ? 16 : 20))
                }
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
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
