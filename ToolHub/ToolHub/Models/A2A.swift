import Foundation

// MARK: - A2A Protocol Models

/// Agent Card - Represents an agent's capabilities and endpoint
struct AgentCard: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let version: String
    let endpoint: URL
    let capabilities: [AgentCapability]
    let authentication: AuthScheme?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, version, endpoint, capabilities, authentication
    }
}

/// Agent Capability - What an agent can do
struct AgentCapability: Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let parameters: [CapabilityParameter]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, parameters
    }
}

/// Capability Parameter - Input/output for capabilities
struct CapabilityParameter: Codable, Equatable {
    let name: String
    let type: String
    let description: String
    let required: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, type, description, required
    }
}

/// Authentication Scheme
struct AuthScheme: Codable, Equatable {
    let type: String
    let description: String?
}

// MARK: - Task Models

/// Task - A unit of work sent between agents
struct AgentTask: Codable, Identifiable, Equatable {
    let id: String
    let fromAgent: String
    let toAgent: String
    let type: String
    let payload: TaskPayload
    let callbackURL: URL?
    let createdAt: Date
    var status: TaskStatus
    var result: TaskResult?
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromAgent = "from_agent"
        case toAgent = "to_agent"
        case type, payload
        case callbackURL = "callback_url"
        case createdAt = "created_at"
        case status, result
        case completedAt = "completed_at"
    }
}

/// Task Payload - The data sent with a task
struct TaskPayload: Codable, Equatable {
    let action: String
    let data: [String: AnyCodable]?
    let context: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case action, data, context
    }
}

/// Task Status
enum TaskStatus: String, Codable, Equatable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
    case cancelled
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

/// Task Result - The outcome of a task
struct TaskResult: Codable, Equatable {
    let success: Bool
    let data: [String: AnyCodable]?
    let error: TaskError?
    let metadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case success, data, error, metadata
    }
}

/// Task Error
struct TaskError: Codable, Equatable {
    let code: String
    let message: String
    let details: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case code, message, details
    }
}

// MARK: - Agent Models

/// Agent - Represents a registered agent in the system
struct Agent: Identifiable, Codable, Equatable {
    let id: String
    let card: AgentCard
    let toolId: String
    var lastSeen: Date
    var isOnline: Bool
    var activeTasks: Int
    
    enum CodingKeys: String, CodingKey {
        case id, card
        case toolId = "tool_id"
        case lastSeen = "last_seen"
        case isOnline = "is_online"
        case activeTasks = "active_tasks"
    }
}

/// Agent Conversation - A thread of communication between agents
struct AgentConversation: Identifiable, Codable, Equatable {
    let id: String
    let participants: [String]
    let tasks: [String]
    let createdAt: Date
    var lastActivityAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, participants, tasks
        case createdAt = "created_at"
        case lastActivityAt = "last_activity_at"
    }
}

// MARK: - Dashboard Models

/// Dashboard Configuration - User-customizable dashboard layout
struct DashboardConfiguration: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var layout: DashboardLayoutType
    var widgets: [DashboardWidget]
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, layout, widgets
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Dashboard Layout Type
enum DashboardLayoutType: String, Codable, Equatable, CaseIterable {
    case grid2x2 = "grid_2x2"
    case grid3x2 = "grid_3x2"
    case grid3x3 = "grid_3x3"
    case singleColumn = "single_column"
    case twoColumn = "two_column"
    case threeColumn = "three_column"
    case freeform = "freeform"
    
    var displayName: String {
        switch self {
        case .grid2x2: return "2x2 Grid"
        case .grid3x2: return "3x2 Grid"
        case .grid3x3: return "3x3 Grid"
        case .singleColumn: return "Single Column"
        case .twoColumn: return "Two Columns"
        case .threeColumn: return "Three Columns"
        case .freeform: return "Freeform"
        }
    }
    
    var columns: Int {
        switch self {
        case .grid2x2, .twoColumn: return 2
        case .grid3x2, .grid3x3, .threeColumn: return 3
        case .singleColumn: return 1
        case .freeform: return 0
        }
    }
}

/// Dashboard Widget - A component on the dashboard
struct DashboardWidget: Codable, Identifiable, Equatable {
    let id: String
    let type: WidgetType
    let title: String
    let dataSource: WidgetDataSource
    var position: WidgetPosition
    var size: WidgetSize
    var refreshInterval: TimeInterval?
    var configuration: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title
        case dataSource = "data_source"
        case position, size
        case refreshInterval = "refresh_interval"
        case configuration
    }
}

/// Widget Data Source - Where widget data comes from
struct WidgetDataSource: Codable, Equatable {
    let type: DataSourceType
    let agentId: String?
    let toolId: String?
    let endpoint: URL?
    let method: String?
    let parameters: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case agentId = "agent_id"
        case toolId = "tool_id"
        case endpoint, method, parameters
    }
}

enum DataSourceType: String, Codable, Equatable {
    case agent
    case tool
    case local
    case external
}

/// Widget Position - Location on dashboard
struct WidgetPosition: Codable, Equatable {
    var x: Int
    var y: Int
    var zIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case x, y
        case zIndex = "z_index"
    }
}

/// Widget Size - Dimensions
struct WidgetSize: Codable, Equatable {
    var width: Int  // In grid units or pixels
    var height: Int
    var isResizable: Bool
    
    enum CodingKeys: String, CodingKey {
        case width, height
        case isResizable = "is_resizable"
    }
}

// MARK: - AnyCodable Helper

/// Type-erased Codable wrapper for dynamic dictionaries
struct AnyCodable: Codable, Equatable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            try container.encodeNil()
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simplified equality check
        return String(describing: lhs.value) == String(describing: rhs.value)
    }
}
