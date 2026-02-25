//
//  ElementHeaderView.swift
//  The Living Prompt Tree
//
//  Level title bar showing element emoji, name, principle, and step indicator.
//

import SwiftUI

/// Header bar for each level showing the element icon, name, and current step.
struct ElementHeaderView: View {
    let emoji: String
    let elementName: String
    let principle: String
    let step: Int

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(elementName)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(Theme.cream)

                    Text(principle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.amber)
                }
            }

            Spacer()

            // Step badge
            Text("Step \(step)/5")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.cream.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
