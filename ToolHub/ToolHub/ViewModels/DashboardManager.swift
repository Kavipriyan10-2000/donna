import Foundation
import Combine

@MainActor
class DashboardManager: ObservableObject {
    static let shared = DashboardManager()
    
    // MARK: - Published State
    @Published var configurations: [DashboardConfiguration] = []
    @Published var activeConfigurationId: String?
    @Published var isEditing = false
    
    // MARK: - Computed Properties
    var activeConfiguration: DashboardConfiguration? {
        configurations.first { $0.id == activeConfigurationId }
    }
    
    // MARK: - Private State
    private let preferences = UserPreferences.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadConfigurations()
        
        // Create default dashboard if none exists
        if configurations.isEmpty {
            createDefaultDashboard()
        }
    }
    
    // MARK: - Configuration Management
    
    func createConfiguration(name: String, layout: DashboardLayoutType = .grid2x2) -> DashboardConfiguration {
        let config = DashboardConfiguration(
            id: UUID().uuidString,
            name: name,
            layout: layout,
            widgets: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        configurations.append(config)
        saveConfigurations()
        
        // Set as active if first config
        if activeConfigurationId == nil {
            activeConfigurationId = config.id
        }
        
        return config
    }
    
    func deleteConfiguration(id: String) {
        configurations.removeAll { $0.id == id }
        
        if activeConfigurationId == id {
            activeConfigurationId = configurations.first?.id
        }
        
        saveConfigurations()
    }
    
    func updateConfiguration(_ config: DashboardConfiguration) {
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            var updatedConfig = config
            updatedConfig.updatedAt = Date()
            configurations[index] = updatedConfig
            saveConfigurations()
        }
    }
    
    func setActiveConfiguration(id: String) {
        activeConfigurationId = id
        UserDefaults.standard.set(id, forKey: "dashboard_active_config")
    }
    
    // MARK: - Widget Management
    
    func addWidget(
        to configurationId: String,
        type: WidgetType,
        title: String,
        dataSource: WidgetDataSource,
        position: WidgetPosition = WidgetPosition(x: 0, y: 0, zIndex: 0),
        size: WidgetSize = WidgetSize(width: 1, height: 1, isResizable: true)
    ) {
        guard let index = configurations.firstIndex(where: { $0.id == configurationId }) else { return }
        
        let widget = DashboardWidget(
            id: UUID().uuidString,
            type: type,
            title: title,
            dataSource: dataSource,
            position: position,
            size: size,
            refreshInterval: nil,
            configuration: nil
        )
        
        configurations[index].widgets.append(widget)
        configurations[index].updatedAt = Date()
        saveConfigurations()
    }
    
    func removeWidget(from configurationId: String, widgetId: String) {
        guard let index = configurations.firstIndex(where: { $0.id == configurationId }) else { return }
        
        configurations[index].widgets.removeAll { $0.id == widgetId }
        configurations[index].updatedAt = Date()
        saveConfigurations()
    }
    
    func updateWidgetPosition(configurationId: String, widgetId: String, position: WidgetPosition) {
        guard let configIndex = configurations.firstIndex(where: { $0.id == configurationId }) else { return }
        guard let widgetIndex = configurations[configIndex].widgets.firstIndex(where: { $0.id == widgetId }) else { return }
        
        configurations[configIndex].widgets[widgetIndex].position = position
        configurations[configIndex].updatedAt = Date()
        saveConfigurations()
    }
    
    func updateWidgetSize(configurationId: String, widgetId: String, size: WidgetSize) {
        guard let configIndex = configurations.firstIndex(where: { $0.id == configurationId }) else { return }
        guard let widgetIndex = configurations[configIndex].widgets.firstIndex(where: { $0.id == widgetId }) else { return }
        
        configurations[configIndex].widgets[widgetIndex].size = size
        configurations[configIndex].updatedAt = Date()
        saveConfigurations()
    }
    
    // MARK: - Layout Management
    
    func changeLayout(configurationId: String, to layout: DashboardLayoutType) {
        guard let index = configurations.firstIndex(where: { $0.id == configurationId }) else { return }
        
        configurations[index].layout = layout
        configurations[index].updatedAt = Date()
        saveConfigurations()
    }
    
    // MARK: - Default Dashboard
    
    private func createDefaultDashboard() {
        var config = DashboardConfiguration(
            id: UUID().uuidString,
            name: "Main Dashboard",
            layout: .grid2x2,
            widgets: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Add default widgets for installed tools
        let tools = preferences.installedTools
        
        for (index, tool) in tools.enumerated().prefix(4) {
            let widget = DashboardWidget(
                id: UUID().uuidString,
                type: .status,
                title: "\(tool.displayName) Status",
                dataSource: WidgetDataSource(
                    type: .tool,
                    agentId: nil,
                    toolId: tool.id,
                    endpoint: nil,
                    method: nil,
                    parameters: nil
                ),
                position: WidgetPosition(x: index % 2, y: index / 2, zIndex: 0),
                size: WidgetSize(width: 1, height: 1, isResizable: true),
                refreshInterval: 5,
                configuration: nil
            )
            
            config.widgets.append(widget)
        }
        
        configurations.append(config)
        activeConfigurationId = config.id
        saveConfigurations()
    }
    
    // MARK: - Persistence
    
    private func saveConfigurations() {
        if let data = try? JSONEncoder().encode(configurations) {
            UserDefaults.standard.set(data, forKey: "dashboard_configurations")
        }
    }
    
    private func loadConfigurations() {
        if let data = UserDefaults.standard.data(forKey: "dashboard_configurations"),
           let configs = try? JSONDecoder().decode([DashboardConfiguration].self, from: data) {
            configurations = configs
        }
        
        activeConfigurationId = UserDefaults.standard.string(forKey: "dashboard_active_config")
    }
    
    // MARK: - Import/Export
    
    func exportConfiguration(id: String) -> Data? {
        guard let config = configurations.first(where: { $0.id == id }) else { return nil }
        return try? JSONEncoder().encode(config)
    }
    
    func importConfiguration(from data: Data) -> DashboardConfiguration? {
        guard let config = try? JSONDecoder().decode(DashboardConfiguration.self, from: data) else { return nil }
        
        // Generate new ID to avoid conflicts
        var newConfig = config
        newConfig.id = UUID().uuidString
        newConfig.name = "\(config.name) (Imported)"
        newConfig.createdAt = Date()
        newConfig.updatedAt = Date()
        
        configurations.append(newConfig)
        saveConfigurations()
        
        return newConfig
    }
}
