//
//  DashboardView.swift
//  The Living Prompt Tree
//
//  Dashboard: token journey, cost comparison, metrics — Clean iOS native.
//

import SwiftUI
import Charts

struct DashboardView: View {

    @EnvironmentObject var appState: AppState

    private var tokenJourney: [(stage: String, tokens: Int)] {
        let labels = ["Start", "Air", "Water", "Sunlight", "Soil", "Nutrients"]
        return zip(labels, appState.tokenHistory).map { ($0, $1) }
    }

    private var badPromptLine: [(stage: String, tokens: Int)] {
        let labels = ["Start", "Air", "Water", "Sunlight", "Soil", "Nutrients"]
        return labels.map { ($0, Curriculum.startingTokens) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("Your Prompt's Impact")
                    .font(.largeTitle.weight(.bold))

                Divider()

                // Token Journey Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Token Journey")
                        .font(.headline)

                    Chart {
                        ForEach(badPromptLine, id: \.stage) { point in
                            LineMark(
                                x: .value("Stage", point.stage),
                                y: .value("Tokens", point.tokens),
                                series: .value("Line", "Bad Prompt")
                            )
                            .foregroundStyle(.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        }

                        ForEach(tokenJourney, id: \.stage) { point in
                            LineMark(
                                x: .value("Stage", point.stage),
                                y: .value("Tokens", point.tokens),
                                series: .value("Line", "Your Prompt")
                            )
                            .foregroundStyle(.green)

                            PointMark(
                                x: .value("Stage", point.stage),
                                y: .value("Tokens", point.tokens)
                            )
                            .foregroundStyle(.green)
                            .annotation(position: .top) {
                                Text("\(point.tokens)")
                                    .font(.caption2.weight(.bold).monospaced())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .frame(height: 180)

                    HStack(spacing: 16) {
                        Label("Bad Prompt", systemImage: "minus")
                            .font(.caption2).foregroundStyle(.red)
                        Label("Your Prompt", systemImage: "circle.fill")
                            .font(.caption2).foregroundStyle(.green)
                    }

                    Text("Stage 3 is your efficiency peak — every word earns its place.")
                        .font(.caption).foregroundStyle(.secondary).italic()
                }
                .padding(16)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))

                // Conversation Cost Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Conversation Cost")
                        .font(.headline)

                    Chart {
                        BarMark(x: .value("Type", "Bad Prompt\n(4 exchanges)"), y: .value("Tokens", Curriculum.badPromptTokenCost))
                            .foregroundStyle(.red.opacity(0.6))
                            .annotation(position: .top) {
                                Text("~\(Curriculum.badPromptTokenCost)")
                                    .font(.caption2.weight(.bold).monospaced())
                                    .foregroundStyle(.red)
                            }

                        BarMark(x: .value("Type", "Your Prompt\n(1 exchange)"), y: .value("Tokens", Curriculum.goodPromptTokenCost))
                            .foregroundStyle(.green)
                            .annotation(position: .top) {
                                Text("~\(Curriculum.goodPromptTokenCost)")
                                    .font(.caption2.weight(.bold).monospaced())
                                    .foregroundStyle(.green)
                            }
                    }
                    .frame(height: 140)

                    Text("A vague prompt looks cheap. A full conversation isn't.")
                        .font(.caption).foregroundStyle(.secondary).italic()
                }
                .padding(16)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))

                // Metrics
                HStack(spacing: 12) {
                    MetricCard(icon: "number.circle", value: "55%", label: "Fewer tokens")
                    MetricCard(icon: "bolt.circle", value: "~8%", label: "Faster answers")
                    MetricCard(icon: "target", value: "~40%", label: "More accurate")
                }

                // Banner
                VStack(spacing: 6) {
                    Text("You didn't just write a better prompt.")
                        .font(.headline)
                    Text("You used AI more sustainably. 🌳")
                        .font(.headline)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))

                // CTAs
                HStack(spacing: 12) {
                    Button {
                        appState.reset()
                    } label: {
                        Text("Try Another Domain")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button { } label: {
                        Label("Share My Tree", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                }
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
    }
}

private struct MetricCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
            Text(value)
                .font(.headline.monospaced())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }
}
