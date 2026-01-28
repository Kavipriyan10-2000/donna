import Foundation

struct Tool: Identifiable, Codable, Equatable {
    let id: String
    let manifest: ToolManifest
    var installPath: String?
    var isInstalled: Bool
    var installDate: Date?
    var lastUsedDate: Date?
    
    init(manifest: ToolManifest) {
        self.id = manifest.id
        self.manifest = manifest
        self.isInstalled = false
    }
    
    var displayName: String {
        manifest.name
    }
    
    var icon: String {
        manifest.icon ?? "gearshape"
    }
    
    var localURL: URL? {
        guard let port = manifest.start.port else { return nil }
        return URL(string: "http://localhost:\(port)")
    }
}

struct ToolManifest: Codable, Equatable {
    let id: String
    let name: String
    let version: String
    let description: String
    let icon: String?
    let install: InstallConfig
    let start: StartConfig
    let ui: UIConfig
    let a2a: A2AConfig?
    
    enum CodingKeys: String, CodingKey {
        case id, name, version, description, icon, install, start, ui, a2a
    }
}

struct InstallConfig: Codable, Equatable {
    let command: String
    let check: String
}

struct StartConfig: Codable, Equatable {
    let command: String
    let port: Int?
    let portRange: PortRange?
    let healthCheck: String
    let workingDirectory: String?
    let environment: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case command, port, portRange, healthCheck, workingDirectory, environment
    }
}

struct PortRange: Codable, Equatable {
    let min: Int
    let max: Int
}

struct UIConfig: Codable, Equatable {
    let url: String
    let toolbar: [ToolbarItemConfig]?
    let widgets: [WidgetConfig]?
    let sidebar: [SidebarItemConfig]?
}

struct ToolbarItemConfig: Codable, Equatable {
    let type: ToolbarItemType
    let label: String
    let icon: String?
    let action: String
    let options: [String]?
    let shortcut: String?
    
    enum CodingKeys: String, CodingKey {
        case type, label, icon, action, options, shortcut
    }
}

enum ToolbarItemType: String, Codable, Equatable {
    case button
    case dropdown
    case search
    case toggle
    case separator
}

struct WidgetConfig: Codable, Equatable {
    let type: WidgetType
    let title: String
    let dataSource: String
    let refreshInterval: Int?
    
    enum CodingKeys: String, CodingKey {
        case type, title
        case dataSource = "source"
        case refreshInterval
    }
}

enum WidgetType: String, Codable, Equatable {
    case status
    case counter
    case chart
    case list
}

struct SidebarItemConfig: Codable, Equatable {
    let type: String
    let label: String
    let action: String
    let source: String?
}

struct A2AConfig: Codable, Equatable {
    let supported: Bool
    let capabilities: [String]
    let endpoint: String?
}

// MARK: - Process Info

struct ProcessInfo: Codable, Equatable {
    let toolId: String
    let port: Int
    let pid: Int32
    let startTime: Date
    var status: ProcessStatus
    var lastHealthCheck: Date?
    
    enum CodingKeys: String, CodingKey {
        case toolId, port, pid, startTime, status, lastHealthCheck
    }
}

enum ProcessStatus: String, Codable, Equatable {
    case starting
    case running
    case stopped
    case error
    case crashed
    
    var displayName: String {
        switch self {
        case .starting: return "Starting"
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .error: return "Error"
        case .crashed: return "Crashed"
        }
    }
    
    var color: String {
        switch self {
        case .starting: return "yellow"
        case .running: return "green"
        case .stopped: return "gray"
        case .error, .crashed: return "red"
        }
    }
}

// MARK: - Layout

enum LayoutType: String, Codable, CaseIterable, Equatable {
    case single
    case splitVertical
    case splitHorizontal
    case tabs
    case dashboard
    
    var displayName: String {
        switch self {
        case .single: return "Single"
        case .splitVertical: return "Split Vertical"
        case .splitHorizontal: return "Split Horizontal"
        case .tabs: return "Tabs"
        case .dashboard: return "Dashboard"
        }
    }
    
    var icon: String {
        switch self {
        case .single: return "square"
        case .splitVertical: return "square.split.2x1"
        case .splitHorizontal: return "square.split.1x2"
        case .tabs: return "rectangle.stack"
        case .dashboard: return "square.grid.2x2"
        }
    }
}

struct Layout: Codable, Equatable {
    let type: LayoutType
    let toolIds: [String]
    let activeToolId: String?
}
