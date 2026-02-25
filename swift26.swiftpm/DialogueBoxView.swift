//
//  DialogueBoxView.swift
//  The Living Prompt Tree
//
//  Bottom dialogue box styled like Yume's Spellbook: rounded rect, cream
//  background, warm brown border, with character name label and animated arrow.
//

import SwiftUI

/// A dialogue box showing a character's speech with a tap-to-advance indicator.
struct DialogueBoxView: View {

    let characterName: String
    let message: String
    var onAdvance: () -> Void

    @State private var arrowBounce = false

    var body: some View {
        Button(action: onAdvance) {
            VStack(alignment: .leading, spacing: 8) {
                // Character name badge
                Text(characterName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.cream)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Theme.forestGreen)
                    )

                // Message text
                Text(message)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(Theme.charcoal)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                // Advance arrow
                HStack {
                    Spacer()
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.amber)
                        .offset(x: arrowBounce ? 4 : 0)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.cream)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.warmBrown.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 6, y: 3)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                arrowBounce = true
            }
        }
    }
}
