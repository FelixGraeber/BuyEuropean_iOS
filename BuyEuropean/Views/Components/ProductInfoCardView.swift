//
//  ProductInfoCardView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import SwiftUI

struct ProductInfoCardView: View {
    let product: String
    let company: String
    let headquarters: String
    let rationale: String
    let countryFlag: String
    @State private var isRationaleExpanded = false
    @State private var isAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Product info
            infoRow(
                icon: "tag.fill",
                iconColor: Color.blue,
                title: "PRODUCT",
                value: product
            )
            
            // Company info
            infoRow(
                icon: "building.2.fill",
                iconColor: Color.purple,
                title: "COMPANY",
                value: company
            )
            
            // Headquarters info with flag
            HStack(alignment: .top, spacing: 12) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("COUNTRY (HEADQUARTER)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.secondaryLabel))
                    
                    HStack(alignment: .center, spacing: 8) {
                        Text(headquarters)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(countryFlag)
                            .font(.title2)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Rationale
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    // Icon container
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IDENTIFICATION RATIONALE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(.secondaryLabel))
                        
                        if isRationaleExpanded || rationale.count < 100 {
                            Text(rationale)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(rationale.prefix(100) + "...")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        if rationale.count >= 100 {
                            Button(action: {
                                withAnimation {
                                    isRationaleExpanded.toggle()
                                }
                            }) {
                                Text(isRationaleExpanded ? "Show Less" : "Read More")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimated = true
            }
        }
    }
    
    private func infoRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon container
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.secondaryLabel))
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ProductInfoCardView(
                product: "iPhone 13 Pro",
                company: "Apple Inc.",
                headquarters: "United States",
                rationale: "This product is manufactured by Apple Inc., which is headquartered in Cupertino, California, United States. Apple is a multinational technology company that designs, develops, and sells consumer electronics, computer software, and online services.",
                countryFlag: "🇺🇸"
            )
            
            ProductInfoCardView(
                product: "Galaxy S21",
                company: "Samsung Electronics",
                headquarters: "South Korea",
                rationale: "This product is manufactured by Samsung Electronics, which is headquartered in Suwon, South Korea. Samsung is a multinational electronics company.",
                countryFlag: "🇰🇷"
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
