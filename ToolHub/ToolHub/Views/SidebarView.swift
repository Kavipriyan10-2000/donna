import SwiftUI

struct SidebarView: View {
    @Binding var selectedView: ContentView.ViewType
    @StateObject private var toolManager = ToolManager.shared
    @StateObject private var processManager = ProcessManager.shared
    @StateObject private var dashboardManager = DashboardManager.shared
    @State private var showingCatalog = false
    @State private var toolToDelete: Tool?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            // View Switcher
            Section("Views") {
                ForEach(ContentView.ViewType.allCases, id: \.self) { viewType in
                    Button {
                        selectedView = viewType
                    } label: {
                        HStack {
                            Image(systemName: viewType.icon)
                                .frame(width: 24)
                            Text(viewType.rawValue)
                            
                            Spacer()
                            
                            if selectedView == viewType {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Tools Section
            Section("Installed Tools") {
                ForEach(toolManager.tools) { tool in
                    ToolRow(
                        tool: tool,
                        isSelected: toolManager.selectedTool?.id == tool.id && selectedView == .tools,
                        status: processManager.runningProcesses[tool.id]?.status ?? .stopped
                    )
                    .tag(tool)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedView = .tools
                        toolManager.selectTool(tool)
                    }
                    .contextMenu {
                        ToolContextMenu(tool: tool)
                    }
                }
                .onDelete(perform: deleteTools)
                
                Button {
                    showingCatalog = true
                } label: {
                    Label("Add Tool", systemImage: "plus")
                }
                .buttonStyle(.plain)
            }
            
            // Dashboards Section
            Section("Dashboards") {
                ForEach(dashboardManager.configurations) { config in
                    Button {
                        selectedView = .dashboard
                        dashboardManager.setActiveConfiguration(id: config.id)
                    } label: {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .frame(width: 24)
                            Text(config.name)
                            
                            Spacer()
                            
                            if dashboardManager.activeConfigurationId == config.id && selectedView == .dashboard {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    let config = dashboardManager.createConfiguration(name: "New Dashboard")
                    dashboardManager.setActiveConfiguration(id: config.id)
                    selectedView = .dashboard
                } label: {
                    Label("New Dashboard", systemImage: "plus")
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .sheet(isPresented: $showingCatalog) {
            ToolCatalogView()
        }
        .alert("Remove Tool?", isPresented: $showingDeleteConfirmation, presenting: toolToDelete) { tool in
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task {
                    try? await toolManager.uninstallTool(id: tool.id)
                }
            }
        } message: { tool in
            Text("Are you sure you want to remove '\(tool.displayName)'? This will stop the tool if it's running.")
        }
    }
    
    private func deleteTools(at offsets: IndexSet) {
        for index in offsets {
            let tool = toolManager.tools[index]
            toolToDelete = tool
            showingDeleteConfirmation = true
        }
    }
    
    @ViewBuilder
    private func ToolContextMenu(tool: Tool) -> some View {
        let isRunning = processManager.isRunning(toolId: tool.id)
        
        if isRunning {
            Button {
                Task {
                    await toolManager.stopTool(tool)
                }
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            
            Button {
                Task {
                    await toolManager.restartTool(tool)
                }
            } label: {
                Label("Restart", systemImage: "arrow.clockwise")
            }
        } else {
            Button {
                Task {
                    await toolManager.startTool(tool)
                }
            } label: {
                Label("Start", systemImage: "play.fill")
            }
        }
        
        Divider()
        
        Button {
            toolToDelete = tool
            showingDeleteConfirmation = true
        } label: {
            Label("Remove", systemImage: "trash")
        }
    }
}

// MARK: - Tool Row

struct ToolRow: View {
    let tool: Tool
    let isSelected: Bool
    let status: ProcessStatus
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tool.icon)
                .frame(width: 24, height: 24)
                .foregroundColor(isSelected ? .accentColor : .primary)
            
            Text(tool.displayName)
                .lineLimit(1)
            
            Spacer()
            
            StatusDot(status: status)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Status Dot

struct StatusDot: View {
    let status: ProcessStatus
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
    
    private var color: Color {
        switch status {
        case .starting:
            return .yellow
        case .running:
            return .green
        case .stopped:
            return .gray
        case .error, .crashed:
            return .red
        }
    }
}

// MARK: - Tool Catalog View

struct ToolCatalogView: View {
    @StateObject private var toolManager = ToolManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isInstalling = false
    @State private var installingToolId: String?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                Section("Available Tools") {
                    ForEach(toolManager.getAvailableTools(), id: \.id) { manifest in
                        ToolCatalogRow(
                            manifest: manifest,
                            isInstalling: installingToolId == manifest.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isInstalling {
                                installTool(manifest: manifest)
                            }
                        }
                    }
                }
                
                if toolManager.tools.isEmpty && toolManager.getAvailableTools().isEmpty {
                    Section {
                        Text("No tools available")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Tool")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .frame(width: 400, height: 500)
    }
    
    private func installTool(manifest: ToolManifest) {
        isInstalling = true
        installingToolId = manifest.id
        errorMessage = nil
        
        Task {
            do {
                try await toolManager.installTool(manifest: manifest)
                await MainActor.run {
                    isInstalling = false
                    installingToolId = nil
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    installingToolId = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Tool Catalog Row

struct ToolCatalogRow: View {
    let manifest: ToolManifest
    let isInstalling: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: manifest.icon ?? "gearshape")
                .frame(width: 32, height: 32)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(manifest.name)
                    .font(.headline)
                
                Text(manifest.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("v\(manifest.version)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isInstalling {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "plus.circle")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 8)
        .opacity(isInstalling ? 0.6 : 1)
    }
}
