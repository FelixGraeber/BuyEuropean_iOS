import SwiftUI

struct CameraPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    var onRequestPermission: () async -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "camera.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)
            
            Text("Camera Access Needed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("BuyEuropean needs camera access to take photos of your product or brand.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    Task {
                        await onRequestPermission()
                        dismiss()
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Not Now")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
}
