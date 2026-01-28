# Donna

> *"I know everything about everything."* - Donna Paulsen

Donna is your personal assistant for managing open-source tools natively on macOS. Like her namesake from Suits, Donna knows everything, anticipates your needs, and keeps everything running smoothly.

## What is Donna?

Donna is a **native macOS application** that hosts browser-based open-source tools in a unified, adaptive interface. Instead of juggling multiple browser tabs and ports, you get:

- 🎯 **Single native app** for all your tools
- 🎨 **Adaptive UI** that changes based on the tool you're using
- 📊 **Customizable dashboard** with widgets and layouts
- 🤖 **A2A Protocol support** for agent-to-agent communication
- 🔌 **Plugin architecture** to easily add new tools

## The Problem

Open-source tools like [Moltbot](https://github.com/moltbot/moltbot) and [Vibe Kanban](https://github.com/BloopAI/vibe-kanban) are amazing, but they:
- Run on different localhost ports
- Require browser access
- Don't have native macOS interfaces
- Can't communicate with each other

## The Solution

Donna wraps these tools in a beautiful native macOS interface:

```
┌─────────────────────────────────────────────┐
│  Donna - Your Tool Assistant                │
├─────────────────────────────────────────────┤
│                                             │
│  [Sidebar]    │  Adaptive Toolbar           │
│               │  [Tool-specific actions]    │
│  🔧 Moltbot   │                             │
│  📋 Vibe      │  ┌─────────────────────┐    │
│  🎯 Other     │  │                     │    │
│               │  │   Tool Content      │    │
│  ─────────    │  │   (WKWebView)       │    │
│  + Add Tool   │  │                     │    │
│               │  └─────────────────────┘    │
│               │                             │
└─────────────────────────────────────────────┘
```

## Features

### 🎨 Adaptive UI
- Toolbar changes based on active tool
- Native macOS controls (not just embedded web)
- Context-aware interface

### 📊 Dashboard Mode
- View multiple tools simultaneously
- Drag-and-drop layout customization
- Widgets for quick info at a glance

### 🤖 Agent-to-Agent (A2A)
- Tools can communicate via Google A2A protocol
- Coordinate multi-agent workflows
- Visual agent network view

### 🔌 Plugin Architecture
- Easy to add new tools via manifests
- Auto-discovery of localhost tools
- One-click installation

## Supported Tools

| Tool | Type | Status |
|------|------|--------|
| [Moltbot](https://github.com/moltbot/moltbot) | AI Assistant | ✅ Planned |
| [Vibe Kanban](https://github.com/BloopAI/vibe-kanban) | Task Management | ✅ Planned |
| [Your Tool Here] | - | 📝 Add it! |

## Architecture

```
Donna (Native macOS App)
├── SwiftUI Interface
├── WKWebView Container
├── Process Manager
├── Tool Registry
├── Adaptive Toolbar System
├── Dashboard Layout Engine
└── A2A Protocol Hub
```

## Tech Stack

- **Language**: Swift
- **Framework**: SwiftUI + AppKit
- **WebView**: WKWebView
- **Process Management**: Foundation.Process
- **Communication**: WebSocket, HTTP

## Roadmap

### Phase 1: Core Platform
- [ ] Native macOS app shell
- [ ] WKWebView container
- [ ] Process manager
- [ ] Basic sidebar navigation

### Phase 2: Adaptive UI
- [ ] Toolbar system
- [ ] Tool manifest parsing
- [ ] Dynamic UI generation

### Phase 3: Dashboard
- [ ] Multiple layouts
- [ ] Drag-and-drop
- [ ] Widget system

### Phase 4: A2A Protocol
- [ ] Agent discovery
- [ ] Task routing
- [ ] Network visualization

### Phase 5: Ecosystem
- [ ] Plugin marketplace
- [ ] Custom themes
- [ ] Community tools

## Development

### Prerequisites
- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

### Building
```bash
git clone https://github.com/Kavipriyan10-2000/donna.git
cd donna
open Donna.xcodeproj
```

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by the efficiency and adaptability of Donna Paulsen from Suits
- Built to support amazing open-source tools like Moltbot and Vibe Kanban
- Uses the [Google A2A Protocol](https://github.com/google/A2A) for agent communication

---

**Donna**: *Because you shouldn't need a browser to use your tools.*
