import XCTest
@testable import ToolHub

final class ToolHubTests: XCTestCase {
    
    // MARK: - Tool Manifest Tests
    
    func testToolManifestParsing() throws {
        let json = """
        {
            "id": "test-tool",
            "name": "Test Tool",
            "version": "1.0.0",
            "description": "A test tool",
            "install": {
                "command": "npm install -g test-tool",
                "check": "which test-tool"
            },
            "start": {
                "command": "test-tool server",
                "port": 8080,
                "health_check": "http://localhost:8080/health"
            },
            "ui": {
                "url": "http://localhost:8080"
            }
        }
        """.data(using: .utf8)!
        
        let manifest = try JSONDecoder().decode(ToolManifest.self, from: json)
        
        XCTAssertEqual(manifest.id, "test-tool")
        XCTAssertEqual(manifest.name, "Test Tool")
        XCTAssertEqual(manifest.version, "1.0.0")
        XCTAssertEqual(manifest.start.port, 8080)
    }
    
    func testToolManifestValidation() {
        let registry = ToolRegistry.shared
        
        // Valid manifest
        let validManifest = ToolManifest(
            id: "valid-tool",
            name: "Valid Tool",
            version: "1.0.0",
            description: "A valid tool",
            icon: nil,
            install: InstallConfig(command: "npm install -g valid", check: "which valid"),
            start: StartConfig(command: "valid server", port: 8080, portRange: nil, healthCheck: "http://localhost:8080/health", workingDirectory: nil, environment: nil),
            ui: UIConfig(url: "http://localhost:8080", toolbar: nil, widgets: nil, sidebar: nil),
            a2a: nil
        )
        
        XCTAssertNoThrow(try registry.validateManifest(validManifest))
        
        // Invalid manifest - empty ID
        let invalidManifest = ToolManifest(
            id: "",
            name: "Invalid",
            version: "1.0.0",
            description: "Invalid",
            icon: nil,
            install: InstallConfig(command: "cmd", check: "check"),
            start: StartConfig(command: "cmd", port: 8080, portRange: nil, healthCheck: "http://localhost:8080/health", workingDirectory: nil, environment: nil),
            ui: UIConfig(url: "http://localhost:8080", toolbar: nil, widgets: nil, sidebar: nil),
            a2a: nil
        )
        
        XCTAssertThrowsError(try registry.validateManifest(invalidManifest))
    }
    
    // MARK: - Port Finder Tests
    
    func testPortAvailability() {
        let portFinder = PortFinder.shared
        
        // Port 1 should not be available (privileged)
        XCTAssertFalse(portFinder.isPortAvailable(1))
        
        // Find an available port
        if let port = portFinder.findAvailablePort(min: 50000, max: 50100) {
            XCTAssertTrue(portFinder.isPortAvailable(port))
            portFinder.releasePort(port)
        }
    }
    
    func testPortReservation() {
        let portFinder = PortFinder.shared
        
        let port = 55555
        portFinder.reservePort(port)
        
        // Reserved port should not be returned as available
        let availablePort = portFinder.findAvailablePort(min: 55550, max: 55560)
        XCTAssertNotEqual(availablePort, port)
        
        portFinder.releasePort(port)
    }
    
    // MARK: - Health Checker Tests
    
    func testHealthCheckFailure() async {
        let healthChecker = HealthChecker.shared
        
        // Test with non-existent server
        let url = URL(string: "http://localhost:59999/health")!
        let isHealthy = await healthChecker.checkHealth(url: url)
        
        XCTAssertFalse(isHealthy)
    }
    
    // MARK: - User Preferences Tests
    
    func testUserPreferences() {
        let prefs = UserPreferences.shared
        
        // Test initial state
        XCTAssertFalse(prefs.sidebarCollapsed)
        XCTAssertTrue(prefs.stopToolsOnQuit)
        
        // Test tool management
        let testManifest = ToolManifest(
            id: "test-prefs",
            name: "Test",
            version: "1.0.0",
            description: "Test",
            icon: nil,
            install: InstallConfig(command: "cmd", check: "check"),
            start: StartConfig(command: "cmd", port: 8080, portRange: nil, healthCheck: "http://localhost:8080/health", workingDirectory: nil, environment: nil),
            ui: UIConfig(url: "http://localhost:8080", toolbar: nil, widgets: nil, sidebar: nil),
            a2a: nil
        )
        
        let tool = Tool(manifest: testManifest)
        prefs.addTool(tool)
        
        XCTAssertTrue(prefs.isToolInstalled("test-prefs"))
        
        prefs.removeTool("test-prefs")
        XCTAssertFalse(prefs.isToolInstalled("test-prefs"))
    }
    
    // MARK: - Tool Model Tests
    
    func testToolModel() {
        let manifest = ToolManifest(
            id: "test-model",
            name: "Test Model",
            version: "1.0.0",
            description: "Test",
            icon: "gear",
            install: InstallConfig(command: "cmd", check: "check"),
            start: StartConfig(command: "cmd", port: 9000, portRange: nil, healthCheck: "http://localhost:9000/health", workingDirectory: nil, environment: nil),
            ui: UIConfig(url: "http://localhost:9000", toolbar: nil, widgets: nil, sidebar: nil),
            a2a: nil
        )
        
        let tool = Tool(manifest: manifest)
        
        XCTAssertEqual(tool.id, "test-model")
        XCTAssertEqual(tool.displayName, "Test Model")
        XCTAssertEqual(tool.icon, "gear")
        XCTAssertEqual(tool.localURL?.absoluteString, "http://localhost:9000")
        XCTAssertFalse(tool.isInstalled)
    }
    
    func testProcessStatus() {
        XCTAssertEqual(ProcessStatus.running.displayName, "Running")
        XCTAssertEqual(ProcessStatus.stopped.displayName, "Stopped")
        XCTAssertEqual(ProcessStatus.error.displayName, "Error")
        XCTAssertEqual(ProcessStatus.crashed.displayName, "Crashed")
        XCTAssertEqual(ProcessStatus.starting.displayName, "Starting")
    }
    
    func testLayoutType() {
        XCTAssertEqual(LayoutType.single.displayName, "Single")
        XCTAssertEqual(LayoutType.splitVertical.displayName, "Split Vertical")
        XCTAssertEqual(LayoutType.tabs.displayName, "Tabs")
        XCTAssertEqual(LayoutType.dashboard.displayName, "Dashboard")
    }
}
