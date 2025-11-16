import AVFoundation
import SwiftUI
import Combine
#if canImport(MediaPlayer)
import MediaPlayer
#endif

// MARK: - Supported Languages

enum VoiceLanguage: String, CaseIterable, Identifiable {
    case englishUS = "en-US"
    case englishGB = "en-GB"
    case spanishSpain = "es-ES"
    case spanishArgentina = "es-AR"
    case finnish = "fi-FI"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .englishUS: return "English (US)"
        case .englishGB: return "English (GB)"
        case .spanishSpain: return "Spanish (Spain)"
        case .spanishArgentina: return "Spanish (Argentina)"
        case .finnish: return "Finnish"
        }
    }
}

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()

    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var currentText = ""
    @Published var speechRate: Float = 0.3 // Default speed (range: 0.0 - 1.0)
    @Published var selectedLanguage: VoiceLanguage = .englishUS // Default to English (US)
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published var selectedVoice: AVSpeechSynthesisVoice?

    private let voiceIdentifierKey = "SelectedVoiceIdentifier"

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        setupRemoteCommandCenter()
        loadSavedVoice()
        updateAvailableVoices()
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        #endif
        // macOS doesn't require audio session configuration
    }

    // MARK: - Remote Command Center (Lock Screen Controls)

    private func setupRemoteCommandCenter() {
        #if os(iOS)
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPaused {
                self.resume()
                return .success
            }
            return .commandFailed
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isSpeaking && !self.isPaused {
                self.pause()
                return .success
            }
            return .commandFailed
        }

        // Stop command
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.stop()
            return .success
        }
        #endif
        // macOS doesn't have MPRemoteCommandCenter
    }

    // MARK: - Voice Management

    private func updateAvailableVoices() {
        // Get all voices for the selected language
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        // Filter by exact language code (e.g., "en-US", "es-ES") to avoid duplicates from different dialects
        var languageVoices = allVoices.filter { $0.language == selectedLanguage.rawValue }

        // Sort voices by priority
        if selectedLanguage == .englishUS {
            let preferredOrder = ["Samantha", "Ava", "Nicky", "Alex", "Tom"]
            languageVoices.sort { voice1, voice2 in
                let index1 = preferredOrder.firstIndex(of: voice1.name) ?? Int.max
                let index2 = preferredOrder.firstIndex(of: voice2.name) ?? Int.max
                if index1 != index2 {
                    return index1 < index2
                }
                return voice1.name < voice2.name
            }
        } else if selectedLanguage == .englishGB {
            let preferredOrder = ["Daniel", "Kate", "Serena", "Arthur"]
            languageVoices.sort { voice1, voice2 in
                let index1 = preferredOrder.firstIndex(of: voice1.name) ?? Int.max
                let index2 = preferredOrder.firstIndex(of: voice2.name) ?? Int.max
                if index1 != index2 {
                    return index1 < index2
                }
                return voice1.name < voice2.name
            }
        } else if selectedLanguage == .spanishSpain {
            let preferredOrder = ["Mónica", "Jorge"]
            languageVoices.sort { voice1, voice2 in
                let index1 = preferredOrder.firstIndex(of: voice1.name) ?? Int.max
                let index2 = preferredOrder.firstIndex(of: voice2.name) ?? Int.max
                if index1 != index2 {
                    return index1 < index2
                }
                return voice1.name < voice2.name
            }
        } else if selectedLanguage == .spanishArgentina {
            let preferredOrder = ["Isabella"]
            languageVoices.sort { voice1, voice2 in
                let index1 = preferredOrder.firstIndex(of: voice1.name) ?? Int.max
                let index2 = preferredOrder.firstIndex(of: voice2.name) ?? Int.max
                if index1 != index2 {
                    return index1 < index2
                }
                return voice1.name < voice2.name
            }
        } else if selectedLanguage == .finnish {
            let preferredOrder = ["Satu"]
            languageVoices.sort { voice1, voice2 in
                let index1 = preferredOrder.firstIndex(of: voice1.name) ?? Int.max
                let index2 = preferredOrder.firstIndex(of: voice2.name) ?? Int.max
                if index1 != index2 {
                    return index1 < index2
                }
                return voice1.name < voice2.name
            }
        }

        availableVoices = languageVoices

        // If no saved voice or saved voice not available, select preferred default
        if selectedVoice == nil || !availableVoices.contains(where: { $0.identifier == selectedVoice?.identifier }) {
            if selectedLanguage == .englishUS {
                // Try to select Samantha for English (US), otherwise first available
                selectedVoice = availableVoices.first(where: { $0.name == "Samantha" }) ?? availableVoices.first
            } else if selectedLanguage == .englishGB {
                // Try to select Daniel for English (GB), otherwise first available
                selectedVoice = availableVoices.first(where: { $0.name == "Daniel" }) ?? availableVoices.first
            } else if selectedLanguage == .spanishSpain {
                // Try to select Mónica for Spanish Spain, otherwise first available
                selectedVoice = availableVoices.first(where: { $0.name == "Mónica" }) ?? availableVoices.first
            } else if selectedLanguage == .spanishArgentina {
                // Try to select Isabella for Spanish Argentina, otherwise first available
                selectedVoice = availableVoices.first(where: { $0.name == "Isabella" }) ?? availableVoices.first
            } else if selectedLanguage == .finnish {
                // Try to select Satu for Finnish, otherwise first available
                selectedVoice = availableVoices.first(where: { $0.name == "Satu" }) ?? availableVoices.first
            } else {
                selectedVoice = availableVoices.first
            }
        }
    }

    func selectVoice(_ voice: AVSpeechSynthesisVoice) {
        selectedVoice = voice
        saveVoicePreference()

        // If currently speaking, restart with new voice
        if isSpeaking && !isPaused {
            let textToResume = currentText
            let wasPaused = isPaused
            synthesizer.stopSpeaking(at: .immediate)

            let utterance = AVSpeechUtterance(string: textToResume)
            utterance.voice = voice
            utterance.rate = speechRate
            synthesizer.speak(utterance)

            if wasPaused {
                synthesizer.pauseSpeaking(at: .immediate)
            }
        }
    }

    private func loadSavedVoice() {
        if let savedIdentifier = UserDefaults.standard.string(forKey: voiceIdentifierKey),
           let voice = AVSpeechSynthesisVoice(identifier: savedIdentifier) {
            selectedVoice = voice
        }
    }

    private func saveVoicePreference() {
        if let voice = selectedVoice {
            UserDefaults.standard.set(voice.identifier, forKey: voiceIdentifierKey)
        }
    }

    // MARK: - Now Playing Info

    private func updateNowPlayingInfo() {
        #if os(iOS)
        var nowPlayingInfo = [String: Any]()

        // Title: First 50 characters of text
        let title = String(currentText.prefix(50)) + (currentText.count > 50 ? "..." : "")
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Text to Voice"

        // Playback rate
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPaused ? 0.0 : 1.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        #endif
        // macOS doesn't have MPNowPlayingInfoCenter
    }

    private func clearNowPlayingInfo() {
        #if os(iOS)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        #endif
        // macOS doesn't have MPNowPlayingInfoCenter
    }

    // MARK: - Playback Controls

    func speak(text: String) {
        // Stop any previous playback
        stop()

        guard !text.isEmpty else { return }

        currentText = text
        let utterance = AVSpeechUtterance(string: text)

        // Use selected voice if available, otherwise fallback to language default
        if let voice = selectedVoice {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: selectedLanguage.rawValue)
        }

        utterance.rate = speechRate

        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false

        // Update lock screen info
        updateNowPlayingInfo()
    }

    func pause() {
        guard isSpeaking && !isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
        updateNowPlayingInfo()
    }

    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPaused = false
        updateNowPlayingInfo()
    }

    func stop() {
        guard isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        clearNowPlayingInfo()
    }

    func updateSpeed(_ newRate: Float) {
        speechRate = newRate
        // If speaking, restart with new speed
        if isSpeaking {
            let textToResume = currentText
            stop()
            speak(text: textToResume)
        }
    }

    func changeLanguage(_ newLanguage: VoiceLanguage) {
        let wasPlaying = isSpeaking && !isPaused
        let textToResume = currentText

        selectedLanguage = newLanguage
        updateAvailableVoices()

        // If speaking, restart with new language and voice
        if wasPlaying {
            stop()
            speak(text: textToResume)
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        clearNowPlayingInfo()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        clearNowPlayingInfo()
    }
}
