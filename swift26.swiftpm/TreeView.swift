//
//  TreeView.swift
//  The Living Prompt Tree
//
//  Created by Chandramohan on 26/02/26.
//
//  A pure SwiftUI tree with 5 element layers (Air, Water, Sunlight, Soil, Nutrients).
//  Each layer has a broken (dim/damaged) and restored (glowing/animated) state,
//  driven by AppState.completedLevels. No images, no Lottie — only shapes,
//  gradients, glow effects, and opacity/spring animations.
//

import SwiftUI

// MARK: - TreeView

/// The Living Prompt Tree — a layered SwiftUI composition where each of
/// the 5 natural elements transitions from broken to restored as levels are completed.
struct TreeView: View {

    @ObservedObject var appState: AppState

    /// Controls the continuous pulse animation for restored elements.
    @State private var pulsePhase: Bool = false
    /// Controls the shimmer offset for particle-like effects.
    @State private var shimmerOffset: CGFloat = 0

    private var completedLevels: Set<Int> { appState.completedLevels }

    var body: some View {
        ZStack {
            // Layer order (back → front): Sky → Sunlight rays → Canopy → Trunk → Water → Soil → Nutrients → Roots

            // L1 — Air: sky halo around the canopy
            AirLayer(isRestored: completedLevels.contains(1), pulse: pulsePhase)

            // L3 — Sunlight: golden rays from above
            SunlightLayer(isRestored: completedLevels.contains(3), pulse: pulsePhase)

            // L4 — Soil: root base glow
            SoilLayer(isRestored: completedLevels.contains(4), pulse: pulsePhase)

            // L5 — Nutrients: root tendrils
            NutrientsLayer(isRestored: completedLevels.contains(5), pulse: pulsePhase)

            // Tree anatomy (trunk + canopy + branches)
            TreeTrunk()

            // L2 — Water: streams flowing down the trunk
            WaterLayer(isRestored: completedLevels.contains(2), shimmerOffset: shimmerOffset)

            // Canopy on top
            TreeCanopy(allRestored: appState.isAllComplete, pulse: pulsePhase)
        }
        .frame(maxWidth: 380, maxHeight: 520)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulsePhase = true
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.0
            }
        }
    }
}

// MARK: - Tree Anatomy (Trunk + Branches)

/// The central trunk of the tree — always visible, color shifts when all elements are restored.
private struct TreeTrunk: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Main trunk
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: 0.07, saturation: 0.6, brightness: 0.45),
                            Color(hue: 0.07, saturation: 0.5, brightness: 0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 28, height: 160)

            // Trunk base flare
            TrunkBase()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: 0.07, saturation: 0.55, brightness: 0.40),
                            Color(hue: 0.07, saturation: 0.5, brightness: 0.30)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, height: 30)
        }
        .offset(y: 20)
    }
}

/// Custom shape for the trunk base flare / root junction.
private struct TrunkBase: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - 14, y: 0))
        path.addLine(to: CGPoint(x: rect.midX + 14, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX + 30, y: rect.midY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - 14, y: 0),
            control: CGPoint(x: rect.midX - 30, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

/// The leaf canopy — a layered set of ellipses forming the tree crown.
private struct TreeCanopy: View {
    let allRestored: Bool
    let pulse: Bool

    private var canopyColor: Color {
        allRestored
            ? Color(hue: 0.35, saturation: 0.75, brightness: 0.65)
            : Color(hue: 0.35, saturation: 0.45, brightness: 0.40)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Back layer (wider)
                Ellipse()
                    .fill(canopyColor.opacity(0.6))
                    .frame(width: 180, height: 110)
                    .offset(y: 10)

                // Left cluster
                Ellipse()
                    .fill(canopyColor.opacity(0.7))
                    .frame(width: 100, height: 85)
                    .offset(x: -50, y: 5)

                // Right cluster
                Ellipse()
                    .fill(canopyColor.opacity(0.7))
                    .frame(width: 100, height: 85)
                    .offset(x: 50, y: 5)

                // Center top cluster
                Ellipse()
                    .fill(canopyColor)
                    .frame(width: 140, height: 100)
                    .offset(y: -15)

                // Crown highlight
                if allRestored {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 80)
                        .offset(y: -20)
                        .scaleEffect(pulse ? 1.05 : 0.95)
                }
            }

            Spacer()
        }
        .offset(y: 30)
        .animation(.easeInOut(duration: 0.8), value: allRestored)
    }
}

// MARK: - Level 1 — Air Layer

/// Broken: gray haze obscures the canopy. Restored: clear blue radial glow.
private struct AirLayer: View {
    let isRestored: Bool
    let pulse: Bool

    var body: some View {
        VStack {
            ZStack {
                if isRestored {
                    // Clear sky glow
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: 0.55, saturation: 0.4, brightness: 0.95).opacity(0.5),
                                    Color(hue: 0.58, saturation: 0.3, brightness: 0.90).opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 160
                            )
                        )
                        .frame(width: 320, height: 220)
                        .scaleEffect(pulse ? 1.05 : 0.98)
                        .shadow(color: Color.cyan.opacity(0.3), radius: 20)
                } else {
                    // Foggy haze
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.gray.opacity(0.4),
                                    Color.gray.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 200)
                }
            }
            .offset(y: 30)

            Spacer()
        }
        .animation(.easeInOut(duration: 1.2), value: isRestored)
    }
}

// MARK: - Level 2 — Water Layer

/// Broken: dull, no streams. Restored: animated cyan streams flowing down the trunk.
private struct WaterLayer: View {
    let isRestored: Bool
    let shimmerOffset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                if isRestored {
                    // Left stream
                    WaterStream()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.52, saturation: 0.6, brightness: 0.85).opacity(0.0),
                                    Color(hue: 0.52, saturation: 0.7, brightness: 0.90).opacity(0.7),
                                    Color(hue: 0.52, saturation: 0.6, brightness: 0.85).opacity(0.0)
                                ],
                                startPoint: UnitPoint(x: 0.5, y: shimmerOffset - 0.3),
                                endPoint: UnitPoint(x: 0.5, y: shimmerOffset + 0.3)
                            )
                        )
                        .frame(width: 6, height: 140)
                        .offset(x: -8)
                        .shadow(color: Color.cyan.opacity(0.6), radius: 4)

                    // Right stream
                    WaterStream()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.52, saturation: 0.6, brightness: 0.85).opacity(0.0),
                                    Color(hue: 0.55, saturation: 0.7, brightness: 0.90).opacity(0.6),
                                    Color(hue: 0.52, saturation: 0.6, brightness: 0.85).opacity(0.0)
                                ],
                                startPoint: UnitPoint(x: 0.5, y: shimmerOffset - 0.5),
                                endPoint: UnitPoint(x: 0.5, y: shimmerOffset + 0.1)
                            )
                        )
                        .frame(width: 5, height: 140)
                        .offset(x: 8)
                        .shadow(color: Color.cyan.opacity(0.5), radius: 3)
                } else {
                    // Dry marks on trunk
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hue: 0.07, saturation: 0.3, brightness: 0.30).opacity(0.3))
                        .frame(width: 4, height: 120)
                        .offset(x: -7)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hue: 0.07, saturation: 0.3, brightness: 0.30).opacity(0.3))
                        .frame(width: 3, height: 120)
                        .offset(x: 7)
                }
            }
            .offset(y: -30)
        }
        .offset(y: 20)
        .animation(.easeInOut(duration: 1.0), value: isRestored)
    }
}

/// A simple rounded rectangle used for a water stream.
private struct WaterStream: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        path.move(to: CGPoint(x: w * 0.3, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.6, y: rect.height * 0.5),
            control: CGPoint(x: w * 0.8, y: rect.height * 0.25)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.4, y: rect.height),
            control: CGPoint(x: w * 0.2, y: rect.height * 0.75)
        )
        path.addLine(to: CGPoint(x: w * 0.1, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.3, y: rect.height * 0.5),
            control: CGPoint(x: w * 0.0, y: rect.height * 0.75)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.3, y: 0),
            control: CGPoint(x: w * 0.6, y: rect.height * 0.25)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Level 3 — Sunlight Layer

/// Broken: dark, no rays. Restored: golden animated ray beams from above.
private struct SunlightLayer: View {
    let isRestored: Bool
    let pulse: Bool

    var body: some View {
        VStack {
            ZStack {
                if isRestored {
                    // Multiple sun rays
                    ForEach(0..<7, id: \.self) { i in
                        let angle = Angle.degrees(Double(i) * 25 - 75)
                        SunRay()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hue: 0.12, saturation: 0.7, brightness: 1.0).opacity(0.5),
                                        Color(hue: 0.12, saturation: 0.5, brightness: 1.0).opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 16, height: 120)
                            .rotationEffect(angle)
                            .offset(y: -20)
                            .opacity(pulse ? 0.7 : 0.3)
                    }

                    // Central sun glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: 0.12, saturation: 0.6, brightness: 1.0).opacity(0.6),
                                    Color(hue: 0.10, saturation: 0.4, brightness: 1.0).opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 50
                            )
                        )
                        .frame(width: 70, height: 70)
                        .offset(y: -40)
                        .scaleEffect(pulse ? 1.1 : 0.9)
                        .shadow(color: Color.yellow.opacity(0.4), radius: 15)
                } else {
                    // Dark overcast indicator
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: 0.0, saturation: 0.0, brightness: 0.25).opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 60)
                        .offset(y: -30)
                }
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 1.5), value: isRestored)
    }
}

/// A tapered ray shape.
private struct SunRay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - 3, y: 0))
        path.addLine(to: CGPoint(x: rect.midX + 3, y: 0))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.4, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.4, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Level 4 — Soil Layer

/// Broken: dark, cracked ground. Restored: warm brown glow with sparkle particles.
private struct SoilLayer: View {
    let isRestored: Bool
    let pulse: Bool

    var body: some View {
        VStack {
            Spacer()

            ZStack {
                if isRestored {
                    // Rich soil glow
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: 0.08, saturation: 0.7, brightness: 0.55).opacity(0.7),
                                    Color(hue: 0.06, saturation: 0.5, brightness: 0.40).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 120
                            )
                        )
                        .frame(width: 260, height: 80)
                        .shadow(color: Color(hue: 0.08, saturation: 0.6, brightness: 0.6).opacity(0.5), radius: 12)

                    // Sparkle particles
                    ForEach(0..<8, id: \.self) { i in
                        Circle()
                            .fill(Color(hue: 0.12, saturation: 0.5, brightness: 0.95))
                            .frame(width: 4, height: 4)
                            .offset(
                                x: CGFloat.random(in: -90...90),
                                y: CGFloat.random(in: -15...15)
                            )
                            .opacity(pulse ? 0.9 : 0.2)
                            .scaleEffect(pulse ? 1.3 : 0.7)
                    }
                } else {
                    // Cracked dark earth
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: 0.0, saturation: 0.1, brightness: 0.20).opacity(0.6),
                                    Color(hue: 0.0, saturation: 0.05, brightness: 0.15).opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 100
                            )
                        )
                        .frame(width: 240, height: 70)

                    // Crack lines
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hue: 0.0, saturation: 0.0, brightness: 0.12).opacity(0.5))
                            .frame(width: CGFloat.random(in: 30...60), height: 2)
                            .rotationEffect(.degrees(Double(i) * 40 - 60))
                            .offset(x: CGFloat(i) * 15 - 25)
                    }
                }
            }
            .offset(y: -15)
        }
        .animation(.easeInOut(duration: 1.0), value: isRestored)
    }
}

// MARK: - Level 5 — Nutrients Layer

/// Broken: toxic purple tint on roots. Restored: green pulsing nutrient flow.
private struct NutrientsLayer: View {
    let isRestored: Bool
    let pulse: Bool

    var body: some View {
        VStack {
            Spacer()

            ZStack {
                // Root tendrils — 3 on each side
                ForEach(0..<3, id: \.self) { i in
                    NutrientTendril(isRestored: isRestored, pulse: pulse, index: i)
                        .offset(x: CGFloat(i) * 20 - 20, y: CGFloat(i) * 5)

                    NutrientTendril(isRestored: isRestored, pulse: pulse, index: i)
                        .scaleEffect(x: -1, y: 1)
                        .offset(x: CGFloat(i) * -20 + 20, y: CGFloat(i) * 5)
                }

                if isRestored {
                    // Central nutrient glow at root junction
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: 0.35, saturation: 0.7, brightness: 0.80).opacity(0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 3,
                                endRadius: 25
                            )
                        )
                        .frame(width: 40, height: 40)
                        .scaleEffect(pulse ? 1.2 : 0.8)
                        .shadow(color: Color.green.opacity(0.4), radius: 8)
                }
            }
            .offset(y: -35)
        }
        .animation(.easeInOut(duration: 1.0), value: isRestored)
    }
}

/// A single root tendril that changes color based on nutrient state.
private struct NutrientTendril: View {
    let isRestored: Bool
    let pulse: Bool
    let index: Int

    private var tendrilColor: Color {
        isRestored
            ? Color(hue: 0.35, saturation: 0.65, brightness: 0.70)
            : Color(hue: 0.80, saturation: 0.5, brightness: 0.35)  // toxic purple
    }

    private var glowColor: Color {
        isRestored
            ? Color.green.opacity(0.4)
            : Color.purple.opacity(0.2)
    }

    var body: some View {
        RootTendrilShape(curveAmount: CGFloat(index) * 0.15 + 0.2)
            .stroke(
                tendrilColor,
                style: StrokeStyle(lineWidth: 4 - CGFloat(index) * 0.8, lineCap: .round)
            )
            .frame(width: 50, height: 35)
            .shadow(color: glowColor, radius: isRestored ? 6 : 2)
            .opacity(isRestored ? (pulse ? 1.0 : 0.7) : 0.5)
    }
}

/// Custom shape for a curving root tendril.
private struct RootTendrilShape: Shape {
    let curveAmount: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX + rect.width * curveAmount, y: rect.midY)
        )
        return path
    }
}

// MARK: - Preview

#Preview {
    let state = AppState()
    TreeView(appState: state)
        .frame(width: 400, height: 540)
        .background(Color.black)
}
