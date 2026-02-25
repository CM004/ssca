import SwiftUI

/// Root content view using NavigationStack with programmatic navigation
/// driven by `appState.currentLevel`. Flow:
/// IntroView → DomainSelection → Level 1…5 → PromptJourneySummary
struct ContentView: View {

    @StateObject private var appState = AppState()
    @State private var showIntro: Bool = true
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            // Root: either Intro or TreeHub
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                if showIntro && appState.completedLevels.isEmpty {
                    IntroView(appState: appState) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showIntro = false
                        }
                        // Navigate to domain selection
                        navigationPath.append(NavDestination.domainSelection)
                    }
                    .transition(.opacity)
                } else {
                    TreeHubView(
                        onStartLevel: { navigateToCurrentLevel() },
                        onTapLevel: { levelId in navigateToLevel(levelId) }
                    )
                    .transition(.opacity)
                }
            }
            .navigationDestination(for: NavDestination.self) { destination in
                switch destination {
                case .domainSelection:
                    DomainSelectionView { _ in
                        navigationPath.removeLast()
                        navigateToCurrentLevel()
                    }
                    .navigationBarBackButtonHidden()
                    .environmentObject(appState)

                case .level(let id):
                    levelView(for: id)
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    navigationPath = NavigationPath()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text("Tree")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(Theme.cream.opacity(0.7))
                                }
                            }
                        }
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .environmentObject(appState)

                case .summary:
                    PromptJourneySummaryView()
                        .navigationBarBackButtonHidden()
                        .environmentObject(appState)
                }
            }
        }
        .environmentObject(appState)
        .onAppear {
            if !appState.completedLevels.isEmpty {
                showIntro = false
            }
        }
    }

    // MARK: - Navigation Helpers

    private func navigateToCurrentLevel() {
        if appState.isAllComplete {
            navigationPath.append(NavDestination.summary)
        } else {
            navigationPath.append(NavDestination.level(appState.currentLevel))
        }
    }

    private func navigateToLevel(_ id: Int) {
        navigationPath.append(NavDestination.level(id))
    }

    @ViewBuilder
    private func levelView(for id: Int) -> some View {
        let onComplete = {
            navigationPath = NavigationPath()
            if appState.isAllComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navigationPath.append(NavDestination.summary)
                }
            }
        }

        switch id {
        case 1: Level1_AirView(onComplete: onComplete)
        case 2: Level2_WaterView(onComplete: onComplete)
        case 3: Level3_SunlightView(onComplete: onComplete)
        case 4: Level4_SoilView(onComplete: onComplete)
        case 5: Level5_NutrientsView(onComplete: onComplete)
        default: Text("Unknown Level").foregroundColor(.white)
        }
    }
}

// MARK: - Navigation Destination

enum NavDestination: Hashable {
    case domainSelection
    case level(Int)
    case summary
}

// MARK: - Tree Hub View

/// Main hub showing the tree and level navigation.
struct TreeHubView: View {
    @EnvironmentObject var appState: AppState
    var onStartLevel: () -> Void
    var onTapLevel: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The Living Prompt Tree")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(Theme.cream)

                    Text("Level \(appState.currentLevel) of 5")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.cream.opacity(0.5))
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Theme.cream.opacity(0.1), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: appState.overallProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.safeGreen, Theme.amber],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(appState.overallProgress * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.cream.opacity(0.7))
                }
                .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // The tree
            TreeView(appState: appState)
                .frame(maxWidth: 380, maxHeight: 340)
                .onTapGesture { onStartLevel() }

            Spacer()

            // Start button
            Button(action: onStartLevel) {
                HStack(spacing: 8) {
                    Image(systemName: appState.isAllComplete ? "checkmark.seal.fill" : "play.fill")
                        .font(.system(size: 14))
                    Text(appState.isAllComplete
                         ? "View Journey Summary"
                         : "Start Level \(appState.currentLevel): \(LevelDataStore.level(for: appState.currentLevel)?.elementName ?? "")")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(Theme.charcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Theme.amber)
                        .shadow(color: Theme.amber.opacity(0.3), radius: 8, y: 3)
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Level indicator bar
            LevelIndicatorBar(onTap: onTapLevel)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }
}

// MARK: - Level Indicator Bar

struct LevelIndicatorBar: View {
    @EnvironmentObject var appState: AppState
    var onTap: (Int) -> Void

    private let elements: [(id: Int, icon: String, name: String, color: Color)] = [
        (1, "wind",         "Air",       Color(hue: 0.55, saturation: 0.4, brightness: 0.9)),
        (2, "drop.fill",    "Water",     Color(hue: 0.52, saturation: 0.6, brightness: 0.9)),
        (3, "sun.max.fill", "Sunlight",  Color(hue: 0.12, saturation: 0.6, brightness: 1.0)),
        (4, "leaf.fill",    "Soil",      Color(hue: 0.08, saturation: 0.6, brightness: 0.7)),
        (5, "shield.fill",  "Nutrients", Color(hue: 0.35, saturation: 0.6, brightness: 0.8))
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(elements, id: \.id) { element in
                let isComplete = appState.completedLevels.contains(element.id)
                let isCurrent = appState.currentLevel == element.id
                let isAccessible = isComplete || isCurrent

                Button {
                    if isAccessible { onTap(element.id) }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(isComplete ? element.color.opacity(0.2) : Color.white.opacity(0.05))
                                .frame(width: 42, height: 42)

                            Image(systemName: element.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(
                                    isComplete ? element.color : .white.opacity(isCurrent ? 0.6 : 0.2)
                                )

                            if isComplete {
                                Circle()
                                    .stroke(element.color.opacity(0.4), lineWidth: 2)
                                    .frame(width: 42, height: 42)
                            }
                            if isCurrent && !isComplete {
                                Circle()
                                    .stroke(Theme.amber.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: 42, height: 42)
                            }
                        }

                        Text(element.name)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(
                                isComplete ? element.color.opacity(0.8) : .white.opacity(isCurrent ? 0.5 : 0.2)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!isAccessible)
            }
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
