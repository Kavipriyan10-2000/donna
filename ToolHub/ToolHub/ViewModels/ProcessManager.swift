import Foundation
import Combine

@MainActor
class ProcessManager: ObservableObject {
    static let shared = ProcessManager()
    
    // MARK: - Published State
    @Published var runningProcesses: [String: ProcessInfo] = [:]
    @Published var processLogs: [String: [String]] = [:]
    
    // MARK: - Private State
    private var processes: [String: Process] = [:]
    private var logPipes: [String: Pipe] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Process Control
    
    func startProcess(for tool: Tool) async throws -> ProcessInfo {
        // Check if already running
        if let existingInfo = runningProcesses[tool.id], existingInfo.status == .running {
            return existingInfo
        }
        
        // Get available port
        guard let port = PortFinder.shared.getPort(for: tool) else {
            throw ProcessError.noAvailablePort
        }
        
        // Update status to starting
        let initialInfo = ProcessInfo(
            toolId: tool.id,
            port: port,
            pid: 0,
            startTime: Date(),
            status: .starting,
            lastHealthCheck: nil
        )
        runningProcesses[tool.id] = initialInfo
        
        // Create and configure process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        // Build command with port
        var command = tool.manifest.start.command
        if tool.manifest.start.port == nil {
            // If dynamic port, append to command
            command += " --port \(port)"
        }
        
        process.arguments = ["-c", command]
        
        // Set working directory if specified
        if let workingDir = tool.manifest.start.workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
        }
        
        // Set environment variables
        var environment = ProcessInfo.processInfo.environment
        environment["PORT"] = "\(port)"
        if let toolEnv = tool.manifest.start.environment {
            environment.merge(toolEnv) { _, new in new }
        }
        process.environment = environment
        
        // Setup log capture
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        logPipes[tool.id] = pipe
        
        // Start reading logs
        setupLogReading(for: tool.id, pipe: pipe)
        
        // Start process
        do {
            try process.run()
        } catch {
            PortFinder.shared.releasePort(port)
            runningProcesses[tool.id] = ProcessInfo(
                toolId: tool.id,
                port: port,
                pid: 0,
                startTime: Date(),
                status: .error,
                lastHealthCheck: nil
            )
            throw ProcessError.failedToStart(error)
        }
        
        // Wait for health check
        let healthURL = URL(string: tool.manifest.start.healthCheck.replacingOccurrences(of: "{port}", with: "\(port)"))!
        let isHealthy = await HealthChecker.shared.waitForHealth(url: healthURL, timeout: 30)
        
        if isHealthy {
            let info = ProcessInfo(
                toolId: tool.id,
                port: port,
                pid: process.processIdentifier,
                startTime: Date(),
                status: .running,
                lastHealthCheck: Date()
            )
            runningProcesses[tool.id] = info
            
            // Start monitoring
            startMonitoring(toolId: tool.id, healthURL: healthURL)
            
            // Setup termination handler
            setupTerminationHandler(for: tool.id, process: process)
            
            processes[tool.id] = process
            
            return info
        } else {
            // Health check failed, terminate process
            process.terminate()
            PortFinder.shared.releasePort(port)
            
            runningProcesses[tool.id] = ProcessInfo(
                toolId: tool.id,
                port: port,
                pid: process.processIdentifier,
                startTime: Date(),
                status: .error,
                lastHealthCheck: nil
            )
            
            throw ProcessError.healthCheckFailed
        }
    }
    
    func stopProcess(for toolId: String) async {
        guard let process = processes[toolId] else { return }
        
        // Stop monitoring
        HealthChecker.shared.stopMonitoring(toolId: toolId)
        
        // Terminate process
        process.terminate()
        
        // Wait a bit for graceful termination
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Force kill if still running
        if process.isRunning {
            process.forceTerminate()
        }
        
        // Cleanup
        if let info = runningProcesses[toolId] {
            PortFinder.shared.releasePort(info.port)
        }
        
        processes.removeValue(forKey: toolId)
        logPipes.removeValue(forKey: toolId)
        
        runningProcesses[toolId] = ProcessInfo(
            toolId: toolId,
            port: 0,
            pid: 0,
            startTime: Date(),
            status: .stopped,
            lastHealthCheck: nil
        )
    }
    
    func restartProcess(for tool: Tool) async throws -> ProcessInfo {
        await stopProcess(for: tool.id)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return try await startProcess(for: tool)
    }
    
    func stopAllProcesses() async {
        for toolId in processes.keys {
            await stopProcess(for: toolId)
        }
    }
    
    // MARK: - Status
    
    func getProcessStatus(for toolId: String) -> ProcessStatus {
        return runningProcesses[toolId]?.status ?? .stopped
    }
    
    func isRunning(toolId: String) -> Bool {
        return runningProcesses[toolId]?.status == .running
    }
    
    func getLogs(for toolId: String) -> [String] {
        return processLogs[toolId] ?? []
    }
    
    // MARK: - Private Methods
    
    private func setupLogReading(for toolId: String, pipe: Pipe) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard let output = String(data: data, encoding: .utf8),
                  !output.isEmpty else { return }
            
            Task { @MainActor in
                let lines = output.components(separatedBy: .newlines)
                if self?.processLogs[toolId] == nil {
                    self?.processLogs[toolId] = []
                }
                self?.processLogs[toolId]?.append(contentsOf: lines)
                
                // Keep only last 1000 lines
                if let count = self?.processLogs[toolId]?.count, count > 1000 {
                    self?.processLogs[toolId] = Array(self?.processLogs[toolId]?.suffix(1000) ?? [])
                }
            }
        }
    }
    
    private func startMonitoring(toolId: String, healthURL: URL) {
        HealthChecker.shared.startMonitoring(toolId: toolId, url: healthURL) { [weak self] isHealthy in
            Task { @MainActor in
                guard var info = self?.runningProcesses[toolId] else { return }
                info.lastHealthCheck = Date()
                
                if !isHealthy && info.status == .running {
                    info.status = .error
                    self?.runningProcesses[toolId] = info
                } else if isHealthy && info.status == .error {
                    info.status = .running
                    self?.runningProcesses[toolId] = info
                }
            }
        }
    }
    
    private func setupTerminationHandler(for toolId: String, process: Process) {
        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                guard let self = self else { return }
                
                // Only handle unexpected termination
                guard self.runningProcesses[toolId]?.status != .stopped else { return }
                
                let exitCode = process.terminationStatus
                let reason = process.terminationReason
                
                print("Process \(toolId) terminated with code \(exitCode), reason: \(reason)")
                
                if exitCode != 0 {
                    // Mark as crashed
                    if var info = self.runningProcesses[toolId] {
                        info.status = .crashed
                        self.runningProcesses[toolId] = info
                    }
                    
                    // Auto-restart if enabled
                    if UserPreferences.shared.autoStartTools {
                        print("Auto-restarting \(toolId)...")
                        if let tool = UserPreferences.shared.getTool(toolId) {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            _ = try? await self.startProcess(for: tool)
                        }
                    }
                }
            }
        }
    }
}

enum ProcessError: Error, LocalizedError {
    case noAvailablePort
    case failedToStart(Error)
    case healthCheckFailed
    case processNotFound
    
    var errorDescription: String? {
        switch self {
        case .noAvailablePort:
            return "Could not find an available port for the tool"
        case .failedToStart(let error):
            return "Failed to start process: \(error.localizedDescription)"
        case .healthCheckFailed:
            return "Tool started but health check failed. The tool may not be responding."
        case .processNotFound:
            return "Process not found"
        }
    }
}
