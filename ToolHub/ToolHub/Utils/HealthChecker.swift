import Foundation

class HealthChecker {
    static let shared = HealthChecker()
    
    private let session: URLSession
    private var checkTasks: [String: Task<Void, Never>] = [:]
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        self.session = URLSession(configuration: config)
    }
    
    /// Check if a tool's health endpoint is responding
    func checkHealth(url: URL) async -> Bool {
        do {
            let (_, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...299).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            return false
        }
    }
    
    /// Wait for a tool to become healthy with timeout
    func waitForHealth(url: URL, timeout: TimeInterval = 30, interval: TimeInterval = 0.5) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if await checkHealth(url: url) {
                return true
            }
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        
        return false
    }
    
    /// Start periodic health checks for a tool
    func startMonitoring(toolId: String, url: URL, interval: TimeInterval = 5, onStatusChange: @escaping (Bool) -> Void) {
        stopMonitoring(toolId: toolId)
        
        let task = Task {
            while !Task.isCancelled {
                let isHealthy = await checkHealth(url: url)
                onStatusChange(isHealthy)
                
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
        
        checkTasks[toolId] = task
    }
    
    /// Stop monitoring a tool
    func stopMonitoring(toolId: String) {
        checkTasks[toolId]?.cancel()
        checkTasks.removeValue(forKey: toolId)
    }
    
    /// Stop all monitoring
    func stopAllMonitoring() {
        checkTasks.values.forEach { $0.cancel() }
        checkTasks.removeAll()
    }
}
