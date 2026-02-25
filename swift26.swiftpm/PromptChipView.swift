//
//  PromptChipView.swift
//  The Living Prompt Tree
//
//  Tappable word chip for Level 3's word-strike interface.
//

import SwiftUI

/// A tappable word chip. Struck words show strikethrough + gray tint.
struct PromptChipView: View {
    let word: String
    let isStruck: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(word)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .strikethrough(isStruck, color: Theme.dangerRed)
                .foregroundColor(isStruck ? .gray : Theme.charcoal)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isStruck ? Color.gray.opacity(0.15) : Theme.parchment)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isStruck ? Color.gray.opacity(0.3) : Theme.warmBrown.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(Theme.springAnim, value: isStruck)
    }
}
