//
//  HeuristicEngine.swift
//  SSCA
//
//  Created by Chandramohan  on 20/02/26.
//

import Foundation

class HeuristicEngine {
    
    static func evaluate(prompt: String) -> AIResult {
        
        let wordCount = prompt.split(separator: " ").count
        
        var score: Double = 0.3
        var feedback = "Try adding more clarity."
        
        if wordCount > 5 {
            score += 0.2
        }
        
        if prompt.lowercased().contains("explain") {
            score += 0.2
        }
        
        if wordCount < 40 {
            score += 0.2
        }
        
        if prompt.contains("for a") {
            score += 0.1
        }
        
        return AIResult(score: min(score, 1.0),
                        feedback: "Heuristic evaluation complete. Try being more specific and concise.")
    }
}
