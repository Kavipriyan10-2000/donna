# Adaptive UI Platform for Open Source Tools

## Enhanced Vision

Create a **native macOS app** that acts as a **universal container** for open-source tools, with:
1. **Adaptive UI** - UI changes based on the tool being used
2. **Customizable Dashboard** - Users can arrange multiple tools
3. **A2A Protocol Support** - Agents can communicate with each other
4. **Plugin Architecture** - Easy to add new tools
5. **Unified Interface** - All tools in one window, no browser needed

---

## Core Concepts

### 1. Adaptive UI System

The app doesn't just embed webviews - it provides **context-aware UI chrome** that adapts to each tool:

```
┌─────────────────────────────────────────────────────────────┐
│  [Sidebar] │  Adaptive Toolbar (changes per tool)           │
│            │  ┌─────────────────────────────────────────┐  │
│  [Tool A]  │  │         Main Content Area               │  │
│  [Tool B]  │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐   │  │
│  [Tool C]  │  │  │ Widget  │ │ Widget  │ │ Widget  │   │  │
│            │  │  │   A1    │ │   A2    │ │   A3    │   │  │
│  ───────── │  │  └─────────┘ └─────────┘ └─────────┘   │  │
│  Dashboard │  │                                         │  │
│  Layout    │  │  ┌─────────────────────────────────┐    │  │
│  Settings  │  │  │     WebView (Tool Content)      │    │  │
│            │  │  │     localhost:PORT              │    │  │
│            │  │  └─────────────────────────────────┘    │  │
│            │  └─────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2. Tool Types Supported

#### Type A: Full Web UI (like Moltbot, Vibe Kanban)
- Embeds complete web interface
- Adaptive toolbar provides tool-specific actions
- Can be fullscreen or part of dashboard

#### Type B: API-Only Tools (no frontend)
- No web UI provided
- App generates UI from API spec/OpenAPI
- Custom widgets for data visualization

#### Type C: Agent Protocol Tools (A2A)
- Implements Google A2A protocol
- Can communicate with other agents
- UI shows agent status, conversations, actions

---

## Architecture

### 1. Tool Registry

Each tool has a manifest:

```json
{
  "id": "moltbot",
  "name": "Moltbot",
  "description": "Personal AI Assistant",
  "type": "web-ui",
  "install": {
    "command": "npm install -g moltbot",
    "check": "which moltbot"
  },
  "start": {
    "command": "moltbot gateway",
    "port": 18789,
    "healthCheck": "http://localhost:18789/health"
  },
  "ui": {
    "url": "http://localhost:18789",
    "fullscreen": true,
    "toolbar": [
      { "type": "button", "label": "New Chat", "action": "newChat" },
      { "type": "dropdown", "label": "Model", "options": ["claude", "gpt-4"] }
    ],
    "widgets": [
      { "type": "status", "source": "gateway.status" },
      { "type": "counter", "source": "messages.count" }
    ]
  },
  "a2a": {
    "supported": false
  }
}
```

### 2. Adaptive Toolbar System

Toolbar changes based on active tool:

```swift
protocol ToolToolbar {
    var items: [ToolbarItem] { get }
    func action(_ item: ToolbarItem)
}

struct ToolbarItem {
    let id: String
    let type: ToolbarItemType // button, dropdown, search, separator
    let label: String
    let icon: String?
    let action: String
    let shortcut: KeyboardShortcut?
}

// Tool provides its toolbar config
class MoltbotToolbar: ToolToolbar {
    var items: [ToolbarItem] = [
        ToolbarItem(type: .button, label: "New Chat", action: "newChat", shortcut: .cmdN),
        ToolbarItem(type: .dropdown, label: "Model", action: "selectModel"),
        ToolbarItem(type: .search, label: "Search History", action: "search"),
    ]
}
```

### 3. Dashboard Layout System

Users can arrange tools in customizable layouts:

```swift
enum LayoutType {
    case single        // One tool fullscreen
    case splitVertical // Two tools side by side
    case splitHorizontal // Two tools stacked
    case grid          // Multiple tools in grid
    case tabs          // Tabbed interface
    case floating      // Floating windows (like VSCode)
}

struct DashboardLayout {
    var type: LayoutType
    var tools: [ToolInstance]
    var positions: [ToolPosition] // For floating layout
}
```

### 4. Widget System

Tools can provide widgets for the dashboard:

```swift
protocol ToolWidget {
    var size: WidgetSize { get } // small, medium, large
    var refreshInterval: TimeInterval? { get }
    func render() -> AnyView
    func refresh()
}

// Example widgets
struct StatusWidget: ToolWidget {
    func render() -> AnyView {
        return AnyView(VStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            Text(statusText)
        })
    }
}

struct ActivityChartWidget: ToolWidget {
    func render() -> AnyView {
        return AnyView(Chart(data) { ... })
    }
}
```

---

## A2A (Agent-to-Agent) Protocol Support

### Google A2A Protocol Implementation

```swift
protocol A2AAgent {
    var agentId: String { get }
    var capabilities: [AgentCapability] { get }
    func sendTask(to agentId: String, task: Task) async throws -> TaskResult
    func receiveTask(_ task: Task) async -> TaskResult
}

struct Task {
    let id: String
    let type: String
    let payload: [String: Any]
    let callbackURL: URL?
}

// Agent Card (A2A spec)
struct AgentCard {
    let name: String
    let description: String
    let url: URL
    let capabilities: [Capability]
    let authentication: AuthScheme
}
```

### Agent Communication Hub

```swift
class AgentHub: ObservableObject {
    @Published var agents: [A2AAgent] = []
    @Published var activeConversations: [AgentConversation] = []
    
    func registerAgent(_ agent: A2AAgent) {
        agents.append(agent)
    }
    
    func routeTask(from: String, to: String, task: Task) async {
        guard let targetAgent = agents.first(where: { $0.agentId == to }) else {
            throw AgentError.agentNotFound
        }
        let result = await targetAgent.receiveTask(task)
        // Update UI with result
    }
}
```

---

## UI Layout Examples

### Example 1: Single Tool Focus
```
┌────────────────────────────────────────────┐
│ [Sidebar] │  Moltbot Toolbar               │
│           │  [New] [Model ▼] [Search]      │
│  [Moltbot]│                                │
│   ●       │  ┌──────────────────────────┐  │
│  [Vibe]   │  │                          │  │
│           │  │   Moltbot Web UI         │  │
│           │  │   (Embedded WKWebView)   │  │
│           │  │                          │  │
│           │  └──────────────────────────┘  │
└────────────────────────────────────────────┘
```

### Example 2: Split View (Two Tools)
```
┌────────────────────────────────────────────┐
│ [Sidebar] │  Toolbar: [Moltbot] [Vibe]     │
│           │                                │
│  [Moltbot]│  ┌────────────┐ ┌───────────┐ │
│   ●       │  │  Moltbot   │ │   Vibe    │ │
│  [Vibe]   │  │   Web UI   │ │  Kanban   │ │
│   ●       │  │            │ │   Board   │ │
│           │  │            │ │           │ │
│           │  └────────────┘ └───────────┘ │
└────────────────────────────────────────────┘
```

### Example 3: Dashboard with Widgets
```
┌────────────────────────────────────────────┐
│ [Sidebar] │  Dashboard Toolbar             │
│           │  [+ Add Widget] [Layout ▼]     │
│  Dashboard│                                │
│   ●       │  ┌──────────┐ ┌──────────────┐ │
│  [Moltbot]│  │ Status   │ │  Activity    │ │
│  [Vibe]   │  │  ● Live  │ │   Chart      │ │
│           │  └──────────┘ └──────────────┘ │
│           │  ┌──────────────────────────┐  │
│           │  │     Recent Tasks         │  │
│           │  └──────────────────────────┘  │
└────────────────────────────────────────────┘
```

### Example 4: Agent Network View (A2A)
```
┌────────────────────────────────────────────┐
│ [Sidebar] │  Agent Network Toolbar         │
│           │  [New Task] [Broadcast]        │
│  Network  │                                │
│   ●       │      ┌─────────┐               │
│           │      │ Moltbot │               │
│           │      └────┬────┘               │
│           │           │                    │
│           │     ┌─────┴─────┐              │
│           │     │           │              │
│           │ ┌───┴───┐   ┌───┴───┐          │
│           │ │ Vibe  │   │ Other │          │
│           │ │Kanban │   │ Agent │          │
│           │ └───────┘   └───────┘          │
│           │                                │
└────────────────────────────────────────────┘
```

---

## Tool Configuration Examples

### Moltbot Config
```json
{
  "id": "moltbot",
  "ui": {
    "type": "webview",
    "url": "http://localhost:18789",
    "toolbar": [
      { "type": "button", "label": "New Chat", "icon": "plus", "action": "newChat" },
      { "type": "dropdown", "label": "Model", "action": "selectModel", 
        "options": ["claude-opus", "claude-sonnet", "gpt-4"] },
      { "type": "toggle", "label": "Voice", "action": "toggleVoice" }
    ],
    "sidebar": [
      { "type": "list", "source": "conversations", "action": "openConversation" },
      { "type": "button", "label": "Settings", "action": "openSettings" }
    ]
  },
  "widgets": [
    { "type": "status", "title": "Gateway", "source": "gateway.status" },
    { "type": "list", "title": "Recent Chats", "source": "conversations.recent" }
  ]
}
```

### Vibe Kanban Config
```json
{
  "id": "vibe-kanban",
  "ui": {
    "type": "webview",
    "url": "http://localhost:3000",
    "toolbar": [
      { "type": "button", "label": "New Board", "action": "newBoard" },
      { "type": "dropdown", "label": "View", "action": "changeView",
        "options": ["Board", "List", "Calendar"] },
      { "type": "search", "placeholder": "Search tasks...", "action": "search" }
    ]
  },
  "widgets": [
    { "type": "chart", "title": "Task Progress", "chartType": "bar" },
    { "type": "counter", "title": "Active Agents", "source": "agents.active" }
  ]
}
```

### Generic API Tool Config
```json
{
  "id": "custom-api-tool",
  "ui": {
    "type": "generated",
    "openapiSpec": "http://localhost:8080/openapi.json",
    "layout": {
      "sections": [
        { "type": "endpoint-list", "filter": "GET" },
        { "type": "request-builder" },
        { "type": "response-viewer" }
      ]
    }
  }
}
```

---

## Implementation Roadmap

### Phase 1: Core Platform
- [ ] Native macOS app shell (SwiftUI)
- [ ] WKWebView container
- [ ] Tool registry system
- [ ] Process manager (start/stop tools)
- [ ] Basic sidebar navigation

### Phase 2: Adaptive UI
- [ ] Toolbar system
- [ ] Tool manifest parsing
- [ ] Dynamic toolbar generation
- [ ] Context-aware UI chrome

### Phase 3: Dashboard & Layouts
- [ ] Multiple layout types (split, grid, tabs)
- [ ] Drag-and-drop arrangement
- [ ] Save/restore layouts
- [ ] Widget system

### Phase 4: A2A Protocol
- [ ] Agent discovery
- [ ] Task routing
- [ ] Agent network visualization
- [ ] Inter-agent communication UI

### Phase 5: Advanced Features
- [ ] Plugin marketplace
- [ ] Custom themes
- [ ] Keyboard shortcuts
- [ ] Global quick launcher

---

## Technical Stack

### Native App
- **Language**: Swift
- **Framework**: SwiftUI + AppKit
- **WebView**: WKWebView
- **Process Management**: Process class
- **Networking**: URLSession, WebSocket

### Tool Integration
- **Manifest Format**: JSON/YAML
- **Process Control**: STDOUT/STDERR parsing
- **Health Checks**: HTTP polling
- **Auto-discovery**: mDNS/Bonjour

### A2A Protocol
- **Communication**: HTTP/JSON-RPC
- **Discovery**: Well-known endpoints
- **Authentication**: OAuth 2.0 / API Keys

---

## Key Differentiators

1. **Not just a browser** - Native adaptive UI that changes per tool
2. **Dashboard-centric** - Can view multiple tools simultaneously
3. **A2A ready** - Agents can talk to each other
4. **API tool support** - Auto-generates UI for API-only tools
5. **Plugin architecture** - Easy to add new tools via manifests
6. **Unified experience** - All tools feel like part of one app

---

## BMAD Agent Workflow

Use BMAD agents to execute:

1. **Analyst (Mary)** → ✅ Research tools, understand patterns
2. **PM (John)** → Create PRD with user stories
3. **UX Designer (Sally)** → Design dashboard layouts, adaptive UI
4. **Architect (Winston)** → Design SwiftUI architecture, A2A protocol
5. **Dev (Amelia)** → Build the native app
6. **TEA (Murat)** → Test with multiple tools

This creates a truly next-generation platform for running open-source tools natively on macOS!