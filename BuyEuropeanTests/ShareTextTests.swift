import XCTest
import SwiftUI // Required for ResultsView
@testable import BuyEuropean // To access ResultsView, BuyEuropeanResponse, etc.

// If BuyEuropeanResponse, Classification, etc. are not found,
// ensure "Models.swift" is included in the "Compile Sources" phase
// of the "BuyEuropeanTests" target.

class ShareTextTests: XCTestCase {

    // Consistent App Store Link as used in ResultsView
    private let appStoreLink = "https://apps.apple.com/de/app/buyeuropean/id6743128862?l=en-GB"

    // Mock Data Generators
    static func europeanProductResponse() -> BuyEuropeanResponse {
        return BuyEuropeanResponse(
            id: 1,
            thinking: "Thinking...",
            identifiedProductName: "Premium European Chocolate",
            identifiedCompany: "EuroChoco GmbH",
            identifiedCompanyHeadquarters: "DE", // Germany
            ultimateParentCompany: nil,
            ultimateParentCompanyHeadquarters: nil,
            identificationRationale: "Made in Germany.",
            productOrAnimalOrHuman: .product,
            classification: .europeanCountry, // Using actual enum case
            potentialAlternativeThinking: nil,
            potentialAlternatives: nil,
            inputTokens: 10,
            outputTokens: 20,
            totalTokens: 30
        )
    }

    static func nonEuropeanProductWithAlternativesResponse() -> BuyEuropeanResponse {
        let alternatives = [
            EuropeanAlternative(productName: "EuroSnack Bar", company: "EuroFoods AG", description: "A tasty European snack", country: "CH"),
            EuropeanAlternative(productName: "French Delight Pastry", company: "Patisserie SA", description: "Authentic French pastry", country: "FR")
        ]
        return BuyEuropeanResponse(
            id: 2,
            thinking: "Thinking...",
            identifiedProductName: "Global Generic Soda",
            identifiedCompany: "GlobalCorp Inc.",
            identifiedCompanyHeadquarters: "US",
            ultimateParentCompany: nil,
            ultimateParentCompanyHeadquarters: nil,
            identificationRationale: "Made by a US company.",
            productOrAnimalOrHuman: .product,
            classification: .neutral, // Using actual enum case for non-European
            potentialAlternativeThinking: "Consider these European options.",
            potentialAlternatives: alternatives,
            inputTokens: 10,
            outputTokens: 20,
            totalTokens: 30
        )
    }

    static func nonEuropeanProductWithoutAlternativesResponse() -> BuyEuropeanResponse {
        return BuyEuropeanResponse(
            id: 3,
            thinking: "Thinking...",
            identifiedProductName: "Imported Gadget X",
            identifiedCompany: "Overseas Electronics Ltd.",
            identifiedCompanyHeadquarters: "CN",
            ultimateParentCompany: nil,
            ultimateParentCompanyHeadquarters: nil,
            identificationRationale: "Imported product.",
            productOrAnimalOrHuman: .product,
            classification: .neutral, // Using actual enum case for non-European
            potentialAlternativeThinking: nil,
            potentialAlternatives: [], // Empty alternatives
            inputTokens: 10,
            outputTokens: 20,
            totalTokens: 30
        )
    }

    static func europeanCompanyResponse() -> BuyEuropeanResponse {
        // For a COMPANY_IS_EUROPEAN, identifiedProductName might be less relevant or nil
        return BuyEuropeanResponse(
            id: 4,
            thinking: "Thinking...",
            identifiedProductName: "Various Products", // Or nil, depending on how your app handles this
            identifiedCompany: "EuroServices Co.",
            identifiedCompanyHeadquarters: "FR", // France
            ultimateParentCompany: nil,
            ultimateParentCompanyHeadquarters: nil,
            identificationRationale: "Company based in France.",
            productOrAnimalOrHuman: .product, // Assuming it's about the company's products
            classification: .europeanCountry, // Using actual enum case; shareText logic will determine display
            potentialAlternativeThinking: nil,
            potentialAlternatives: nil,
            inputTokens: 10,
            outputTokens: 20,
            totalTokens: 30
        )
    }

    static func otherClassificationResponse() -> BuyEuropeanResponse {
        return BuyEuropeanResponse(
            id: 5,
            thinking: "Thinking...",
            identifiedProductName: "Picture of a Cat", // Or nil
            identifiedCompany: nil,
            identifiedCompanyHeadquarters: nil,
            ultimateParentCompany: nil,
            ultimateParentCompanyHeadquarters: nil,
            identificationRationale: "It's a cat.",
            productOrAnimalOrHuman: .cat,
            classification: .animal, // Using actual enum case
            potentialAlternativeThinking: nil,
            potentialAlternatives: nil,
            inputTokens: 10,
            outputTokens: 20,
            totalTokens: 30
        )
    }

    // Helper to get localized country name (mirroring ResultsView's internal helper)
    private func getCountryName(from code: String?) -> String {
        guard let code = code, !code.isEmpty else { return "an unknown country" }
        return Locale.current.localizedString(forRegionCode: code) ?? code
    }

    // --- Test Methods ---

    func testShareText_ForEuropeanProduct_IsCorrect() {
        let response = ShareTextTests.europeanProductResponse()
        let view = ResultsView(response: response, analysisImage: nil, onDismiss: {})
        let generatedText = view.shareText

        let countryName = getCountryName(from: response.identifiedCompanyHeadquarters) // Updated to use identifiedCompanyHeadquarters
        let expectedProductName = response.identifiedProductName // No longer using ?? "This product" here, view logic handles it
        let expectedText = "\(expectedProductName!) is European! (Made by \(response.identifiedCompany!) in \(countryName)). Found with BuyEuropean: \(appStoreLink)"

        XCTAssertEqual(generatedText, expectedText, "Share text for European product is incorrect.")
    }

    func testShareText_ForNonEuropeanProductWithAlternatives_IsCorrect() {
        let response = ShareTextTests.nonEuropeanProductWithAlternativesResponse()
        let view = ResultsView(response: response, analysisImage: nil, onDismiss: {})
        let generatedText = view.shareText

        let currentProductName = response.identifiedProductName.isEmpty ? "This product" : response.identifiedProductName
        let alternativeExample = response.potentialAlternatives?.first?.productName ?? "European brands" // model uses productName
        let expectedText = "\(currentProductName) isn't European. BuyEuropean suggested alternatives like \(alternativeExample). Check it out: \(appStoreLink)"

        XCTAssertEqual(generatedText, expectedText, "Share text for non-European product with alternatives is incorrect.")
    }

    func testShareText_ForNonEuropeanProductWithoutAlternatives_IsCorrect() {
        let response = ShareTextTests.nonEuropeanProductWithoutAlternativesResponse()
        let view = ResultsView(response: response, analysisImage: nil, onDismiss: {})
        let generatedText = view.shareText

        let currentProductName = response.identifiedProductName.isEmpty ? "This product" : response.identifiedProductName
        let expectedText = "Checking product origins with the BuyEuropean app. \(currentProductName) was analyzed. Find out more: \(appStoreLink)"

        XCTAssertEqual(generatedText, expectedText, "Share text for non-European product without alternatives is incorrect.")
    }

    func testShareText_ForEuropeanCompany_IsCorrect() {
        let response = ShareTextTests.europeanCompanyResponse()
        let view = ResultsView(response: response, analysisImage: nil, onDismiss: {})
        let generatedText = view.shareText

        let countryName = getCountryName(from: response.identifiedCompanyHeadquarters)
        // Logic from ResultsView: let determinedName = (response.identifiedProductName.isEmpty || response.identifiedProductName == "Unknown Product") ? companyName : currentProductName
        // For this specific mock, identifiedProductName is "Various Products", so it should be used.
        let companyNameString = response.identifiedCompany ?? "the company"
        let determinedName = (response.identifiedProductName.isEmpty || response.identifiedProductName == "Unknown Product") ? companyNameString : response.identifiedProductName
        let companyInfo = response.identifiedCompany ?? "a European company"
        let expectedText = "\(determinedName!) is European! (Made by \(companyInfo) in \(countryName)). Found with BuyEuropean: \(appStoreLink)"

        XCTAssertEqual(generatedText, expectedText, "Share text for European company is incorrect.")
    }

    func testShareText_ForOtherClassification_IsCorrect() {
        let response = ShareTextTests.otherClassificationResponse()
        let view = ResultsView(response: response, analysisImage: nil, onDismiss: {})
        let generatedText = view.shareText

        let expectedText = "I used the BuyEuropean app to analyze an item. See what it can do for you: \(appStoreLink)"

        XCTAssertEqual(generatedText, expectedText, "Share text for other classification is incorrect.")
    }

    func testCountryNameHelper_KnownCode() {
        XCTAssertEqual(getCountryName(from: "DE"), "Germany", "Country code DE should return Germany.")
        XCTAssertEqual(getCountryName(from: "FR"), "France", "Country code FR should return France.")
        // Add more specific country code tests if necessary for your app's supported regions
    }

    func testCountryNameHelper_UnknownOrEmptyCode() {
        XCTAssertEqual(getCountryName(from: "XX"), "XX", "Unknown country code should return the code itself.")
        XCTAssertEqual(getCountryName(from: ""), "an unknown country", "Empty country code should return default placeholder.")
        XCTAssertEqual(getCountryName(from: nil), "an unknown country", "Nil country code should return default placeholder.")
    }
}

// Make sure your actual Classification enum in Models.swift has these cases,
// or adjust the mock data and tests to use the correct enum cases from your app.
// Example:
/*
extension Classification { // Assuming Classification is the enum name
    static var PRODUCT_IS_EUROPEAN: Classification { .europeanCountry } // Map to an existing valid case
    static var PRODUCT_IS_NOT_EUROPEAN: Classification { .neutral } // Map to an existing valid case
    static var COMPANY_IS_EUROPEAN: Classification { .europeanCountry } // Map to an existing valid case
    static var ANIMAL_IN_IMAGE: Classification { .animal } // Map to an existing valid case
}
*/
// The actual Classification enum has cases like:
// .europeanCountry, .europeanAlly, .neutral, .cat, .dog, .animal, .human, .unknown
// The ResultsView.swift's shareText logic uses:
// .PRODUCT_IS_EUROPEAN, .COMPANY_IS_EUROPEAN, .PRODUCT_IS_NOT_EUROPEAN,
// .ANIMAL_IN_IMAGE, .HUMAN_IN_IMAGE, .UNKNOWN_PRODUCT_OR_COMPANY etc.
// These seem to be different sets of enums or the test needs to use the ones from Models.swift.
// Removed comments about placeholder classifications as they are now using actual enums.
