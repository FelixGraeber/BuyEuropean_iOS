//
//  ErrorView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                    .padding()
                
                Text(LocalizedStringKey("error.title"))
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(message) // This 'message' is dynamic, so it's already a variable. No localization needed here.
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onDismiss) {
                    Text(LocalizedStringKey("error.button.try_again"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .padding()
            .navigationBarTitle(Text(LocalizedStringKey("error.title")), displayMode: .inline)
            .navigationBarItems(trailing: Button(LocalizedStringKey("common.dismiss")) {
                onDismiss()
            })
        }
    }
}
