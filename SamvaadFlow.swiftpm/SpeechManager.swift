//
//  SpeechManager.swift
//  The Living Prompt Tree
//
//  Reusable text-to-speech manager using AVSpeechSynthesizer.
//  Usage: Add @StateObject var speech = SpeechManager() then call
//  speech.speak("text") and use speech.speakerButton("text") for a toolbar icon.
//

import SwiftUI
import AVFoundation

@MainActor
final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speak the given text, or stop if already speaking.
    func toggleSpeech(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.05
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Stop speaking immediately.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}

// MARK: - Reusable Speaker Button View

struct SpeakerButton: View {
    @ObservedObject var speech: SpeechManager
    let text: String

    var body: some View {
        Button {
            speech.toggleSpeech(text)
        } label: {
            Image(systemName: speech.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.title3)
                .foregroundStyle(speech.isSpeaking ? .green : .secondary)
                .symbolEffect(.variableColor, isActive: speech.isSpeaking)
        }
    }
}
