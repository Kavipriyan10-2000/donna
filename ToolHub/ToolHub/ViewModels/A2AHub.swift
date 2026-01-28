import Foundation
import Combine

@MainActor
class A2AHub: ObservableObject {
    static let shared = A2AHub()
    
    // MARK: - Published State
    @Published var registeredAgents: [Agent] = []
    @Published var activeTasks: [AgentTask] = []
    @Published var conversations: [AgentConversation] = []
    @Published var isDiscoveryRunning = false
    
    // MARK: - Private State
    private let client = A2AClient()
    private var discoveryTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Agent Registration
    
    func registerAgent(card: AgentCard, toolId: String) {
        let agent = Agent(
            id: card.id,
            card: card,
            toolId: toolId,
            lastSeen: Date(),
            isOnline: true,
            activeTasks: 0
        )
        
        if let index = registeredAgents.firstIndex(where: { $0.id == agent.id }) {
            registeredAgents[index] = agent
        } else {
            registeredAgents.append(agent)
        }
        
        // Persist registration
        saveRegistrations()
    }
    
    func unregisterAgent(id: String) {
        registeredAgents.removeAll { $0.id == id }
        saveRegistrations()
    }
    
    func updateAgentStatus(id: String, isOnline: Bool) {
        if let index = registeredAgents.firstIndex(where: { $0.id == id }) {
            registeredAgents[index].isOnline = isOnline
            registeredAgents[index].lastSeen = Date()
        }
    }
    
    // MARK: - Discovery
    
    func startDiscovery() {
        guard !isDiscoveryRunning else { return }
        
        isDiscoveryRunning = true
        
        discoveryTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.discoverAgents()
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            }
        }
    }
    
    func stopDiscovery() {
        discoveryTask?.cancel()
        discoveryTask = nil
        isDiscoveryRunning = false
    }
    
    private func discoverAgents() async {
        // Check known agents
        for var agent in registeredAgents {
            let isOnline = await client.checkAgentHealth(agent.card)
            updateAgentStatus(id: agent.id, isOnline: isOnline)
        }
        
        // Discover from running tools
        for (toolId, processInfo) in ProcessManager.shared.runningProcesses {
            guard processInfo.status == .running else { continue }
            
            // Try to discover agent at tool's endpoint
            if let url = URL(string: "http://localhost:\(processInfo.port)/a2a/agent.json"),
               let card = await client.fetchAgentCard(from: url) {
                registerAgent(card: card, toolId: toolId)
            }
        }
    }
    
    // MARK: - Task Management
    
    func sendTask(from fromAgent: String, to toAgent: String, type: String, payload: TaskPayload) async throws -> AgentTask {
        guard let targetAgent = registeredAgents.first(where: { $0.id == toAgent }) else {
            throw A2AError.agentNotFound(toAgent)
        }
        
        guard targetAgent.isOnline else {
            throw A2AError.agentOffline(toAgent)
        }
        
        let task = AgentTask(
            id: UUID().uuidString,
            fromAgent: fromAgent,
            toAgent: toAgent,
            type: type,
            payload: payload,
            callbackURL: nil,
            createdAt: Date(),
            status: .pending,
            result: nil,
            completedAt: nil
        )
        
        activeTasks.append(task)
        
        // Update agent active task count
        if let index = registeredAgents.firstIndex(where: { $0.id == toAgent }) {
            registeredAgents[index].activeTasks += 1
        }
        
        // Send task via HTTP
        do {
            let result = try await client.sendTask(task, to: targetAgent.card.endpoint)
            
            // Update task with result
            if let taskIndex = activeTasks.firstIndex(where: { $0.id == task.id }) {
                activeTasks[taskIndex].result = result
                activeTasks[taskIndex].status = result.success ? .completed : .failed
                activeTasks[taskIndex].completedAt = Date()
            }
            
            // Decrement active task count
            if let index = registeredAgents.firstIndex(where: { $0.id == toAgent }) {
                registeredAgents[index].activeTasks = max(0, registeredAgents[index].activeTasks - 1)
            }
            
            return activeTasks.first { $0.id == task.id } ?? task
        } catch {
            // Mark task as failed
            if let taskIndex = activeTasks.firstIndex(where: { $0.id == task.id }) {
                activeTasks[taskIndex].status = .failed
                activeTasks[taskIndex].completedAt = Date()
            }
            
            // Decrement active task count
            if let index = registeredAgents.firstIndex(where: { $0.id == toAgent }) {
                registeredAgents[index].activeTasks = max(0, registeredAgents[index].activeTasks - 1)
            }
            
            throw error
        }
    }
    
    func broadcastTask(from fromAgent: String, type: String, payload: TaskPayload) async -> [TaskResult] {
        var results: [TaskResult] = []
        
        await withTaskGroup(of: TaskResult?.self) { group in
            for agent in registeredAgents where agent.isOnline {
                group.addTask {
                    do {
                        let task = try await self.sendTask(
                            from: fromAgent,
                            to: agent.id,
                            type: type,
                            payload: payload
                        )
                        return task.result
                    } catch {
                        return TaskResult(
                            success: false,
                            data: nil,
                            error: TaskError(code: "SEND_FAILED", message: error.localizedDescription, details: nil),
                            metadata: nil
                        )
                    }
                }
            }
            
            for await result in group {
                if let result = result {
                    results.append(result)
                }
            }
        }
        
        return results
    }
    
    func cancelTask(id: String) {
        if let index = activeTasks.firstIndex(where: { $0.id == id }) {
            activeTasks[index].status = .cancelled
            activeTasks[index].completedAt = Date()
        }
    }
    
    // MARK: - Persistence
    
    private func saveRegistrations() {
        // Persist to UserDefaults or file
        if let data = try? JSONEncoder().encode(registeredAgents) {
            UserDefaults.standard.set(data, forKey: "a2a_registered_agents")
        }
    }
    
    func loadRegistrations() {
        if let data = UserDefaults.standard.data(forKey: "a2a_registered_agents"),
           let agents = try? JSONDecoder().decode([Agent].self, from: data) {
            registeredAgents = agents
        }
    }
}

// MARK: - A2A Client

class A2AClient {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    func checkAgentHealth(_ card: AgentCard) async -> Bool {
        let healthURL = card.endpoint.appendingPathComponent("/health")
        
        do {
            let (_, response) = try await session.data(from: healthURL)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    func fetchAgentCard(from url: URL) async -> AgentCard? {
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try JSONDecoder().decode(AgentCard.self, from: data)
        } catch {
            return nil
        }
    }
    
    func sendTask(_ task: AgentTask, to endpoint: URL) async throws -> TaskResult {
        let taskURL = endpoint.appendingPathComponent("/tasks")
        
        var request = URLRequest(url: taskURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(task)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw A2AError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw A2AError.httpError(httpResponse.statusCode, errorBody)
        }
        
        return try JSONDecoder().decode(TaskResult.self, from: data)
    }
}

// MARK: - Errors

enum A2AError: Error, LocalizedError {
    case agentNotFound(String)
    case agentOffline(String)
    case invalidResponse
    case httpError(Int, String)
    case taskFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .agentNotFound(let id):
            return "Agent '\(id)' not found"
        case .agentOffline(let id):
            return "Agent '\(id)' is offline"
        case .invalidResponse:
            return "Invalid response from agent"
        case .httpError(let code, let message):
            return "HTTP error \(code): \(message)"
        case .taskFailed(let reason):
            return "Task failed: \(reason)"
        }
    }
}
