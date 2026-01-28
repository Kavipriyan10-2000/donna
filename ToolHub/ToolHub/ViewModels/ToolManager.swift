import Foundation
import Combine

@MainActor
class ToolManager: ObservableObject {
    static let shared = ToolManager()
    
    // MARK: - Published State
    @Published var tools: [Tool] = []
    @Published var selectedTool: Tool?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let registry = ToolRegistry.shared
    private let preferences = UserPreferences.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadTools()
        
        // Subscribe to preferences changes
        preferences.$installedTools
            .sink { [weak self] _ in
                self?.loadTools()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Tool Loading
    
    func loadTools() {
        // Load installed tools from preferences
        tools = preferences.installedTools
        
        // Restore selected tool
        if let selectedId = preferences.selectedToolId,
           let tool = tools.first(where: { $0.id == selectedId }) {
            selectedTool = tool
        }
    }
    
    // MARK: - Tool Installation
    
    func installTool(manifest: ToolManifest) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Check if already installed
        guard !preferences.isToolInstalled(manifest.id) else {
            throw ToolManagerError.alreadyInstalled(manifest.id)
        }
        
        // Run install command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", manifest.install.command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw ToolManagerError.installationFailed(output)
            }
        } catch {
            throw ToolManagerError.installationFailed(error.localizedDescription)
        }
        
        // Create and save tool
        var tool = Tool(manifest: manifest)
        tool.isInstalled = true
        tool.installDate = Date()
        
        preferences.addTool(tool)
        
        // Reload tools
        loadTools()
    }
    
    func uninstallTool(id: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Stop process if running
        if ProcessManager.shared.isRunning(toolId: id) {
            await ProcessManager.shared.stopProcess(for: id)
        }
        
        // Remove from preferences
        preferences.removeTool(id)
        
        // Reload tools
        loadTools()
        
        // Clear selection if needed
        if selectedTool?.id == id {
            selectedTool = nil
            preferences.selectedToolId = nil
        }
    }
    
    // MARK: - Tool Selection
    
    func selectTool(_ tool: Tool?) {
        selectedTool = tool
        preferences.selectedToolId = tool?.id
        
        if let tool = tool {
            var updatedTool = tool
            updatedTool.lastUsedDate = Date()
            preferences.updateTool(updatedTool)
        }
    }
    
    // MARK: - Tool Control
    
    func startTool(_ tool: Tool) async {
        errorMessage = nil
        
        do {
            _ = try await ProcessManager.shared.startProcess(for: tool)
        } catch {
            errorMessage = "Failed to start \(tool.displayName): \(error.localizedDescription)"
        }
    }
    
    func stopTool(_ tool: Tool) async {
        errorMessage = nil
        await ProcessManager.shared.stopProcess(for: tool.id)
    }
    
    func restartTool(_ tool: Tool) async {
        errorMessage = nil
        
        do {
            _ = try await ProcessManager.shared.restartProcess(for: tool)
        } catch {
            errorMessage = "Failed to restart \(tool.displayName): \(error.localizedDescription)"
        }
    }
    
    // MARK: - Tool Status
    
    func getToolStatus(_ tool: Tool) -> ProcessStatus {
        return ProcessManager.shared.getProcessStatus(for: tool.id)
    }
    
    func isToolRunning(_ tool: Tool) -> Bool {
        return ProcessManager.shared.isRunning(toolId: tool.id)
    }
    
    func getToolURL(_ tool: Tool) -> URL? {
        guard let info = ProcessManager.shared.runningProcesses[tool.id] else { return nil }
        return URL(string: "http://localhost:\(info.port)")
    }
    
    // MARK: - Available Tools
    
    func getAvailableTools() -> [ToolManifest] {
        return registry.getAvailableTools()
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

enum ToolManagerError: Error, LocalizedError {
    case alreadyInstalled(String)
    case installationFailed(String)
    case notInstalled(String)
    
    var errorDescription: String? {
        switch self {
        case .alreadyInstalled(let id):
            return "Tool '\(id)' is already installed"
        case .installationFailed(let reason):
            return "Installation failed: \(reason)"
        case .notInstalled(let id):
            return "Tool '\(id)' is not installed"
        }
    }
}
