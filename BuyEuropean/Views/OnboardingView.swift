import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                // Screen 1: Welcome & Value Proposition
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "🛍️") // Placeholder, replace with actual app icon or relevant SF Symbol
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.accentColor)

                    Text("Welcome to BuyEuropean!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Easily identify products from European companies. Make informed choices and support European businesses.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                    Spacer()
                }
                .tag(0)
                .padding()

                // Screen 2: Camera Permission Info
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.accentColor)

                    Text("Scan with Your Camera")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Use your camera to scan barcodes or product packaging. Grant camera access to start analyzing products instantly.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                    Spacer()
                }
                .tag(1)
                .padding()

                // Screen 3: Location Permission Info & Finish
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "location.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.accentColor)

                    Text("Enhance Your Results (Optional)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Allow location access to help us provide more relevant product analysis based on your region. This is optional and can be changed later in settings.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                    Button("Finish") {
                        showOnboarding = false
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    Spacer()
                }
                .tag(2)
                .padding()
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

            // Custom Page Control for better UX
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(selectedTab == index ? Color.accentColor : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20) // Adjust padding as needed
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(showOnboarding: .constant(true))
    }
}
