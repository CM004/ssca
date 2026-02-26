//
//  IntroStageView.swift
//  The Living Prompt Tree
//
//  Stage 0: Clean iOS-native intro with story + starting prompt.
//

import SwiftUI

struct IntroStageView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("SamvaadFlow")
                    .font(.largeTitle.weight(.bold))
                    .padding(.top, 8)

                Text("This tree can talk with AI but glowing tree is flickering becuase the communication is not strong. It lacks the essential elements needed to survive.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Each missing element represents one fundamental rule of writing prompts that AI can actually use well to understand and respond to.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Your job: restore the glowing tree — one element at a time.")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.orange)

                Divider()

                // Starting prompt
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Starting Prompt")
                        .font(.headline)

                    Text(Curriculum.startingPrompt)
                        .font(.body.monospaced())
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))

                    HStack {
                        Label("\(Curriculum.startingTokens) tokens", systemImage: "number")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)

                        Spacer()

                    
                    }
                }

                Text("This prompt will travel through all 5 stages. Each stage will fix one broken element.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .italic()

                Button {
                    withAnimation { appState.currentStage = 1 }
                } label: {
                    Text("Begin Stage 1 : Air")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
            }
            .padding(24)
        }
        .navigationTitle("Introduction")
    }
}
