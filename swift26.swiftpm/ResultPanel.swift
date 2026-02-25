//
//  ResultPanel.swift
//  The Living Prompt Tree
//
//  Shared result display and success celebration panels used by all levels.
//

import SwiftUI

// MARK: - ResultPanel

/// Spellbook-styled evaluation result card.
struct ResultPanel: View {
    let result: EvaluationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: result.passed ? "checkmark.seal.fill" : "arrow.counterclockwise")
                    .font(.system(size: 18))
                    .foregroundColor(result.passed ? Theme.safeGreen : Theme.amber)

                Text(result.passed ? "Passed!" : "Not quite — try again")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Theme.charcoal)

                Spacer()

                // Score badge
                ZStack {
                    Circle()
                        .stroke(Theme.charcoal.opacity(0.1), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    Circle()
                        .trim(from: 0, to: Double(result.score) / 100.0)
                        .stroke(
                            result.passed ? Theme.safeGreen : Theme.amber,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 40, height: 40)

                    Text("\(result.score)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.charcoal)
                }
            }

            // Feedback
            Text(result.feedback)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(Theme.charcoal.opacity(0.8))
                .lineSpacing(4)

            // Issues
            if !result.detectedIssues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ISSUES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.dangerRed)

                    ForEach(result.detectedIssues, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.dangerRed.opacity(0.7))
                                .padding(.top, 3)
                            Text(issue)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.charcoal.opacity(0.7))
                        }
                    }
                }
            }

            // Suggestions
            if !result.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HINTS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.amber)

                    ForEach(result.suggestions, id: \.self) { s in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.amber.opacity(0.7))
                                .padding(.top, 3)
                            Text(s)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.charcoal.opacity(0.7))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.parchment)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            result.passed ? Theme.safeGreen.opacity(0.4) : Theme.amber.opacity(0.4),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - SuccessPanel

/// Celebratory card shown when a level element is restored.
struct SuccessPanel: View {
    let elementName: String
    let feedback: String
    let onContinue: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.amber.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse ? 1.3 : 1.0)
                    .opacity(pulse ? 0.4 : 0.2)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.amber)
            }

            Text("\(elementName) Restored! ✨")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(Theme.cream)

            Text(feedback)
                .font(.system(size: 13, design: .serif))
                .foregroundColor(Theme.cream.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)

            Button(action: onContinue) {
                HStack(spacing: 6) {
                    Text("Continue")
                        .font(.system(size: 15, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(Theme.charcoal)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Theme.amber)
                        .shadow(color: Theme.amber.opacity(0.3), radius: 6, y: 3)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.forestGreen.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.amber.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
        )
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
