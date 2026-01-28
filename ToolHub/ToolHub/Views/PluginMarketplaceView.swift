import SwiftUI

struct PluginMarketplaceView: View {
    @StateObject private var marketplaceManager = PluginMarketplaceManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: PluginCategory?
    @State private var showingInstallConfirmation = false
    @State private var selectedPlugin: Plugin?
    
    var filteredPlugins: [Plugin] {
        marketplaceManager.plugins.filter { plugin in
            let matchesSearch = searchText.isEmpty ||
                plugin.name.localizedCaseInsensitiveContains(searchText) ||
                plugin.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || plugin.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search plugins...", text: $searchText)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag(nil as PluginCategory?)
                    ForEach(PluginCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category as PluginCategory?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
            }
            .padding()
            
            Divider()
            
            // Plugin Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 300), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredPlugins) { plugin in
                        PluginCard(
                            plugin: plugin,
                            isInstalled: marketplaceManager.isInstalled(plugin.id),
                            onInstall: {
                                selectedPlugin = plugin
                                showingInstallConfirmation = true
                            },
                            onUninstall: {
                                Task {
                                    await marketplaceManager.uninstallPlugin(plugin)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .alert("Install Plugin?", isPresented: $showingInstallConfirmation, presenting: selectedPlugin) { plugin in
            Button("Cancel", role: .cancel) {}
            Button("Install") {
                Task {
                    await marketplaceManager.installPlugin(plugin)
                }
            }
        } message: { plugin in
            Text("Are you sure you want to install '\(plugin.name)' v\(plugin.version)?")
        }
        .task {
            await marketplaceManager.loadPlugins()
        }
    }
}

// MARK: - Plugin Card

struct PluginCard: View {
    let plugin: Plugin
    let isInstalled: Bool
    let onInstall: () -> Void
    let onUninstall: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: plugin.icon)
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plugin.name)
                        .font(.headline)
                    
                    Text("v\(plugin.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(plugin.rating) ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        
                        Text("(\(plugin.downloads))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isInstalled {
                    Button {
                        onUninstall()
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button {
                        onInstall()
                    } label: {
                        Label("Install", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Divider()
            
            // Description
            Text(plugin.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Tags
            HStack {
                ForEach(plugin.tags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(plugin.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
            }
            
            // Author
            HStack {
                Image(systemName: "person.circle")
                Text(plugin.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let lastUpdated = plugin.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Plugin Marketplace Manager

@MainActor
class PluginMarketplaceManager: ObservableObject {
    static let shared = PluginMarketplaceManager()
    
    @Published var plugins: [Plugin] = []
    @Published var installedPlugins: [String: InstalledPlugin] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let registry = ToolRegistry.shared
    private let preferences = UserPreferences.shared
    
    private init() {
        loadInstalledPlugins()
    }
    
    func loadPlugins() async {
        isLoading = true
        
        // In a real implementation, this would fetch from a server
        // For now, we'll use mock data
        plugins = mockPlugins
        
        isLoading = false
    }
    
    func installPlugin(_ plugin: Plugin) async {
        guard !isInstalled(plugin.id) else {
            errorMessage = "Plugin is already installed"
            return
        }
        
        do {
            // Download and install the plugin
            let installedPlugin = InstalledPlugin(
                id: plugin.id,
                version: plugin.version,
                installDate: Date(),
                manifest: plugin.manifest
            )
            
            // Save to UserDefaults
            installedPlugins[plugin.id] = installedPlugin
            saveInstalledPlugins()
            
            // If it's a tool plugin, add to registry
            if let manifest = plugin.manifest {
                try registry.saveManifest(manifest)
            }
            
        } catch {
            errorMessage = "Failed to install plugin: \(error.localizedDescription)"
        }
    }
    
    func uninstallPlugin(_ plugin: Plugin) async {
        installedPlugins.removeValue(forKey: plugin.id)
        saveInstalledPlugins()
        
        // Remove from registry if it's a tool
        try? registry.deleteManifest(id: plugin.id)
    }
    
    func isInstalled(_ pluginId: String) -> Bool {
        installedPlugins[pluginId] != nil
    }
    
    private func loadInstalledPlugins() {
        if let data = UserDefaults.standard.data(forKey: "installed_plugins"),
           let plugins = try? JSONDecoder().decode([String: InstalledPlugin].self, from: data) {
            installedPlugins = plugins
        }
    }
    
    private func saveInstalledPlugins() {
        if let data = try? JSONEncoder().encode(installedPlugins) {
            UserDefaults.standard.set(data, forKey: "installed_plugins")
        }
    }
    
    // MARK: - Mock Data
    
    private var mockPlugins: [Plugin] {
        [
            Plugin(
                id: "mermaid-diagram",
                name: "Mermaid Diagram Viewer",
                version: "1.2.0",
                description: "View and edit Mermaid diagrams with live preview. Supports flowcharts, sequence diagrams, class diagrams, and more.",
                author: "ToolHub Team",
                icon: "diagram",
                category: .productivity,
                tags: ["diagrams", "visualization", "mermaid"],
                rating: 4.5,
                downloads: 1250,
                lastUpdated: Date().addingTimeInterval(-86400 * 7),
                manifest: nil
            ),
            Plugin(
                id: "json-formatter",
                name: "JSON Formatter Pro",
                version: "2.1.0",
                description: "Advanced JSON formatting, validation, and transformation tool with syntax highlighting and tree view.",
                author: "DevTools Inc",
                icon: "curlybraces",
                category: .developer,
                tags: ["json", "formatter", "developer"],
                rating: 4.8,
                downloads: 3420,
                lastUpdated: Date().addingTimeInterval(-86400 * 3),
                manifest: nil
            ),
            Plugin(
                id: "markdown-editor",
                name: "Markdown Studio",
                version: "1.5.0",
                description: "Full-featured markdown editor with live preview, syntax highlighting, and export options.",
                author: "WriteBetter",
                icon: "doc.text",
                category: .productivity,
                tags: ["markdown", "editor", "writing"],
                rating: 4.3,
                downloads: 2100,
                lastUpdated: Date().addingTimeInterval(-86400 * 14),
                manifest: nil
            ),
            Plugin(
                id: "api-tester",
                name: "API Tester",
                version: "3.0.0",
                description: "Test REST APIs with a beautiful interface. Supports authentication, headers, and response formatting.",
                author: "API Tools",
                icon: "network",
                category: .developer,
                tags: ["api", "rest", "testing"],
                rating: 4.6,
                downloads: 4560,
                lastUpdated: Date().addingTimeInterval(-86400 * 2),
                manifest: nil
            ),
            Plugin(
                id: "color-picker",
                name: "Color Picker Pro",
                version: "1.0.5",
                description: "Advanced color picker with palette generation, contrast checker, and export to various formats.",
                author: "DesignTools",
                icon: "eyedropper",
                category: .design,
                tags: ["color", "design", "picker"],
                rating: 4.2,
                downloads: 890,
                lastUpdated: Date().addingTimeInterval(-86400 * 30),
                manifest: nil
            ),
            Plugin(
                id: "regex-tester",
                name: "Regex Tester",
                version: "2.2.0",
                description: "Test and debug regular expressions with real-time matching and explanation.",
                author: "DevTools Inc",
                icon: "text.magnifyingglass",
                category: .developer,
                tags: ["regex", "developer", "testing"],
                rating: 4.7,
                downloads: 1890,
                lastUpdated: Date().addingTimeInterval(-86400 * 5),
                manifest: nil
            )
        ]
    }
}

// MARK: - Plugin Models

struct Plugin: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let version: String
    let description: String
    let author: String
    let icon: String
    let category: PluginCategory
    let tags: [String]
    let rating: Double
    let downloads: Int
    let lastUpdated: Date?
    let manifest: ToolManifest?
}

struct InstalledPlugin: Codable {
    let id: String
    let version: String
    let installDate: Date
    let manifest: ToolManifest?
}

enum PluginCategory: String, Codable, CaseIterable {
    case productivity
    case developer
    case design
    case utility
    case integration
    
    var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .developer: return "Developer"
        case .design: return "Design"
        case .utility: return "Utility"
        case .integration: return "Integration"
        }
    }
}
