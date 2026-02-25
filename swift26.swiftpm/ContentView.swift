import SwiftUI

struct ContentView: View {
    @State private var userPrompt: String = ""
    @State private var feedback: String = ""
    @State private var energyLevel: Double = 0.2
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("🌳 The Living Prompt Tree")
                .font(.largeTitle)
                .bold()
            
            TreeView(energyLevel: energyLevel)
                .frame(height: 250)
            
            TextEditor(text: $userPrompt)
                .frame(height: 120)
                .border(Color.gray)
                .padding()
            
            Button("Restore Energy") {
                Task {
                    let result = await AIEngine.evaluate(prompt: userPrompt)
                    feedback = result.feedback
                    energyLevel = result.score
                }
            }
            .buttonStyle(.borderedProminent)
            
            Text(feedback)
                .padding()
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
