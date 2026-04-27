import AVFoundation
import QuickTranslateCore

@MainActor
final class SpeechService {
  private let synthesizer = AVSpeechSynthesizer()

  func speak(_ request: SpeechUtteranceRequest) {
    let text = request.normalizedText
    guard !text.isEmpty else {
      return
    }

    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }

    let utterance = AVSpeechUtterance(string: text)
    if let languageCode = request.voiceLanguageCode,
       let voice = AVSpeechSynthesisVoice(language: languageCode) {
      utterance.voice = voice
    }
    synthesizer.speak(utterance)
  }
}
