//
//  AIEngine.swift
//  SSCA
//
//  Created by Chandramohan  on 20/02/26.
//

import Foundation
import FoundationModels

struct AIResult {
    let score: Double
    let feedback: String
}

class AIEngine {
    
    static func evaluate(prompt: String) async -> AIResult {
        if #available(iOS 26.0, *) {
            do {
                // Only reference SystemLanguageModel and LanguageModelSession inside availability block
                let model = SystemLanguageModel.default
                guard model.availability == .available else {
                    fatalError("Foundation Model is not available on this device.")
                }

                let session = LanguageModelSession()
                let instruction = """
                Evaluate the clarity and efficiency of the following prompt.
                Give a score from 0 to 1.
                Provide one short improvement suggestion.

                Prompt:
                \(prompt)
                """

                let response = try await session.respond(to: instruction)
                let text = response.content
                let score = extractScore(from: text)
                return AIResult(score: score, feedback: text)
            } catch {
                fatalError("Foundation Model call failed: \(error.localizedDescription)")
            }
        } else {
            fatalError("iOS 26 or later is required for Foundation Models.")
        }
    }
    
    private static func extractScore(from text: String) -> Double {
        if let number = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap({ Double($0) }).first {
            return min(max(number, 0), 1)
        }
        return 0.5
    }
}
