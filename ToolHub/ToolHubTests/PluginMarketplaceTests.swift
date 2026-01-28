import XCTest
@testable import ToolHub

final class PluginMarketplaceTests: XCTestCase {
    
    var marketplaceManager: PluginMarketplaceManager!
    
    override func setUp() {
        super.setUp()
        marketplaceManager = PluginMarketplaceManager.shared
    }
    
    override func tearDown() {
        // Clean up installed plugins
        for (id, _) in marketplaceManager.installedPlugins {
            marketplaceManager.installedPlugins.removeValue(forKey: id)
        }
        marketplaceManager.saveInstalledPlugins()
        super.tearDown()
    }
    
    func testPluginModel() {
        let plugin = Plugin(
            id: "test-plugin",
            name: "Test Plugin",
            version: "1.0.0",
            description: "A test plugin",
            author: "Test Author",
            icon: "star",
            category: .productivity,
            tags: ["test", "plugin"],
            rating: 4.5,
            downloads: 100,
            lastUpdated: Date(),
            manifest: nil
        )
        
        XCTAssertEqual(plugin.id, "test-plugin")
        XCTAssertEqual(plugin.name, "Test Plugin")
        XCTAssertEqual(plugin.version, "1.0.0")
        XCTAssertEqual(plugin.category, .productivity)
        XCTAssertEqual(plugin.rating, 4.5)
    }
    
    func testPluginCategoryDisplayName() {
        XCTAssertEqual(PluginCategory.productivity.displayName, "Productivity")
        XCTAssertEqual(PluginCategory.developer.displayName, "Developer")
        XCTAssertEqual(PluginCategory.design.displayName, "Design")
        XCTAssertEqual(PluginCategory.utility.displayName, "Utility")
        XCTAssertEqual(PluginCategory.integration.displayName, "Integration")
    }
    
    func testPluginInstallation() async {
        let plugin = Plugin(
            id: "test-install",
            name: "Test Install",
            version: "1.0.0",
            description: "Test",
            author: "Test",
            icon: "star",
            category: .utility,
            tags: [],
            rating: 5.0,
            downloads: 10,
            lastUpdated: nil,
            manifest: nil
        )
        
        // Initially not installed
        XCTAssertFalse(marketplaceManager.isInstalled(plugin.id))
        
        // Install
        await marketplaceManager.installPlugin(plugin)
        
        // Should be installed
        XCTAssertTrue(marketplaceManager.isInstalled(plugin.id))
        XCTAssertEqual(marketplaceManager.installedPlugins[plugin.id]?.version, "1.0.0")
    }
    
    func testPluginUninstallation() async {
        let plugin = Plugin(
            id: "test-uninstall",
            name: "Test Uninstall",
            version: "1.0.0",
            description: "Test",
            author: "Test",
            icon: "star",
            category: .utility,
            tags: [],
            rating: 5.0,
            downloads: 10,
            lastUpdated: nil,
            manifest: nil
        )
        
        // Install first
        await marketplaceManager.installPlugin(plugin)
        XCTAssertTrue(marketplaceManager.isInstalled(plugin.id))
        
        // Uninstall
        await marketplaceManager.uninstallPlugin(plugin)
        
        // Should not be installed
        XCTAssertFalse(marketplaceManager.isInstalled(plugin.id))
    }
    
    func testInstalledPluginPersistence() async {
        let plugin = Plugin(
            id: "test-persist",
            name: "Test Persistence",
            version: "2.0.0",
            description: "Test",
            author: "Test",
            icon: "star",
            category: .developer,
            tags: [],
            rating: 4.0,
            downloads: 50,
            lastUpdated: Date(),
            manifest: nil
        )
        
        // Install
        await marketplaceManager.installPlugin(plugin)
        
        // Save
        marketplaceManager.saveInstalledPlugins()
        
        // Clear from memory
        marketplaceManager.installedPlugins.removeAll()
        
        // Load
        marketplaceManager.loadInstalledPlugins()
        
        // Should still be installed
        XCTAssertTrue(marketplaceManager.isInstalled(plugin.id))
        XCTAssertEqual(marketplaceManager.installedPlugins[plugin.id]?.version, "2.0.0")
    }
}
