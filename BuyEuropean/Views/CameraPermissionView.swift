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
            
            Text(LocalizedStringKey("permission.camera.title"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(LocalizedStringKey("permission.camera.description"))
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
                    Text(LocalizedStringKey("common.continue"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
}
