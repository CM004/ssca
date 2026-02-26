//
//  EvaluationResultView.swift
//  The Living Prompt Tree
//
//  Clean iOS-native result card: system styling, grouped list look.
//

import SwiftUI

struct EvaluationResultView: View {
    let emoji: String
    let title: String
    let score: StageScore
    let ctaLabel: String
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Label("\(emoji) \(title)", systemImage: "checkmark.seal")
                    .font(.headline)
                Spacer()
                Text(score.label)
                    .font(.subheadline.weight(.bold).monospaced())
                    .foregroundStyle(.green)
            }

            Divider()

            ForEach(Array(score.checks.enumerated()), id: \.offset) { _, check in
                HStack(spacing: 8) {
                    Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(check.passed ? .green : .orange)
                        .font(.subheadline)
                    Text(check.label)
                        .font(.subheadline)
                    Spacer()
                }
            }

            Divider()

            Text(score.feedback)
                .font(.callout)
                .foregroundStyle(.secondary)
                .italic()

            Button(action: onContinue) {
                Text(ctaLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.green)
        }
        .padding(16)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }
}
