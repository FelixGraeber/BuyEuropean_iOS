//
//  AlternativeCardView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI

struct AlternativeCardView: View {
    let alternative: EuropeanAlternative
    let countryFlag: String
    let onLearnMore: () -> Void
    @State private var isAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with product name and country flag
            HStack {
                Text(alternative.productName)
                    .font(.headline)
                    .foregroundColor(Color.blue.opacity(0.8))
                
                Spacer()
                
                if alternative.country != nil {
                    Text(countryFlag)
                        .font(.title2)
                }
            }
            
            // Company name
            Text(alternative.company)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
            
            // Description
            Text(alternative.description)
                .font(.body)
                .foregroundColor(Color(.label))
                .padding(.top, 4)
            
            // Learn more button
            Button(action: onLearnMore) {
                HStack {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.footnote)
                        
                        Text("Learn More")
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                isAnimated = true
            }
        }
    }
}

struct AlternativesHeaderView: View {
    @State private var isAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("European Alternatives")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text("Vote with your money by choosing European alternatives!")
                .font(.subheadline)
                .foregroundColor(Color.blue.opacity(0.8))
                .italic()
        }
        .padding(.bottom, 8)
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimated = true
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            AlternativesHeaderView()
            
            AlternativeCardView(
                alternative: EuropeanAlternative(
                    productName: "Fairphone 4",
                    company: "Fairphone",
                    description: "Sustainable and ethical smartphone with modular design for easy repairs and upgrades.",
                    country: "Netherlands"
                ),
                countryFlag: "🇳🇱",
                onLearnMore: {}
            )
            
            AlternativeCardView(
                alternative: EuropeanAlternative(
                    productName: "Nokia X20",
                    company: "HMD Global",
                    description: "Durable smartphone with clean Android experience and excellent battery life.",
                    country: "Finland"
                ),
                countryFlag: "🇫🇮",
                onLearnMore: {}
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
