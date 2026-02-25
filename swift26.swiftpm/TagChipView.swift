//
//  TagChipView.swift
//  The Living Prompt Tree
//
//  Status chip for tracking criteria (e.g., [Clear Intent], [Has Audience]).
//

import SwiftUI

/// A status tag chip. Complete = green fill. Incomplete = outline only.
struct TagChipView: View {
    let label: String
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))

            Text(label)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(isComplete ? .white : Theme.charcoal.opacity(0.7))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isComplete ? Theme.safeGreen : Color.clear)
                .overlay(
                    Capsule()
                        .stroke(
                            isComplete ? Theme.safeGreen : Theme.charcoal.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
        )
        .animation(Theme.springAnim, value: isComplete)
    }
}
