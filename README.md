# Text to Voice

A powerful and customizable iOS text-to-speech application built with SwiftUI and AVFoundation. Read web content or custom text aloud with full control over voice selection, playback speed, and language preferences.

## Features

- **Dual Input Modes**
  - 📱 **Web URL Reader**: Fetch and read content from any webpage
  - ✍️ **Text Input**: Paste or type text directly for instant playback

- **Multi-Language Support**
  - English (US) - Default voice: Samantha
  - Spanish (Spain) - Default voice: Mónica
  - Spanish (Argentina) - Default voice: Isabella
  - Finnish - Default voice: Satu

- **Advanced Voice Control**
  - Select from all available system voices for each language
  - Voice quality indicators (Enhanced/Premium)
  - Persistent voice preferences

- **Playback Controls**
  - Play/Pause toggle
  - Stop button
  - Adjustable speed (0.1x - 1.0x)
  - Background audio playback
  - Lock screen controls integration

- **History Management**
  - Automatic saving of read content
  - Quick replay from history
  - Swipe to delete individual items
  - Clear all history option

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/TextToVoice.git
```

2. Open the project in Xcode:
```bash
cd TextToVoice
open TextToVoice.xcodeproj
```

3. Build and run the project on your device or simulator

## Usage

### Reading Web Content

1. Switch to "From Web" mode using the segmented control
2. Tap **Paste URL** to paste a URL from clipboard
3. Tap **Fetch** to download and extract text from the webpage
4. Press the **Play** button to start reading

### Reading Custom Text

1. Switch to "From Text" mode
2. Type or paste your text in the text editor
3. Press the **Play** button to start reading

### Changing Voice and Language

1. Select your preferred language from the **Voice Language** picker
2. Choose a specific voice from the **Voice** picker
3. Your selection is automatically saved for future sessions

### Adjusting Speed

Use the speed slider to adjust playback speed from 0.1x (slow) to 1.0x (fast). The default speed is 0.3x for comfortable listening.

### Managing History

1. Switch to the **History** tab to view previously read content
2. Tap any item to replay it
3. Swipe left to delete individual items
4. Use the trash button to clear all history

## Technical Details

### Architecture

- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Speech synthesis with AVSpeechSynthesizer
- **Combine**: Reactive state management
- **MediaPlayer**: Lock screen controls and Now Playing integration
- **URLSession**: Async web content fetching
- **UserDefaults**: Persistent storage for history and preferences

### Key Components

- `SpeechManager`: Core speech synthesis manager with audio session configuration
- `WebContentFetcher`: HTML content fetching and text extraction
- `HistoryManager`: Data persistence and history management
- `ContentView`: Main UI with tab navigation
- `ReaderView`: Input handling and playback controls
- `HistoryView`: History list with replay functionality

### Background Audio

The app supports background audio playback, allowing you to:
- Continue listening with the screen locked
- Control playback from the lock screen
- Use system media controls (Control Center, AirPods, etc.)

## License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2025 Nelson Cabrera

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests

## Author

Nelson Cabrera

## Acknowledgments

Built with SwiftUI and AVFoundation frameworks provided by Apple.

## Screenshots

<img src="IMG_1267.PNG" width="300" alt="Text to Voice App Screenshot 1">
<img src="IMG_1268.PNG" width="300" alt="Text to Voice App Screenshot 2">
