# Testing Strategy

> **Version**: 1.0  
> **Last Updated**: 2026-01-28  
> **Applies To**: All contributors to the Donna project

---

## Table of Contents

1. [Testing Philosophy](#1-testing-philosophy)
2. [Unit Testing Approach](#2-unit-testing-approach)
3. [Integration Testing](#3-integration-testing)
4. [UI Testing with XCTest](#4-ui-testing-with-xctest)
5. [Manual Testing Checklist](#5-manual-testing-checklist)

---

## 1. Testing Philosophy

### Goals

- **Confidence**: Tests should give confidence that the application works correctly
- **Regression Prevention**: Catch bugs before they reach users
- **Documentation**: Tests serve as executable documentation
- **Refactoring Safety**: Enable confident code changes

### Testing Pyramid

```
       /\
      /  \     E2E Tests (10%)
     /----\
    /      \   Integration Tests (30%)
   /--------\
  /          \ Unit Tests (60%)
 /------------\
```

### Test Priorities

1. **Critical Paths**: Process management, tool lifecycle, data persistence
2. **User-Facing Features**: UI interactions, tool switching, dashboard
3. **Edge Cases**: Error handling, timeouts, network failures
4. **Happy Path**: Standard user workflows

---

## 2. Unit Testing Approach

### Framework

- **XCTest**: Apple's native testing framework
- **Swift Testing**: Modern Swift testing (when available)

### Test Structure

```swift
import XCTest
@testable import Donna

final class ProcessManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: ProcessManager!
    private var mockTool: Tool!
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        sut = ProcessManager()
        mockTool = MockToolFactory.createValidTool()
    }
    
    override func tearDown() {
        sut.stopAll()
        sut = nil
        mockTool = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testStartToolWithValidConfigReturnsSuccess() async throws {
        // Given
        let tool = mockTool
        
        // When
        try await sut.startTool(tool)
        
        // Then
        XCTAssertTrue(sut.isRunning(tool))
        XCTAssertEqual(sut.getStatus(tool), .running)
    }
    
    func testStartToolWithInvalidPortThrowsError() async {
        // Given
        let tool = MockToolFactory.createToolWithInvalidPort()
        
        // When/Then
        do {
            try await sut.startTool(tool)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testStopToolTerminatesRunningProcess() async throws {
        // Given
        try await sut.startTool(mockTool)
        XCTAssertTrue(sut.isRunning(mockTool))
        
        // When
        sut.stopTool(mockTool)
        
        // Then
        XCTAssertFalse(sut.isRunning(mockTool))
        XCTAssertEqual(sut.getStatus(mockTool), .stopped)
    }
}
```

### Testing Patterns

#### Given-When-Then

Every test should follow the Given-When-Then structure:

- **Given**: Set up preconditions and inputs
- **When**: Execute the action being tested
- **Then**: Verify expected outcomes

#### AAA Pattern (Arrange-Act-Assert)

Alternative to Given-When-Then:

```swift
func testExample() {
    // Arrange
    let input = "test"
    
    // Act
    let result = systemUnderTest.process(input)
    
    // Assert
    XCTAssertEqual(result, "expected")
}
```

### Mocking Strategy

#### Protocol-Based Mocking

```swift
// Define protocol
protocol NetworkServiceProtocol {
    func fetchData(from url: URL) async throws -> Data
}

// Create mock
class MockNetworkService: NetworkServiceProtocol {
    var mockData: Data?
    var mockError: Error?
    var fetchDataCalled = false
    var lastURL: URL?
    
    func fetchData(from url: URL) async throws -> Data {
        fetchDataCalled = true
        lastURL = url
        
        if let error = mockError {
            throw error
        }
        
        return mockData ?? Data()
    }
}

// Usage in tests
func testFetchToolManifest() async throws {
    // Given
    let mockNetwork = MockNetworkService()
    mockNetwork.mockData = mockManifestJSON.data(using: .utf8)
    
    let sut = ToolRegistry(networkService: mockNetwork)
    
    // When
    let tool = try await sut.fetchManifest(from: testURL)
    
    // Then
    XCTAssertTrue(mockNetwork.fetchDataCalled)
    XCTAssertEqual(tool.name, "Moltbot")
}
```

### Test Data Factories

```swift
enum MockToolFactory {
    static func createValidTool() -> Tool {
        Tool(
            id: "test-tool",
            name: "Test Tool",
            description: "A test tool",
            version: "1.0.0",
            type: .webUI,
            startConfig: StartConfig(
                command: "echo",
                arguments: ["hello"],
                port: 9999,
                healthCheck: HealthCheckConfig(url: "http://localhost:9999/health")
            ),
            uiConfig: UIConfig(url: "http://localhost:9999")
        )
    }
    
    static func createToolWithInvalidPort() -> Tool {
        var tool = createValidTool()
        tool.startConfig.port = -1
        return tool
    }
    
    static func createInstalledTool() -> Tool {
        var tool = createValidTool()
        tool.isInstalled = true
        return tool
    }
}
```

### Async/Await Testing

```swift
func testAsyncOperation() async throws {
    // Test async code directly
    let result = try await sut.asyncMethod()
    XCTAssertNotNil(result)
}

func testAsyncTimeout() async {
    // Test timeout behavior
    do {
        try await sut.slowOperation()
        XCTFail("Should have timed out")
    } catch {
        XCTAssertEqual(error as? AppError, .timeout)
    }
}

func testAsyncSequence() async {
    var values: [Int] = []
    
    for try await value in sut.asyncSequence() {
        values.append(value)
    }
    
    XCTAssertEqual(values, [1, 2, 3])
}
```

### Error Testing

```swift
func testErrorHandling() {
    // Given
    let sut = createSystemWithInvalidState()
    
    // When/Then
    XCTAssertThrowsError(try sut.dangerousOperation()) { error in
        guard let appError = error as? AppError else {
            XCTFail("Wrong error type")
            return
        }
        XCTAssertEqual(appError, .invalidState)
    }
}
```

---

## 3. Integration Testing

### Scope

Integration tests verify that multiple components work together correctly:

- Process Manager + Tool Registry
- WebView + Message Handler
- Dashboard + Layout Engine
- A2A Hub + Agent Discovery

### Test Structure

```swift
final class ProcessToolIntegrationTests: XCTestCase {
    
    private var processManager: ProcessManager!
    private var toolRegistry: ToolRegistry!
    
    override func setUp() {
        super.setUp()
        processManager = ProcessManager()
        toolRegistry = ToolRegistry(processManager: processManager)
    }
    
    func testToolLifecycle() async throws {
        // Given: Register a tool
        let tool = MockToolFactory.createValidTool()
        try await toolRegistry.register(tool)
        
        // When: Activate tool
        try await toolRegistry.activateTool(tool)
        
        // Then: Process should be running
        XCTAssertTrue(processManager.isRunning(tool))
        XCTAssertEqual(toolRegistry.activeTool?.id, tool.id)
        
        // When: Deactivate tool
        await toolRegistry.deactivateTool(tool)
        
        // Then: Process should stop
        XCTAssertFalse(processManager.isRunning(tool))
    }
}
```

### External Dependencies

For integration tests with external tools:

```swift
final class ExternalToolIntegrationTests: XCTestCase {
    
    private var sut: ProcessManager!
    
    override func setUp() {
        super.setUp()
        sut = ProcessManager()
    }
    
    override func tearDown() {
        sut.stopAll()
        super.tearDown()
    }
    
    func testStartMoltbot() async throws {
        // Skip if moltbot not installed
        try XCTSkipUnless(MoltbotChecker.isInstalled(), "Moltbot not installed")
        
        // Given
        let moltbot = ToolRegistry.shared.getTool(byId: "moltbot")!
        
        // When
        try await sut.startTool(moltbot)
        
        // Then
        XCTAssertTrue(sut.isRunning(moltbot))
        
        // Cleanup
        sut.stopTool(moltbot)
    }
}
```

### Network Testing

```swift
final class NetworkIntegrationTests: XCTestCase {
    
    private var urlSession: URLSession!
    
    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        urlSession = URLSession(configuration: config)
    }
    
    func testHealthCheckEndpoint() async throws {
        // Given
        let url = URL(string: "http://localhost:18789/health")!
        
        // When
        let (_, response) = try await urlSession.data(from: url)
        
        // Then
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(httpResponse.statusCode, 200)
    }
}
```

---

## 4. UI Testing with XCTest

### Framework

- **XCUITest**: Apple's UI testing framework

### Test Structure

```swift
final class DonnaUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    func testSidebarNavigation() {
        // Given
        let sidebar = app.outlines["Sidebar"]
        
        // When: Click on a tool
        sidebar.buttons["Moltbot"].tap()
        
        // Then: WebView should load
        let webView = app.webViews["ToolWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5))
    }
    
    func testToolbarActions() {
        // Given: A tool is selected
        app.outlines["Sidebar"].buttons["Moltbot"].tap()
        
        // When: Tap toolbar button
        app.toolbars.buttons["New Chat"].tap()
        
        // Then: New chat should be created
        XCTAssertTrue(app.staticTexts["New Conversation"].exists)
    }
}
```

### Accessibility Identifiers

Always use accessibility identifiers for UI testing:

```swift
struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .accessibilityIdentifier("Sidebar")
        } detail: {
            ToolWebView()
                .accessibilityIdentifier("ToolWebView")
        }
    }
}
```

### Common UI Test Patterns

#### Waiting for Elements

```swift
func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
    return element.waitForExistence(timeout: timeout)
}

func testAsyncLoading() {
    let loadingIndicator = app.activityIndicators["Loading"]
    let content = app.staticTexts["Content"]
    
    // Wait for loading to complete
    XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 10))
    
    // Then content should appear
    XCTAssertTrue(content.exists)
}
```

#### Interacting with WebViews

```swift
func testWebViewInteraction() {
    let webView = app.webViews["ToolWebView"]
    
    // Wait for webView to load
    XCTAssertTrue(webView.waitForExistence(timeout: 5))
    
    // Execute JavaScript
    let result = webView.evaluateJavaScript("document.title")
    XCTAssertEqual(result as? String, "Expected Title")
}
```

#### Testing Different Screen Sizes

```swift
func testResponsiveLayout() {
    // Test compact mode
    app.windows.firstMatch.resize(width: 800, height: 600)
    XCTAssertFalse(app.splitGroups["Sidebar"].exists)
    
    // Test expanded mode
    app.windows.firstMatch.resize(width: 1400, height: 900)
    XCTAssertTrue(app.splitGroups["Sidebar"].exists)
}
```

### UI Test Data

Use launch arguments to configure test state:

```swift
// In test
app.launchArguments = [
    "--uitesting",
    "--mock-tools",
    "--skip-onboarding"
]
app.launch()

// In app
if CommandLine.arguments.contains("--uitesting") {
    // Configure for testing
}
```

---

## 5. Manual Testing Checklist

### Pre-Release Checklist

#### Core Functionality

- [ ] App launches without errors
- [ ] Sidebar displays all installed tools
- [ ] Tool selection loads correct WebView
- [ ] Process manager starts/stops tools correctly
- [ ] Settings persist across app restarts

#### Adaptive UI

- [ ] Toolbar updates for each tool
- [ ] Toolbar actions work correctly
- [ ] Window title updates appropriately
- [ ] Sidebar items reflect tool state

#### Dashboard

- [ ] Multiple tools can be displayed
- [ ] Layout switching works
- [ ] Drag and drop functions correctly
- [ ] Widgets display and update
- [ ] Layouts save and restore

#### A2A Protocol

- [ ] Agent discovery works
- [ ] Agent cards display correctly
- [ ] Tasks can be sent between agents
- [ ] Network view updates in real-time

#### Error Handling

- [ ] Tool startup failures show appropriate error
- [ ] Network errors are handled gracefully
- [ ] Invalid manifests are rejected with clear message
- [ ] App recovers from crashes

#### Performance

- [ ] App launches in < 3 seconds
- [ ] Tool switching is responsive (< 1 second)
- [ ] Dashboard with 4+ tools performs well
- [ ] Memory usage remains stable

#### Accessibility

- [ ] VoiceOver works with all UI elements
- [ ] Keyboard navigation is complete
- [ ] Color contrast meets WCAG guidelines
- [ ] Dynamic type is supported

### Platform-Specific Testing

#### macOS 14 (Sonoma)

- [ ] Test on Intel Mac
- [ ] Test on Apple Silicon Mac
- [ ] Test with different display scales
- [ ] Test with Stage Manager

#### macOS 15 (Sequoia) - Future

- [ ] Compatibility testing
- [ ] New feature integration

### Regression Testing

Before each release, verify:

- [ ] All previously fixed bugs remain fixed
- [ ] No new crashes in crash reporting
- [ ] Performance hasn't degraded
- [ ] Existing user workflows still work

### Beta Testing

For beta releases:

- [ ] Test with real user tools (Moltbot, Vibe Kanban)
- [ ] Test with various network conditions
- [ ] Test with different macOS configurations
- [ ] Collect and analyze feedback

---

## Test Execution

### Running Tests

```bash
# All tests
xcodebuild test -scheme Donna -destination 'platform=macOS'

# Unit tests only
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaTests

# Integration tests
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaIntegrationTests

# UI tests
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaUITests

# Specific test class
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaTests/ProcessManagerTests

# Specific test method
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaTests/ProcessManagerTests/testStartTool
```

### Continuous Integration

Tests run automatically on:

- Every Pull Request
- Every merge to `main`
- Nightly builds
- Release builds

### Test Reporting

- **Code Coverage**: Generated with `xcodebuild` + `xccov`
- **Test Results**: Published to GitHub Actions
- **Performance Metrics**: Tracked over time

---

## Best Practices

1. **Write tests first** when possible (TDD)
2. **Keep tests fast** - slow tests won't be run
3. **Make tests independent** - no shared state
4. **Use descriptive names** - test names are documentation
5. **One assertion per test** when possible
6. **Test edge cases** - null inputs, empty arrays, extreme values
7. **Refactor tests** - they deserve maintenance too

---

*This document should be updated as testing practices evolve.*