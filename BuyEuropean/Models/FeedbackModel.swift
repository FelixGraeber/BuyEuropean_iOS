//
//  FeedbackModel.swift
//  BuyEuropean
//
//  Created by Felix Graeber on 11.03.25.
//

import Foundation

struct FeedbackModel: Codable {
    var analysisId: Int
    var isPositive: Bool
    var wrongProduct: Bool
    var wrongBrand: Bool
    var wrongCountry: Bool
    var wrongClassification: Bool
    var wrongAlternatives: Bool
    var feedbackText: String
    var imageData: String?
    
    enum CodingKeys: String, CodingKey {
        case analysisId = "analysis_id"
        case isPositive = "is_positive"
        case wrongProduct = "wrong_product"
        case wrongBrand = "wrong_brand"
        case wrongCountry = "wrong_country"
        case wrongClassification = "wrong_classification"
        case wrongAlternatives = "wrong_alternatives"
        case feedbackText = "feedback_text"
        case imageData = "image_data"
    }
    
    init(analysisId: Int, isPositive: Bool = true) {
        self.analysisId = analysisId
        self.isPositive = isPositive
        self.wrongProduct = false
        self.wrongBrand = false
        self.wrongCountry = false
        self.wrongClassification = false
        self.wrongAlternatives = false
        self.feedbackText = ""
        self.imageData = nil
    }
}
