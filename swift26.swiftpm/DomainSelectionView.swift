//
//  DomainSelectionView.swift
//  The Living Prompt Tree
//
//  Opening domain picker: Julie introduces herself and the user selects
//  a domain for personalised prompt examples throughout the 5 levels.
//

import SwiftUI

struct DomainSelectionView: View {

    @EnvironmentObject var appState: AppState
    var onSelect: (Domain) -> Void

    // Julie's dialogue lines
    private let dialogueLines: [String] = [
        "Hi! I'm Julie. I just asked an AI to help me, but the answer was… a mess.",
        "I think the problem is my prompt. Can you help me learn to write better ones?",
        "First, pick a topic you're curious about. I'll use it for all our practice prompts!"
    ]

    @State private var currentLine: Int = 0
    @State private var selectedDomain: Domain? = nil

    private let domainCards: [(domain: Domain, emoji: String, label: String, desc: String)] = [
        (.healthcare,       "🏥", "Healthcare",        "Medicine, wellness, nutrition"),
        (.finance,          "💰", "Finance",            "Money, investing, budgeting"),
        (.customerService,  "💬", "Customer Service",   "Support, communication, service"),
        (.general,          "📚", "General",            "Learning, research, everyday tasks")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Compact tree silhouette
                TreeView(appState: appState)
                    .frame(height: 160)
                    .scaleEffect(0.5)
                    .frame(height: 80)
                    .clipped()
                    .opacity(0.6)

                // Dialogue
                DialogueBoxView(
                    characterName: "🌱 Julie",
                    message: dialogueLines[currentLine]
                ) {
                    if currentLine < dialogueLines.count - 1 {
                        withAnimation(Theme.springAnim) {
                            currentLine += 1
                        }
                    }
                }

                // Domain grid (shown after dialogue advances)
                if currentLine >= dialogueLines.count - 1 {
                    VStack(spacing: 12) {
                        ForEach(domainCards, id: \.domain) { card in
                            Button {
                                withAnimation(Theme.springAnim) {
                                    selectedDomain = card.domain
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Text(card.emoji)
                                        .font(.system(size: 28))
                                        .frame(width: 44)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(card.label)
                                            .font(.system(size: 16, weight: .bold, design: .serif))
                                            .foregroundColor(Theme.charcoal)
                                        Text(card.desc)
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.charcoal.opacity(0.6))
                                    }

                                    Spacer()

                                    if selectedDomain == card.domain {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Theme.safeGreen)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            selectedDomain == card.domain
                                                ? Theme.amber.opacity(0.15)
                                                : Theme.parchment
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    selectedDomain == card.domain
                                                        ? Theme.amber
                                                        : Theme.warmBrown.opacity(0.2),
                                                    lineWidth: selectedDomain == card.domain ? 2 : 1
                                                )
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)
                }

                // Start button
                if let domain = selectedDomain {
                    Button {
                        onSelect(domain)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 15))
                            Text("Begin Restoring the Tree")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(Theme.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            Capsule()
                                .fill(Theme.amber)
                                .shadow(color: Theme.amber.opacity(0.3), radius: 8, y: 3)
                        )
                    }
                    .padding(.horizontal, 16)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }
}
