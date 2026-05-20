# MeshTalk iOS

Native iOS walkie-talkie companion app for the MeshTalk mesh network bridge.

## Features

- **Push-to-Talk (PTT)**: Hold the large button to transmit
- **VOX Mode**: Voice-activated transmission with adjustable threshold
- **Background Audio**: Continues running when screen locks or app switches
- **WebSocket**: Connects to mesh bridge server with auto-reconnect
- **PCM16 Audio**: 16kHz mono, 100ms frames (3200 bytes)
- **Dark Theme**: Matches Android/web companion apps

## Requirements

- macOS with Xcode 15+ installed
- XcodeGen (`brew install xcodegen`)
- iOS 16.0+ device (no simulator - needs real microphone)

## Setup

```bash
# Generate the Xcode project
chmod +x generate-project.sh
./generate-project.sh

# Open in Xcode
open MeshTalk.xcodeproj
```

## Configuration

Default bridge server: `10.0.200.221:8440`

Change in the Settings gear icon within the app, or modify `MeshConfig.swift`.

## Architecture

```
MeshTalk/
├── MeshTalkApp.swift              # @main entry point
├── ContentView.swift              # SwiftUI walkie-talkie UI
├── Info.plist                     # Background modes, permissions
├── Models/
│   └── MeshConfig.swift           # Server/audio configuration
├── Audio/
│   ├── AudioEngine.swift          # AVAudioEngine capture + playback
│   ├── OpusCodec.swift            # Opus codec (PCM16 passthrough for now)
│   └── VoxDetector.swift          # Voice activity detection
├── Network/
│   ├── WebSocketClient.swift      # URLSessionWebSocketTask + reconnect
│   └── MeshBridgeClient.swift     # Bridge protocol (join, audio, control)
└── Service/
    └── BackgroundAudioManager.swift  # AVAudioSession + lifecycle
```

## WebSocket Protocol

Connects to: `ws://<host>:8440/ws/talk?id=iphone_<uuid>&channel=alpha&user=iPhone&format=pcm16`

- **Binary messages**: Raw PCM16 audio frames (bidirectional)
- **Text messages**: JSON control messages (peers, join/leave events)

## Bundle ID

`com.openclaw.meshtalk`
