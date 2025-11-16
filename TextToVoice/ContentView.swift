//
//  ContentView.swift
//  TextToVoice
//
//  Created by Nelson Cabrera on 14.11.2025.
//

import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var historyManager = HistoryManager()

    var body: some View {
        TabView {
            // Main tab: Reader
            ReaderView(speechManager: speechManager, historyManager: historyManager)
                .tabItem {
                    Label("Reader", systemImage: "book.fill")
                }

            // History tab
            HistoryView(speechManager: speechManager, historyManager: historyManager)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
    }
}

// MARK: - Main Reader View

enum InputMode: String, CaseIterable {
    case web = "From Web"
    case text = "From Text"
}

struct ReaderView: View {
    @ObservedObject var speechManager: SpeechManager
    @ObservedObject var historyManager: HistoryManager

    @State private var inputMode: InputMode = .web
    @State private var urlInput = ""
    @State private var textInput = ""
    @State private var isLoadingWeb = false
    @State private var webContentText = "" // Hidden text from web
    @State private var errorMessage: String?
    @State private var showError = false

    private let webFetcher = WebContentFetcher()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Input mode selector
                    Picker("Input Mode", selection: $inputMode) {
                        ForEach(InputMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Divider()

                    // Dynamic content based on mode
                    if inputMode == .web {
                        webInputSection
                    } else {
                        textInputSection
                    }

                    Divider()

                    // Language selector
                    languageSelector

                    // Voice selector
                    voiceSelector

                    Divider()

                    // Playback controls
                    playbackControls

                    // Speed control
                    speedControl
                }
                .padding()
            }
            .navigationTitle("Text to Voice")
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    // MARK: - Web Input Section

    private var webInputSection: some View {
        VStack(spacing: 15) {
            // URL Display
            if !urlInput.isEmpty {
                HStack {
                    Text(urlInput)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: clearURL) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            // Buttons Row
            HStack(spacing: 12) {
                // Paste URL Button
                Button(action: pasteURL) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste URL")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Fetch Content Button
                Button(action: fetchWebContent) {
                    HStack {
                        if isLoadingWeb {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Fetch")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(urlInput.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(urlInput.isEmpty || isLoadingWeb)
            }

            if isLoadingWeb {
                Text("Loading content...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Text Input Section

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextEditor(text: $textInput)
                .frame(minHeight: 200)
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            if textInput.isEmpty {
                Text("Paste or type your text here")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Language Selector

    private var languageSelector: some View {
        HStack {
            Text("Voice Language:")
                .font(.subheadline)

            Spacer()

            Picker("Language", selection: Binding(
                get: { speechManager.selectedLanguage },
                set: { speechManager.changeLanguage($0) }
            )) {
                ForEach(VoiceLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
    }

    // MARK: - Voice Selector

    private var voiceSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Voice:")
                .font(.subheadline)
                .padding(.horizontal)

            if speechManager.availableVoices.isEmpty {
                Text("No voices available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                Picker("Voice", selection: Binding(
                    get: { speechManager.selectedVoice ?? speechManager.availableVoices.first! },
                    set: { speechManager.selectVoice($0) }
                )) {
                    ForEach(speechManager.availableVoices, id: \.identifier) { voice in
                        Text(voiceDisplayName(for: voice))
                            .tag(voice)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
            }
        }
    }

    // Helper to format voice name
    private func voiceDisplayName(for voice: AVSpeechSynthesisVoice) -> String {
        var name = voice.name

        // Add quality indicator if available
        switch voice.quality {
        case .enhanced:
            name += " (Enhanced)"
        case .premium:
            name += " (Premium)"
        default:
            break
        }

        return name
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 30) {
            // Play/Pause Button (combined)
            Button(action: playOrPause) {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 50))
                    .foregroundColor(playPauseColor)
            }
            .disabled(!canPlayOrPause)

            // Stop
            Button(action: stopSpeech) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(speechManager.isSpeaking ? .red : .gray)
            }
            .disabled(!speechManager.isSpeaking)
        }
        .padding()
    }

    // Helper for play/pause button icon
    private var playPauseIcon: String {
        if speechManager.isSpeaking && !speechManager.isPaused {
            return "pause.circle.fill"
        } else {
            return "play.circle.fill"
        }
    }

    // Helper for play/pause button color
    private var playPauseColor: Color {
        if speechManager.isSpeaking && !speechManager.isPaused {
            return .orange
        } else if canPlay || speechManager.isPaused {
            return .green
        } else {
            return .gray
        }
    }

    // Helper to check if we can play or pause
    private var canPlayOrPause: Bool {
        return canPlay || speechManager.isSpeaking
    }

    // Helper to check if we can play
    private var canPlay: Bool {
        if inputMode == .web {
            return !webContentText.isEmpty
        } else {
            return !textInput.isEmpty
        }
    }

    // MARK: - Speed Control

    private var speedControl: some View {
        VStack {
            Text("Speed: \(String(format: "%.1f", speechManager.speechRate))x")
                .font(.subheadline)

            HStack {
                Text("Slow")
                    .font(.caption)
                Slider(value: Binding(
                    get: { speechManager.speechRate },
                    set: { speechManager.updateSpeed($0) }
                ), in: 0.1...1.0)
                Text("Fast")
                    .font(.caption)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func pasteURL() {
        #if os(iOS)
        if let clipboardString = UIPasteboard.general.string {
            urlInput = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        #elseif os(macOS)
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            urlInput = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        #endif
    }

    private func clearURL() {
        urlInput = ""
        webContentText = ""
    }

    private func fetchWebContent() {
        isLoadingWeb = true
        errorMessage = nil

        Task {
            do {
                let fetchedText = try await webFetcher.fetchText(from: urlInput)
                await MainActor.run {
                    webContentText = fetchedText
                    isLoadingWeb = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoadingWeb = false
                }
            }
        }
    }

    private func playOrPause() {
        if speechManager.isSpeaking {
            // If already speaking, toggle pause/resume
            togglePause()
        } else {
            // If not speaking, start playback
            playContent()
        }
    }

    private func playContent() {
        let contentToPlay: String
        let sourceURL: String?

        if inputMode == .web {
            guard !webContentText.isEmpty else { return }
            contentToPlay = webContentText
            sourceURL = urlInput.isEmpty ? nil : urlInput
        } else {
            guard !textInput.isEmpty else { return }
            contentToPlay = textInput
            sourceURL = nil
        }

        // Save to history
        let item = SavedItem(
            content: contentToPlay,
            sourceURL: sourceURL
        )
        historyManager.saveItem(item)

        // Play
        speechManager.speak(text: contentToPlay)
    }

    private func togglePause() {
        if speechManager.isPaused {
            speechManager.resume()
        } else {
            speechManager.pause()
        }
    }

    private func stopSpeech() {
        speechManager.stop()
    }
}

#Preview {
    ContentView()
}
