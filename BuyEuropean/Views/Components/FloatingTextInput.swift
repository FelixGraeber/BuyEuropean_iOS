import SwiftUI
import Combine

struct FloatingTextInput: View {
    @Binding var text: String
    @Binding var isExpanded: Bool
    var onSubmit: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            if isExpanded {
                // Full screen overlay when expanded
                ZStack {
                    // White background
                    Color.white.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Top header with title and close button
                        HStack {
                            Text("Manual Input")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                // Dismiss keyboard and collapse
                                isTextFieldFocused = false
                                withAnimation(.spring(response: 0.3)) {
                                    isExpanded = false
                                    text = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(.systemGray3))
                            }
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 16)
                        .padding(.horizontal, 20)
                        
                        // Hint text
                        Text("Enter a brand or product name to analyze")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        // Input field and send button
                        HStack(spacing: 12) {
                            // Text input with rounded background
                            HStack {
                                TextField("Brand/product name", text: $text)
                                    .focused($isTextFieldFocused)
                                    .font(.body)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .submitLabel(.send)
                                    .onSubmit(handleSubmit)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                            )
                            
                            // Send button
                            Button(action: handleSubmit) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        ZStack {
                                            Circle().fill(text.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                                        }
                                    )
                            }
                            .disabled(text.isEmpty)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        
                        Spacer()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    // Set focus on text field when expanded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }
            } else {
                // Floating button when collapsed
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded = true
                    }
                }) {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            ZStack {
                                Circle().fill(Color.blue.opacity(0.8))
                                Circle().fill(Color.blue).padding(4)
                            }
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
                }
                .position(x: geometry.size.width - 50, y: geometry.size.height - 160)
                .transition(.scale.combined(with: .opacity))
            }
        }
        // Add tap gesture to dismiss keyboard when tapping outside the text field
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                if isExpanded && !isTextFieldFocused {
                    isTextFieldFocused = false
                }
            }
        )
    }
    
    private func handleSubmit() {
        guard !text.isEmpty else { return }
        
        // Dismiss keyboard
        isTextFieldFocused = false
        
        // Submit text and dismiss
        onSubmit()
        
        // Animate back to collapsed state
        withAnimation(.spring(response: 0.3)) {
            isExpanded = false
            // Don't clear text immediately as it creates a jarring effect
            // The view model will handle clearing if needed
        }
    }
}

struct FloatingTextInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FloatingTextInput(text: .constant(""), isExpanded: .constant(false), onSubmit: {})
                .previewDisplayName("Collapsed")
            FloatingTextInput(text: .constant("Demo text"), isExpanded: .constant(true), onSubmit: {})
                .previewDisplayName("Expanded")
        }
    }
} 