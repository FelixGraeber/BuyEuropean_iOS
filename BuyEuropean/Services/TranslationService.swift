import Foundation
import NaturalLanguage

/// Service responsible for handling on-device translation.
/// Available on iOS 16.0+.
actor TranslationService {
    
    /// Translates the provided text to the target locale.
    /// - Parameters:
    ///   - text: The text to translate.
    ///   - targetLocale: The locale to translate to. Defaults to the user's current locale.
    /// - Returns: The translated text if successful, or nil if translation is unavailable or fails.
    func translate(text: String, to targetLocale: Locale = Locale.current) async -> String? {
        // Skip translation if text is empty
        guard !text.isEmpty else {
            return text
        }
        
        // Determine source language
        let languageRecognizer = NLLanguageRecognizer()
        languageRecognizer.processString(text)
        
        guard let dominantLanguage = languageRecognizer.dominantLanguage else {
            print("Could not determine source language")
            return nil
        }
        
        // Get target language code
        guard let targetLanguageCode = targetLocale.language.languageCode?.identifier else {
            print("Could not determine target language code")
            return nil
        }
        
        // Skip if source and target are the same
        if dominantLanguage.rawValue == targetLanguageCode {
            // No need to translate if the source language is already the target language
            return text
        }
        
        // Use web-based translation API
        do {
            let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(dominantLanguage.rawValue)&tl=\(targetLanguageCode)&dt=t&q=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            guard let url = URL(string: urlString) else {
                print("Failed to create translation URL")
                return nil
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Parse the JSON response - fixed to concatenate all translated segments
            if let json = try JSONSerialization.jsonObject(with: data) as? Array<Any>,
               let translationArray = json.first as? Array<Any> {
                
                // The first element in the JSON response is an array of translation segments
                // Each segment is an array where the first element is the translated text
                var completeTranslation = ""
                
                // Go through all segments and concatenate them
                for translationSegment in translationArray {
                    if let segment = translationSegment as? Array<Any>,
                       let translatedTextPart = segment.first as? String {
                        completeTranslation += translatedTextPart
                    }
                }
                
                if !completeTranslation.isEmpty {
                    return completeTranslation
                } else {
                    print("Failed to extract any translation text")
                    return nil
                }
            } else {
                print("Failed to parse translation response")
                return nil
            }
        } catch {
            print("Translation error: \(error.localizedDescription)")
            return nil
        }
    }
} 