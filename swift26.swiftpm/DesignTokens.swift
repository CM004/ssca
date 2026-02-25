//
//  DesignTokens.swift
//  The Living Prompt Tree
//
//  Shared color palette and style constants for the Spellbook visual theme.
//

import SwiftUI

/// Central design tokens for the Spellbook visual style.
enum Theme {
    // MARK: - Colors
    static let forestGreen    = Color(hex: 0x2D5016)
    static let soilBrown      = Color(hex: 0x4A2C0A)
    static let parchment      = Color(hex: 0xF5E6C8)
    static let cream          = Color(hex: 0xFFF8E7)
    static let amber          = Color(hex: 0xFFB347)
    static let warmBrown      = Color(hex: 0x8B6914)
    static let charcoal       = Color(hex: 0x2C2C2C)
    static let safeGreen      = Color(hex: 0x4CAF50)
    static let dangerRed      = Color(hex: 0xE57373)

    // MARK: - Gradients
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [forestGreen, soilBrown],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Animation
    static let springAnim = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static var levelTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
