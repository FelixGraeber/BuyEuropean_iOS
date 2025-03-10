//
//  ResultsView.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 10.03.25.
//

import SwiftUI

struct ResultsView: View {
    let response: BuyEuropeanResponse
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product identification section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Product Identification")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Divider()
                        
                        productInfoRow(title: "Product", value: response.identifiedProductName)
                        productInfoRow(title: "Company", value: response.identifiedCompany)
                        productInfoRow(title: "Headquarters", value: response.identifiedHeadquarters)
                        
                        // Classification badge
                        HStack {
                            Text("Classification:")
                                .fontWeight(.medium)
                            
                            Text(response.classification.displayName)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(classificationColor)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        .padding(.top, 4)
                        
                        // Rationale
                        Text("Identification Rationale:")
                            .fontWeight(.medium)
                            .padding(.top, 8)
                        
                        Text(response.identificationRationale)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Alternatives section (if any)
                    if shouldShowAlternatives {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("European Alternatives")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Divider()
                            
                            if let alternatives = response.potentialAlternatives, !alternatives.isEmpty {
                                ForEach(alternatives) { alternative in
                                    alternativeView(alternative: alternative)
                                }
                            } else if !response.potentialAlternative.isEmpty {
                                // Fallback to the string alternative if no structured alternatives
                                Text(response.potentialAlternative)
                                    .padding(.horizontal)
                            }
                            
                            if !response.potentialAlternativeThinking.isEmpty {
                                Text("Reasoning:")
                                    .fontWeight(.medium)
                                    .padding(.top, 8)
                                
                                Text(response.potentialAlternativeThinking)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Analysis Results", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                onDismiss()
            })
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
    
    private func productInfoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(title):")
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func alternativeView(alternative: EuropeanAlternative) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(alternative.productName)
                    .font(.headline)
                
                Spacer()
                
                if let country = alternative.country {
                    Text(country)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            Text(alternative.company)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(alternative.description)
                .padding(.top, 4)
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.vertical, 4)
    }
    
    private var classificationColor: Color {
        switch response.classification {
        case .europeanCountry:
            return Color.green
        case .europeanAlly:
            return Color.blue
        case .europeanSceptic:
            return Color.yellow
        case .europeanAdversary:
            return Color.red
        case .unknown:
            return Color.gray
        }
    }
    
    private var shouldShowAlternatives: Bool {
        // Show alternatives if it's not a European country
        return response.classification != .europeanCountry &&
               (response.potentialAlternatives != nil || !response.potentialAlternative.isEmpty)
    }
}
