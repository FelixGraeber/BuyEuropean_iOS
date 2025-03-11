//
//  ClassificationBadgeView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI

struct ClassificationBadgeView: View {
    let style: ClassificationStyle
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Main badge
            Text(style.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(style.badgeColor)
                .cornerRadius(30)
                .shadow(color: style.badgeColor.opacity(0.3), radius: 5, x: 0, y: 2)
                .scaleEffect(isAnimated ? 1.0 : 0.8)
                .opacity(isAnimated ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isAnimated)
            
            // Description text
            Text(style.description)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(isAnimated ? 1.0 : 0.0)
                .offset(y: isAnimated ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: isAnimated)
        }
        .padding(.vertical, 8)
        .onAppear {
            withAnimation {
                isAnimated = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ClassificationBadgeView(style: ClassificationStyle.forClassification(.europeanCountry))
        ClassificationBadgeView(style: ClassificationStyle.forClassification(.europeanAlly))
        ClassificationBadgeView(style: ClassificationStyle.forClassification(.europeanSceptic))
        ClassificationBadgeView(style: ClassificationStyle.forClassification(.europeanAdversary))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
