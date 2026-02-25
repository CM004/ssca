//
//  IntroView.swift
//  The Living Prompt Tree
//
//  Created by Chandramohan on 26/02/26.
//
//  Narrative onboarding screen introducing the tree, Julie's story,
//  and the concept of prompt engineering. Uses typewriter text animation
//  and a dim tree silhouette on a dark background.
//

import SwiftUI

// MARK: - IntroView

/// The opening narrative that introduces the player to the Living Prompt Tree.
/// Tells Julie's story of a vague prompt and invites the user to restore the tree
/// by learning 5 principles of effective AI prompting.
struct IntroView: View {

    @ObservedObject var appState: AppState

    /// Callback triggered when the user taps "Begin Restoring".
    var onBegin: () -> Void

    // Animation state
    @State private var currentParagraph: Int = 0
    @State private var displayedText: String = ""
    @State private var isTyping: Bool = false
    @State private var showButton: Bool = false
    @State private var treeGlow: Bool = false
    @State private var titleOpacity: Double = 0

    private let narrativeParagraphs: [String] = [
        "Julie typed her first prompt into the AI:\n\"Tell me about climate change.\"\nThe response was a wall of vague, unfocused text. She felt lost.",
        "Deep in the digital forest, a once-radiant tree began to wither.\nIts Air turned hazy. Its Water dried up.\nIts Sunlight faded. Its Soil cracked. Its Nutrients turned toxic.",
        "The tree's life is tied to the clarity of human prompts.\nEvery vague question drains its energy.\nEvery well-crafted prompt restores an element.",
        "Five elements. Five principles.\nClarity · Structure · Efficiency · Context · Safety\n\nYour words have the power to bring this tree back to life."
    ]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hue: 0.72, saturation: 0.3, brightness: 0.08),
                    Color(hue: 0.58, saturation: 0.2, brightness: 0.12),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Dim tree silhouette in the background
            VStack {
                Spacer()
                TreeSilhouette(glowing: treeGlow)
                    .frame(width: 240, height: 300)
                    .opacity(0.25)
                    .offset(y: 30)
            }
            .ignoresSafeArea(edges: .bottom)

            // Content
            VStack(spacing: 28) {
                Spacer()
                    .frame(height: 40)

                // Title
                VStack(spacing: 8) {
                    Text("🌳")
                        .font(.system(size: 52))

                    Text("The Living Prompt Tree")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.35, saturation: 0.5, brightness: 0.85),
                                    Color(hue: 0.45, saturation: 0.4, brightness: 0.95)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("An AI Literacy Experience")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)
                }
                .opacity(titleOpacity)

                Spacer()
                    .frame(height: 10)

                // Typewriter narrative text
                VStack(spacing: 16) {
                    Text(displayedText)
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .frame(maxWidth: 320)
                        .fixedSize(horizontal: false, vertical: true)

                    // Typing indicator
                    if isTyping {
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 5, height: 5)
                                    .offset(y: isTyping ? -3 : 3)
                                    .animation(
                                        .easeInOut(duration: 0.4)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.15),
                                        value: isTyping
                                    )
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(minHeight: 160)

                Spacer()

                // Navigation controls
                VStack(spacing: 16) {
                    if currentParagraph < narrativeParagraphs.count - 1 && !isTyping {
                        // "Continue" to advance narrative
                        Button {
                            advanceNarrative()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if showButton {
                        // "Begin Restoring" CTA
                        Button {
                            onBegin()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 16))
                                Text("Begin Restoring")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hue: 0.35, saturation: 0.6, brightness: 0.85),
                                                Color(hue: 0.30, saturation: 0.5, brightness: 0.95)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.green.opacity(0.4), radius: 12, y: 4)
                            )
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .scaleEffect(treeGlow ? 1.02 : 0.98)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: treeGlow
                        )
                    }

                    // Skip option
                    if !showButton {
                        Button {
                            skipIntro()
                        } label: {
                            Text("Skip Intro")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            startIntro()
        }
    }

    // MARK: - Animation Logic

    private func startIntro() {
        withAnimation(.easeIn(duration: 1.5)) {
            titleOpacity = 1.0
        }

        // Start first paragraph after title fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            typeCurrentParagraph()
        }
    }

    private func advanceNarrative() {
        currentParagraph += 1
        displayedText = ""
        typeCurrentParagraph()
    }

    private func typeCurrentParagraph() {
        guard currentParagraph < narrativeParagraphs.count else {
            showBeginButton()
            return
        }

        let fullText = narrativeParagraphs[currentParagraph]
        isTyping = true
        displayedText = ""

        var charIndex = 0
        let characters = Array(fullText)

        func typeNext() {
            guard charIndex < characters.count else {
                isTyping = false
                // If this is the last paragraph, show the CTA
                if currentParagraph >= narrativeParagraphs.count - 1 {
                    showBeginButton()
                }
                return
            }

            displayedText.append(characters[charIndex])
            charIndex += 1

            // Variable speed: pause longer on newlines and periods
            let char = characters[charIndex - 1]
            let delay: Double
            switch char {
            case "\n": delay = 0.15
            case ".", "!", "?": delay = 0.10
            case ",", ":": delay = 0.06
            default: delay = 0.025
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                typeNext()
            }
        }

        typeNext()
    }

    private func showBeginButton() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showButton = true
        }
        withAnimation(.easeInOut(duration: 1.5)) {
            treeGlow = true
        }
    }

    private func skipIntro() {
        currentParagraph = narrativeParagraphs.count - 1
        displayedText = narrativeParagraphs.last ?? ""
        isTyping = false
        showBeginButton()
    }
}

// MARK: - Tree Silhouette

/// A dim, simplified tree silhouette used as the IntroView background.
private struct TreeSilhouette: View {
    let glowing: Bool

    var body: some View {
        ZStack {
            // Trunk
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.08))
                .frame(width: 20, height: 140)
                .offset(y: 40)

            // Canopy
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            (glowing
                                ? Color(hue: 0.35, saturation: 0.4, brightness: 0.4)
                                : Color.white
                            ).opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 180, height: 130)
                .offset(y: -40)
                .shadow(
                    color: glowing ? Color.green.opacity(0.15) : Color.clear,
                    radius: 20
                )

            // Root base
            Ellipse()
                .fill(Color.white.opacity(0.06))
                .frame(width: 140, height: 40)
                .offset(y: 115)
        }
        .animation(.easeInOut(duration: 2.0), value: glowing)
    }
}

// MARK: - Preview

#Preview("Intro View") {
    IntroView(appState: AppState(), onBegin: { })
}
