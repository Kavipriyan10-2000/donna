# ToolHub

A native macOS application that serves as a universal container for open-source developer tools.

## Features

- **Universal Tool Container**: Run multiple localhost-based tools in one native app
- **Process Management**: Automatic start/stop of tool servers
- **WKWebView Integration**: Embed web-based tools seamlessly
- **Adaptive UI**: Tool-specific toolbar actions
- **Dashboard Layouts**: View multiple tools simultaneously
- **A2A Protocol**: Agent-to-agent communication support

## Supported Tools

- **Moltbot** - Personal AI Assistant (port 18789)
- **Vibe Kanban** - AI Coding Agent Orchestrator (dynamic port)

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for development)
- Swift 5.9+

## Installation

### From Source

1. Clone the repository
2. Open `ToolHub.xcodeproj` in Xcode
3. Build and run (⌘+R)

### From Release

Download the latest release from GitHub and drag `ToolHub.app` to your Applications folder.

## Usage

1. **Launch ToolHub**
2. **Add Tools**: Click "Add Tool" in the sidebar to install tools from the catalog
3. **Start Tools**: Select a tool and click "Start"
4. **Use Tools**: The tool's web interface loads in the main area

## Architecture

```
ToolHub/
├── Views/          # SwiftUI views
├── ViewModels/     # ObservableObjects for state management
├── Services/       # Business logic services
├── Models/         # Data models
├── Utils/          # Utility classes
└── Resources/      # Tool manifests
```

## Development

### Project Structure

- `ToolManager` - Central coordinator for tool lifecycle
- `ProcessManager` - Manages tool processes
- `ToolRegistry` - Loads and validates tool manifests
- `UserPreferences` - Persists user settings

### Adding a New Tool

Create a JSON manifest in `Resources/Manifests/`:

```json
{
  "id": "my-tool",
  "name": "My Tool",
  "version": "1.0.0",
  "description": "Description of my tool",
  "install": {
    "command": "npm install -g my-tool",
    "check": "which my-tool"
  },
  "start": {
    "command": "my-tool server",
    "port": 8080,
    "health_check": "http://localhost:8080/health"
  },
  "ui": {
    "url": "http://localhost:8080"
  }
}
```

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## Roadmap

- [x] Core platform with WKWebView
- [x] Process management
- [x] Tool registry
- [ ] Adaptive toolbar
- [ ] Dashboard with widgets
- [ ] A2A protocol implementation
- [ ] Plugin marketplace
- [ ] Windows/Linux support
