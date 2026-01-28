import SwiftUI

struct ContentView: View {
    @StateObject private var toolManager = ToolManager.shared
    @StateObject private var processManager = ProcessManager.shared
    @StateObject private var dashboardManager = DashboardManager.shared
    @State private var isWebViewLoading = false
    @State private var webViewError: Error?
    @State private var selectedView: ViewType = .tools
    
    enum ViewType: String, CaseIterable {
        case tools = "Tools"
        case dashboard = "Dashboard"
        case agents = "Agents"
        
        var icon: String {
            switch self {
            case .tools: return "gearshape.2"
            case .dashboard: return "square.grid.2x2"
            case .agents: return "network"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedView: $selectedView)
        } detail: {
            detailContent
        }
        .frame(minWidth: 800, minHeight: 600)
        .alert("Error", isPresented: .constant(toolManager.errorMessage != nil)) {
            Button("OK") {
                toolManager.clearError()
            }
        } message: {
            Text(toolManager.errorMessage ?? "")
        }
    }
    
    @ViewBuilder
    private var detailContent: some View {
        switch selectedView {
        case .tools:
            if let selectedTool = toolManager.selectedTool {
                ToolDetailView(tool: selectedTool)
            } else {
                EmptyStateView(message: "Select a tool from the sidebar")
            }
        case .dashboard:
            DashboardView()
        case .agents:
            AgentNetworkView()
        }
    }
}

// MARK: - Tool Detail View

struct ToolDetailView: View {
    let tool: Tool
    @StateObject private var processManager = ProcessManager.shared
    @State private var isWebViewLoading = false
    @State private var webViewError: Error?
    @State private var currentURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ToolToolbar(tool: tool)
            
            Divider()
            
            // Content
            ZStack {
                if let url = currentURL {
                    if let error = webViewError {
                        ToolErrorView(error: error) {
                            reloadTool()
                        }
                    } else {
                        ToolWebView(
                            url: url,
                            toolId: tool.id,
                            isLoading: $isWebViewLoading,
                            error: $webViewError
                        )
                        .opacity(isWebViewLoading ? 0 : 1)
                        
                        if isWebViewLoading {
                            ToolLoadingView(toolName: tool.displayName)
                        }
                    }
                } else {
                    ToolNotRunningView(tool: tool)
                }
            }
            
            Divider()
            
            // Status Bar
            StatusBar(tool: tool)
        }
        .onAppear {
            updateURL()
        }
        .onChange(of: processManager.runningProcesses[tool.id]) { _ in
            updateURL()
        }
    }
    
    private func updateURL() {
        if let info = processManager.runningProcesses[tool.id],
           info.status == .running {
            currentURL = URL(string: "http://localhost:\(info.port)")
        } else {
            currentURL = nil
        }
    }
    
    private func reloadTool() {
        webViewError = nil
        isWebViewLoading = true
        updateURL()
    }
}

// MARK: - Tool Toolbar

struct ToolToolbar: View {
    let tool: Tool
    @StateObject private var processManager = ProcessManager.shared
    @StateObject private var toolManager = ToolManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Tool info
            HStack(spacing: 8) {
                Image(systemName: tool.icon)
                Text(tool.displayName)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Control buttons
            let isRunning = processManager.isRunning(toolId: tool.id)
            
            if isRunning {
                Button {
                    Task {
                        await toolManager.stopTool(tool)
                    }
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                
                Button {
                    Task {
                        await toolManager.restartTool(tool)
                    }
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    Task {
                        await toolManager.startTool(tool)
                    }
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(height: 44)
    }
}

// MARK: - Tool Not Running View

struct ToolNotRunningView: View {
    let tool: Tool
    @StateObject private var toolManager = ToolManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: tool.icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(tool.displayName)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This tool is not currently running")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button {
                Task {
                    await toolManager.startTool(tool)
                }
            } label: {
                Label("Start Tool", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Status Bar

struct StatusBar: View {
    let tool: Tool
    @StateObject private var processManager = ProcessManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Status
            HStack(spacing: 6) {
                StatusDot(status: processStatus)
                Text(processStatus.displayName)
                    .font(.caption)
            }
            
            Divider()
                .frame(height: 12)
            
            // Port info
            if let port = processManager.runningProcesses[tool.id]?.port, port > 0 {
                HStack(spacing: 4) {
                    Text("Port:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(port)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // PID
            if let pid = processManager.runningProcesses[tool.id]?.pid, pid > 0 {
                Text("PID: \(pid)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .frame(height: 28)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var processStatus: ProcessStatus {
        processManager.runningProcesses[tool.id]?.status ?? .stopped
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.dashed")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
