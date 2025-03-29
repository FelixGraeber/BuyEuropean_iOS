import Foundation
import Combine
import CoreLocation

// Import models - use direct model import 
import SwiftUI // For SwiftUI support
// These models should be accessible from the module
// BuyEuropeanResponse, AnalyzeProductRequest, AnalyzeTextRequest are defined in Models.swift

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case serverError(Int)
    case unknown
    
    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with status code: \(code)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://buy-e-ubackend-felixgraeber.replit.app"
    
    private var locationManager: LocationManager?

    private init() {}
    
    func setLocationManager(_ manager: LocationManager) {
        self.locationManager = manager
    }
    
    func analyzeProduct(imageBase64: String, prompt: String? = nil) async throws -> BuyEuropeanResponse {
        guard let url = URL(string: "\(baseURL)/v2/analyze-product") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var userLocationToSend: UserLocation? = nil

        // Check if location manager is available and authorized
        if let lm = locationManager, lm.isAuthorized {
            if let city = lm.currentCity, let country = lm.currentCountry {
                 userLocationToSend = UserLocation(city: city, country: country)
                 print("API Service (Product): Authorized. Will send location - City: \(city), Country: \(country)")
            } else {
                print("API Service (Product): Authorized but city/country not yet available.")
            }
        } else {
             print("API Service (Product): Location not authorized.")
        }
        
        // Trigger a location update *after* deciding what to send, only if authorized.
        if let lm = locationManager, lm.isAuthorized {
             lm.requestSingleLocationUpdate()
             print("API Service (Product): Authorized. Requested location update for next time.")
        }

        let requestBody = AnalyzeProductRequest(
            image: imageBase64, 
            prompt: prompt,
            userLocation: userLocationToSend // Pass the location object
        )
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
            // Debugging: Print the request body
            if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                 print("API Request Body (Product): \(bodyString)")
            }
        } catch {
            throw APIError.encodingError(error)
        }
        
        do {
            _ = try JSONSerialization.data(withJSONObject: [:], options: [])
            let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
            
            // Log the raw response data
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response Body (Product): \(responseString)")
            } else {
                print("API Response Body (Product): Could not decode data as UTF-8 string.")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                 // Print error response body if available
                 if let errorBody = String(data: data, encoding: .utf8) {
                      print("API Error Response Body (Product): \(errorBody)")
                 }
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(BuyEuropeanResponse.self, from: data)
            } catch {
                 // Print decoding error data if available
                 print("API Decoding Error (Product): \(error.localizedDescription)")
                 if let responseBody = String(data: data, encoding: .utf8) {
                      print("API Response Body (Failed Decode - Product): \(responseBody)")
                 }
                throw APIError.decodingError(error)
            }
        } catch let urlError as URLError {
            throw APIError.networkError(urlError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.unknown
        }
    }
    
    func submitFeedback(feedback: FeedbackModel) async throws {
        guard let url = URL(string: "\(baseURL)/api/feedback/analysis") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(feedback)
        } catch {
            throw APIError.encodingError(error)
        }
        
        do {
            _ = try JSONSerialization.data(withJSONObject: [:], options: [])
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Log the raw response data
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response Body (Feedback): \(responseString)")
            } else {
                print("API Response Body (Feedback): Could not decode data as UTF-8 string.")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // If we get an error response with data, try to decode it for more details
                if !data.isEmpty {
                    do {
                        if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                           let errorMessage = errorResponse["error"] {
                            print("Server error: \(errorMessage)")
                        }
                    } catch {
                        print("Failed to decode error response")
                    }
                }
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            // Successfully submitted feedback
            return
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func analyzeText(text: String, prompt: String? = nil) async throws -> BuyEuropeanResponse {
        guard let url = URL(string: "\(baseURL)/v2/analyze-text") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var userLocationToSend: UserLocation? = nil

        // Check if location manager is available and authorized (no setting check)
        if let lm = locationManager, lm.isAuthorized {
            if let city = lm.currentCity, let country = lm.currentCountry {
                 userLocationToSend = UserLocation(city: city, country: country)
                 print("API Service: Authorized. Will send location - City: \(city), Country: \(country)")
            } else {
                print("API Service: Authorized but city/country not yet available.")
                // Optionally trigger update here if needed, but requestSingleLocationUpdate below handles it
            }
        } else {
             print("API Service: Location not authorized.")
        }
        
        // Trigger a location update *after* deciding what to send, only if authorized.
        // This helps keep the location fresh for the next call.
        if let lm = locationManager, lm.isAuthorized {
             lm.requestSingleLocationUpdate()
             print("API Service: Authorized. Requested location update for next time.")
        }

        let requestBody = AnalyzeTextRequest(
            product_text: text,
            prompt: prompt,
            userLocation: userLocationToSend // Pass the prepared location object
        )
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
            // Debugging: Print the request body
            if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                 print("API Request Body: \(bodyString)")
            }
        } catch {
            throw APIError.encodingError(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Log the raw response data
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response Body (Text): \(responseString)")
            } else {
                print("API Response Body (Text): Could not decode data as UTF-8 string.")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                 // Print error response body if available
                 if let errorBody = String(data: data, encoding: .utf8) {
                      print("API Error Response Body: \(errorBody)")
                 }
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(BuyEuropeanResponse.self, from: data)
            } catch {
                // Print decoding error data if available
                 print("API Decoding Error: \(error.localizedDescription)")
                 if let responseBody = String(data: data, encoding: .utf8) {
                      print("API Response Body (Failed Decode): \(responseBody)")
                 }
                throw APIError.decodingError(error)
            }
        } catch let urlError as URLError {
            throw APIError.networkError(urlError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.unknown
        }
    }
}
