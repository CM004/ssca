# 🌳 SamvaadFlow

**A Swift Student Challenge app that teaches AI prompt engineering through a living tree metaphor.**

> *Samvaad (संवाद) — Hindi for "dialogue." Because good AI starts with a good conversation.*

---

## What It Is

SamvaadFlow is an interactive, gamified iOS/iPadOS playground where users evolve a single weak prompt into a powerful, safe, and efficient one — across **5 stages**, each mapped to a natural element.

| Stage | Element | Principle | What You Learn |
|-------|---------|-----------|----------------|
| 1 | 🌬️ Air | **Clarity** | Role-based & task-based prompting |
| 2 | 💧 Water | **Structure** | Role → Task → Audience → Constraint → Format |
| 3 | ☀️ Sunlight | **Efficiency** | Keyword extraction & symbol compression |
| 4 | 🌍 Soil | **Context** | Few-shot examples & chain-of-thought anchoring |
| 5 | 🛡️ Nutrients | **Safety & Privacy** | PII removal & constraint-based prompting |

---

## Demo Link

https://www.loom.com/share/6fb10fbe00984f16a190c2d16c5a6aa7

---


## Architecture

```
SamvaadFlow.swiftpm
├── ContentView.swift          # 3-column NavigationSplitView layout
├── AppState.swift             # Central @ObservableObject — stage, prompt, scores
├── LevelConfig.swift          # Full curriculum: 5 domains × 5 stages
├── Stage1_AirView.swift       # Drag-and-drop block builder
├── Stage2_WaterView.swift     # Reorder items into correct structure
├── Stage3_SunlightView.swift  # Word-tap removal + compression feedback
├── Stage4_SoilView.swift      # Context & few-shot example editor
├── Stage5_NutrientsView.swift # PII redaction + constraint toggle
├── DashboardView.swift        # Final prompt comparison + token savings
├── PromptRainView.swift       # SpriteKit mini-game (prompt rain)
├── PracticeView.swift         # Free-form practice with evaluation
├── FoundationModelEvaluator.swift  # On-device Apple Intelligence evaluation
├── HeuristicEvaluator.swift        # Rule-based evaluator — regex + keyword checks for all 5 stages
├── TreeScene.swift            # SpriteKit growing tree (visual progress)
└── StoreManager.swift         # StoreKit 2 paywall (Education domain free)
```

---

## Key Features

- **One prompt, five transformations** — the same prompt is progressively refined through every stage
- **5 domains** — Education (free), Healthcare, Legal, Finance, Support (unlockable)
- **Per-stage inline evaluation** — each stage has its own rule-based checks that score the user's work on the spot
- **Living tree visualisation** — SpriteKit tree grows and animates as you complete each stage
- **Token efficiency tracking** — shows how a bad prompt costs 303 tokens vs. 136 for the optimised one
- **Prompt Rain** — a SpriteKit arcade game to reinforce learning
- **Paywall via StoreKit 2** — premium domains gated behind in-app purchase

---

## Requirements

| Requirement | Version |
|-------------|---------|
| Platform | iOS / iPadOS **26.0+** |
| Swift | **6.0** |
| Xcode | **Swift Playgrounds 4 / Xcode 26** |
| Apple Intelligence | Optional |

---

## Running It

Open `SamvaadFlow.swiftpm` in **Swift Playgrounds** or **Xcode** and hit Run.  
No external dependencies. No server. Everything runs on-device.

---

## Built For

**Apple Swift Student Challenge 2026**  
*Category: Education / AI Literacy*

---

*Made with 🍃 by Chandramohan*
