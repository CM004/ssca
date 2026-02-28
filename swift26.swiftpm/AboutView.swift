//
//  AboutView.swift
//  The Living Prompt Tree
//
//  About this app — mission, experience, technology, and impact.
//

import SwiftUI

struct AboutView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                heroSection
                Divider()
                problemSection
                Divider()
                experienceSection
                Divider()
                technologySection
                Divider()
                impactSection
                Divider()
                ethicsSection
                Divider()
                creatorSection
            }
            .padding(28)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("About SamvaadFlow")
    }

    // MARK: - Section 1 — Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            Text("🌳")
                .font(.system(size: 60))

            Text("SamvaadFlow")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.green)

            Text("Most people are taught what to ask AI.\nNobody teaches them how.")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Section 2 — Why This Exists

    private var problemSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("🌫️", "Why This Exists")

            Text("""
            Every message you send to AI is broken into tokens. Every token costs compute. Every compute cycle costs energy.

            Research shows that bloated prompts can be reduced by 40–60% without losing meaning — producing faster, more accurate responses at a fraction of the cost.

            Most people have never been taught this. SamvaadFlow changes that.
            """)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Section 3 — How It Works

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("🌱", "How It Works")

            Text("""
            You restores a glowing tree — flickering because prompts are vague, unstructured, and unsafe. So is the communication between you and AI. The tree is a metaphor for your prompt: when your prompts are clear, structured, efficient, grounded, and safe — the tree glows.
            """)
            .font(.callout)
            .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                stageCard("🌬️", "AIR — Clarity", "Add role + task")
                Divider()
                stageCard("💧", "WATER — Structure", "Order your prompt")
                Divider()
                stageCard("☀️", "SUNLIGHT — Efficiency", "Compress tokens")
                Divider()
                stageCard("🌍", "SOIL — Context", "Ground with context or examples")
                Divider()
                stageCard("🛡️", "NUTRIENTS — Safety", "Remove personal data")
            }
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))

            Text("Five domains. Five elements. Five trees to restore.")
                .font(.subheadline.weight(.bold))
                .padding(.top, 6)

            Text("Education · Healthcare · Legal · Finance · Customer Service")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Section 4 — Technology

    private var technologySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("🧠", "Powered By Apple Intelligence")

            Text("""
            Every stage is evaluated by Apple's on-device Foundation Model (iOS 26) — running entirely offline. No data leaves your device. If Apple Intelligence is unavailable, a built-in heuristic engine keeps every interaction fully functional.
            """)
            .font(.callout)
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill").foregroundStyle(.green)
                Text("No accounts. No tracking. No cloud.")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Section 5 — What You Take Away

    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("🎯", "What You Take Away")

            VStack(alignment: .leading, spacing: 4) {
                bulletPoint("Write prompts that are clear, structured, and efficient")
                bulletPoint("Protect personal data before it reaches any AI system")
                bulletPoint("See how language affects energy, cost, and accuracy")
                bulletPoint("Track real impact — tokens saved, energy reduced, privacy protected")
                bulletPoint("Know about the tradeoff between tokens and accuracy")
            }
        }
    }

    // MARK: - Section 6 — The Name

    private var ethicsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("🪷", "The Name")

            Text("""
            SamvaadFlow — संवाद (Samvaad) is the Hindi word for meaningful dialogue. Flow is the state your prompts reach when every word earns its place. Together: the art of speaking to AI with purpose.
            """)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Section 7 — Footer

    private var creatorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Built with SwiftUI · SpriteKit · Apple Foundation Models")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(.green)
                Text("Fully offline. No accounts. No tracking.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))

            VStack(spacing: 6) {
                Text("Small Steps, Big Impacts.")
                    .font(.callout.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.green.opacity(0.2), lineWidth: 1))
        }
    }

    // MARK: - Reusable Components

    private func sectionHeader(_ emoji: String, _ title: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji).font(.title2)
            Text(title).font(.title3.weight(.bold))
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").font(.caption).foregroundStyle(.green)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func statRow(_ arrow: String, _ label: String, _ value: String) -> some View {
        HStack {
            Text(arrow).font(.caption.weight(.bold)).foregroundStyle(.green)
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.weight(.bold).monospaced()).foregroundStyle(.primary)
        }
    }

    private func stageCard(_ emoji: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.bold))
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(10)
    }

    private func domainRow(_ emoji: String, _ domain: String, _ desc: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
            Text(domain).font(.caption.weight(.bold)).frame(width: 90, alignment: .leading)
            Text("— \(desc)").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func impactRow(_ emoji: String, _ label: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func ethicCard(_ emoji: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.bold))
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func flowStep(_ text: String) -> some View {
        Text(text)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 4))
    }

    private func flowArrow() -> some View {
        Text("↓").font(.caption).foregroundStyle(.green).padding(.leading, 20)
    }

    private func referenceRow(_ title: String, _ source: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text").font(.caption2).foregroundStyle(.green)
            Text(title).font(.caption2).foregroundStyle(.primary)
            Text("— \(source)").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var citationStrip: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sources").font(.caption2.weight(.bold)).foregroundStyle(.green)
            referenceRow("Prompt Compression in LLMs", "Sahin Ahmed")
            referenceRow("How to Compress Prompts & Reduce LLM Costs", "freeCodeCamp")
            referenceRow("The Science of Prompt Compression", "Pranav Prakash")
            referenceRow("Prompt Compression: Past, Present, Profit", "Kanis Patel")
        }
        .padding(10)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
    }
}

