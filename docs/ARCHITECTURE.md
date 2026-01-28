# Native App Platform Analysis

## Problem Statement

You want to create a **native macOS application** that can:
1. **Host/embed** browser-based open-source tools (like moltbot, vibe-kanban)
2. **Avoid browser navigation** - everything inside one native app
3. **Pick and choose** which tools to run
4. **Unified interface** for all tools

## Analyzed Tools

### 1. Moltbot
- **Type**: Personal AI Assistant / Gateway
- **Access**: Web UI at `ws://127.0.0.1:18789`
- **Architecture**: Gateway (WebSocket) + CLI + WebChat UI
- **Current**: Runs as daemon, accessed via browser
- **Key Components**:
  - Gateway WebSocket control plane
  - WebChat UI (served from Gateway)
  - macOS menu bar app (optional companion)
  - iOS/Android nodes

### 2. Vibe Kanban
- **Type**: AI Coding Agent Orchestrator
- **Access**: Web UI on `http://localhost:PORT`
- **Architecture**: Rust backend + Node.js frontend
- **Current**: Runs via `npx vibe-kanban`, accessed via browser
- **Key Components**:
  - Rust backend server
  - React/Vue frontend
  - MCP server integration
  - Git worktree management

### 3. Common Pattern
Both tools:
- Run local HTTP/WebSocket servers
- Serve web UIs on localhost ports
- Require browser to access
- Have no native macOS UI

---

## Solution Approaches

### Approach 1: Native WebView Container (Recommended)

**Concept**: Create a native macOS app that embeds web content

**Architecture**:
```
┌─────────────────────────────────────────┐
│         Native macOS App (SwiftUI)      │
│  ┌─────────────────────────────────┐    │
│  │     WKWebView / WebKit          │    │
│  │  ┌─────────────────────────┐    │    │
│  │  │   Tool 1: Moltbot       │    │    │
│  │  │   localhost:18789       │    │    │
│  │  └─────────────────────────┘    │    │
│  │  ┌─────────────────────────┐    │    │
│  │  │   Tool 2: Vibe Kanban   │    │    │
│  │  │   localhost:3000        │    │    │
│  │  └─────────────────────────┘    │    │
│  │  ┌─────────────────────────┐    │    │
│  │  │   Tool 3: [Future]      │    │    │
│  │  └─────────────────────────┘    │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [Sidebar] [Toolbar] [Tab Bar]          │
└─────────────────────────────────────────┘
```

**Pros**:
- Native macOS look and feel
- Can add native features (menu bar, shortcuts, notifications)
- Single app for all tools
- Can inject native ↔ web bridge APIs

**Cons**:
- Requires Swift/SwiftUI development
- Each tool still runs its own server

**Tech Stack**:
- Swift + SwiftUI
- WKWebView (WebKit)
- AppKit for native integration

---

### Approach 2: Electron/Tauri Wrapper

**Concept**: Cross-platform desktop app wrapper

**Architecture**:
```
┌─────────────────────────────────────────┐
│         Electron/Tauri App              │
│  ┌─────────────────────────────────┐    │
│  │     Chromium/WebView2           │    │
│  │  (Multiple webviews/tabs)       │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

**Pros**:
- Cross-platform (macOS, Windows, Linux)
- Web technologies (HTML/CSS/JS)
- Large ecosystem

**Cons**:
- Electron is heavy (bundles Chromium)
- Tauri is lighter but still adds complexity
- Less "native" feel on macOS

**Tech Stack**:
- Tauri (Rust + WebView) - lighter than Electron
- Or Electron if needed

---

### Approach 3: Native + Embedded Servers

**Concept**: Native app that includes and manages the tool servers

**Architecture**:
```
┌─────────────────────────────────────────┐
│         Native macOS App                │
│                                         │
│  ┌──────────────┐  ┌──────────────┐    │
│  │  SwiftUI UI  │  │  Server Mgr  │    │
│  │  (Sidebar)   │  │  (Process)   │    │
│  └──────┬───────┘  └──────┬───────┘    │
│         │                 │             │
│         └────────┬────────┘             │
│                  │                      │
│  ┌───────────────┼───────────────┐      │
│  │     WKWebView (Embedded)      │      │
│  │  ┌───────────────────────┐    │      │
│  │  │  localhost:PORT       │    │      │
│  │  │  (Served by embedded) │    │      │
│  │  └───────────────────────┘    │      │
│  └───────────────────────────────┘      │
└─────────────────────────────────────────┘
```

**Pros**:
- Fully self-contained
- No external dependencies
- Clean user experience

**Cons**:
- Complex to bundle Node.js/Rust servers
- Large app size
- Updates are harder

---

## Recommended Architecture

### Native macOS App with WebView Container + Process Manager

**Why this approach**:
1. **Truly native** - Uses SwiftUI + WKWebView
2. **Lightweight** - Doesn't bundle servers, just manages them
3. **Flexible** - Can add any localhost-based tool
4. **Extensible** - Can add native features later

**Components**:

#### 1. Main App (SwiftUI)
```swift
// App entry point
@main
struct ToolLauncherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### 2. Tool Manager
- Manages list of available tools
- Handles tool installation (npm, cargo, etc.)
- Starts/stops tool processes
- Monitors port availability

#### 3. WebView Container
- WKWebView for each tool
- Tab-based interface
- URL routing to localhost ports

#### 4. Sidebar Navigation
- List of installed tools
- Quick launch buttons
- Status indicators (running/stopped)

#### 5. Process Manager
- Spawns tool processes (Node, Rust, etc.)
- Captures stdout/stderr
- Auto-restart on crash
- Port conflict resolution

---

## User Flow

```
1. Open Native App
   │
2. See Sidebar with Available Tools
   │
3. Click "Moltbot"
   │
4. App checks if moltbot is installed
   │
   ├─ Not installed? → Show install button
   │                    Run: npm install -g moltbot
   │
   └─ Installed? → Start process: moltbot gateway
                    Wait for port 18789
                    Load WKWebView → localhost:18789
   │
5. Tool appears in main area
   │
6. Can switch to other tools via sidebar
   │
7. Close app → Optionally stop all processes
```

---

## Technical Implementation

### SwiftUI + WKWebView

```swift
import SwiftUI
import WebKit

struct ToolWebView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

struct ContentView: View {
    @StateObject private var toolManager = ToolManager()
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(toolManager.tools) { tool in
                ToolRow(tool: tool)
                    .onTapGesture {
                        toolManager.selectTool(tool)
                    }
            }
        } detail: {
            // Main content
            if let selectedTool = toolManager.selectedTool {
                if selectedTool.isRunning {
                    ToolWebView(url: selectedTool.localURL)
                } else {
                    StartToolView(tool: selectedTool)
                }
            }
        }
    }
}
```

### Process Manager

```swift
class ToolProcessManager: ObservableObject {
    func startTool(_ tool: Tool) {
        let process = Process()
        process.executableURL = tool.executableURL
        process.arguments = tool.arguments
        
        // Capture output
        let pipe = Pipe()
        process.standardOutput = pipe
        
        // Start process
        try? process.run()
        
        // Wait for port to be ready
        waitForPort(tool.port) {
            tool.isRunning = true
        }
    }
    
    func stopTool(_ tool: Tool) {
        tool.process?.terminate()
        tool.isRunning = false
    }
}
```

---

## BMAD Agent Workflow for This Project

### Phase 1: Analysis (Analyst Agent - Mary)
- Research existing tools (moltbot, vibe-kanban)
- Understand user pain points
- Document requirements

### Phase 2: Planning (PM Agent - John)
- Create PRD for the native app platform
- Define MVP features
- Prioritize tool support

### Phase 3: Architecture (Architect Agent - Winston)
- Design system architecture
- Choose tech stack (SwiftUI + WKWebView)
- Define process management strategy

### Phase 4: Implementation (Dev Agent - Amelia)
- Build SwiftUI app
- Implement process manager
- Add tool discovery/installation

### Phase 5: Testing (TEA Agent - Murat)
- Test with moltbot
- Test with vibe-kanban
- Add other tools

---

## Next Steps

1. **Create PRD** using BMAD PM agent workflow
2. **Design architecture** using BMAD Architect agent
3. **Build MVP** with support for 2-3 tools
4. **Test and iterate**

This approach gives you a true native macOS app that can host any localhost-based tool, with a unified interface for managing and switching between them.