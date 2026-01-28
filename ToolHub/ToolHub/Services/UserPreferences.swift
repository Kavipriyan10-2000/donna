import Foundation
import Combine

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Keys
    private enum Keys {
        static let installedTools = "installedTools"
        static let selectedToolId = "selectedToolId"
        static let currentLayout = "currentLayout"
        static let sidebarCollapsed = "sidebarCollapsed"
        static let stopToolsOnQuit = "stopToolsOnQuit"
        static let autoStartTools = "autoStartTools"
        static let showStatusBar = "showStatusBar"
    }
    
    // MARK: - Published Properties
    
    @Published var installedTools: [Tool] = [] {
        didSet { saveInstalledTools() }
    }
    
    @Published var selectedToolId: String? {
        didSet { defaults.set(selectedToolId, forKey: Keys.selectedToolId) }
    }
    
    @Published var currentLayout: LayoutType = .single {
        didSet { defaults.set(currentLayout.rawValue, forKey: Keys.currentLayout) }
    }
    
    @Published var sidebarCollapsed: Bool = false {
        didSet { defaults.set(sidebarCollapsed, forKey: Keys.sidebarCollapsed) }
    }
    
    @Published var stopToolsOnQuit: Bool = true {
        didSet { defaults.set(stopToolsOnQuit, forKey: Keys.stopToolsOnQuit) }
    }
    
    @Published var autoStartTools: Bool = true {
        didSet { defaults.set(autoStartTools, forKey: Keys.autoStartTools) }
    }
    
    @Published var showStatusBar: Bool = true {
        didSet { defaults.set(showStatusBar, forKey: Keys.showStatusBar) }
    }
    
    // MARK: - Initialization
    
    private init() {
        loadPreferences()
    }
    
    // MARK: - Loading
    
    private func loadPreferences() {
        // Load installed tools
        if let data = defaults.data(forKey: Keys.installedTools),
           let tools = try? decoder.decode([Tool].self, from: data) {
            self.installedTools = tools
        }
        
        // Load selected tool
        self.selectedToolId = defaults.string(forKey: Keys.selectedToolId)
        
        // Load layout
        if let layoutString = defaults.string(forKey: Keys.currentLayout),
           let layout = LayoutType(rawValue: layoutString) {
            self.currentLayout = layout
        }
        
        // Load booleans
        self.sidebarCollapsed = defaults.bool(forKey: Keys.sidebarCollapsed)
        self.stopToolsOnQuit = defaults.object(forKey: Keys.stopToolsOnQuit) as? Bool ?? true
        self.autoStartTools = defaults.object(forKey: Keys.autoStartTools) as? Bool ?? true
        self.showStatusBar = defaults.object(forKey: Keys.showStatusBar) as? Bool ?? true
    }
    
    // MARK: - Saving
    
    private func saveInstalledTools() {
        if let data = try? encoder.encode(installedTools) {
            defaults.set(data, forKey: Keys.installedTools)
        }
    }
    
    // MARK: - Convenience Methods
    
    var installedToolIds: [String] {
        installedTools.map { $0.id }
    }
    
    func isToolInstalled(_ toolId: String) -> Bool {
        installedTools.contains { $0.id == toolId }
    }
    
    func getTool(_ toolId: String) -> Tool? {
        installedTools.first { $0.id == toolId }
    }
    
    func addTool(_ tool: Tool) {
        if !isToolInstalled(tool.id) {
            installedTools.append(tool)
        }
    }
    
    func removeTool(_ toolId: String) {
        installedTools.removeAll { $0.id == toolId }
        if selectedToolId == toolId {
            selectedToolId = nil
        }
    }
    
    func updateTool(_ tool: Tool) {
        if let index = installedTools.firstIndex(where: { $0.id == tool.id }) {
            installedTools[index] = tool
        }
    }
    
    // MARK: - Reset
    
    func resetAll() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        
        installedTools = []
        selectedToolId = nil
        currentLayout = .single
        sidebarCollapsed = false
        stopToolsOnQuit = true
        autoStartTools = true
        showStatusBar = true
    }
}
