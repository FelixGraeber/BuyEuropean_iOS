import Foundation
import Combine

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
    
    private init() {}
    
    func analyzeProduct(imageBase64: String, prompt: String? = nil) async throws -> BuyEuropeanResponse {
        guard let url = URL(string: "\(baseURL)/analyze-product") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = AnalyzeProductRequest(image: imageBase64, prompt: prompt)
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            throw APIError.encodingError(error)
        }
        
        do {
            _ = try JSONSerialization.data(withJSONObject: [:], options: [])
            let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(BuyEuropeanResponse.self, from: data)
            } catch {
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
        guard let url = URL(string: "\(baseURL)/analyze-text") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = AnalyzeTextRequest(
            product_text: text,
            prompt: prompt,
            userLocation: nil
        )
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            throw APIError.encodingError(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(BuyEuropeanResponse.self, from: data)
            } catch {
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
