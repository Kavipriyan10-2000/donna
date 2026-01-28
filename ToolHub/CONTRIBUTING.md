# Contributing to ToolHub

Thank you for your interest in contributing to ToolHub! This document provides guidelines and best practices for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Git Branching Strategy](#git-branching-strategy)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Code Style](#code-style)
- [Documentation](#documentation)

## Code of Conduct

This project and everyone participating in it is governed by our commitment to:
- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Respect different viewpoints and experiences

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/donna.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Run tests
6. Commit and push
7. Create a Pull Request

## Development Workflow

### Prerequisites

- macOS 13.0+ (Ventura)
- Xcode 15.0+
- Swift 5.9+
- Git

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/Kavipriyan10-2000/donna.git
cd donna/ToolHub

# Open in Xcode
open ToolHub.xcodeproj
```

### Running Tests

```bash
# Run all tests
xcodebuild test -project ToolHub.xcodeproj -scheme ToolHub -destination 'platform=macOS'
```

## Git Branching Strategy

We follow the **Git Flow** branching model:

### Branch Types

- **`main`** - Production-ready code
- **`develop`** - Integration branch for features
- **`feature/*`** - New features or enhancements
- **`bugfix/*`** - Bug fixes
- **`hotfix/*`** - Critical production fixes
- **`release/*`** - Release preparation

### Naming Conventions

```
feature/adaptive-toolbar
feature/plugin-marketplace
bugfix/memory-leak
hotfix/crash-on-startup
release/v1.1.0
```

### Workflow

1. **Create a feature branch from `develop`**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature
   ```

2. **Make commits with clear messages**:
   ```bash
   git commit -m "Add adaptive toolbar system
   
   - Implement ToolbarManager for dynamic toolbar items
   - Add JavaScript bridge for webview communication
   - Support button, dropdown, search, and toggle types
   - Add keyboard shortcuts"
   ```

3. **Push and create Pull Request**:
   ```bash
   git push origin feature/your-feature
   ```

4. **Merge only after review and tests pass**

## Pull Request Process

### Before Creating a PR

- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] New tests added for new functionality
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] CHANGELOG.md updated

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] CHANGELOG.md updated

## Screenshots (if applicable)
Add screenshots for UI changes
```

### Review Process

1. **Automated Checks**:
   - CI/CD pipeline runs tests
   - Code coverage reports generated
   - Linting checks pass

2. **Code Review**:
   - At least 1 approval required
   - All comments resolved
   - No unresolved conversations

3. **Merge Requirements**:
   - Branch is up to date with `develop`
   - All checks pass
   - Approved by reviewer

## Testing Requirements

### Unit Tests

All new functionality must include unit tests:

```swift
func testToolbarItemCreation() {
    let item = ToolbarItem(
        id: "test",
        type: .button,
        label: "Test",
        icon: "star",
        action: "testAction",
        options: nil,
        shortcut: nil,
        isEnabled: true
    )
    
    XCTAssertEqual(item.type, .button)
    XCTAssertTrue(item.isEnabled)
}
```

### Integration Tests

Test component interactions:

```swift
func testPluginInstallation() async {
    let plugin = createTestPlugin()
    
    // Install
    await marketplaceManager.installPlugin(plugin)
    
    // Verify
    XCTAssertTrue(marketplaceManager.isInstalled(plugin.id))
}
```

### UI Tests

For UI changes, add XCUITest tests:

```swift
func testToolbarAppears() {
    let app = XCUIApplication()
    app.launch()
    
    let toolbar = app.toolbars["AdaptiveToolbar"]
    XCTAssertTrue(toolbar.exists)
}
```

### Test Coverage

- Minimum 70% code coverage
- Critical paths must have 100% coverage
- Use code coverage reports in PRs

## Code Style

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):

```swift
// Good
func loadToolbar(for tool: Tool) { }

// Bad
func loadToolbar(tool: Tool) { }
```

### Formatting

- Use 4 spaces for indentation
- Maximum line length: 120 characters
- Use trailing commas in multi-line arrays/dictionaries
- Group imports alphabetically

### Naming Conventions

```swift
// Types: UpperCamelCase
struct ToolbarItem { }
class PluginManager { }

// Functions/Variables: lowerCamelCase
func executeAction() { }
var isLoading: Bool

// Constants: lowerCamelCase
let defaultTimeout = 30.0

// Enums: UpperCamelCase for type, lowerCamelCase for cases
enum ToolbarItemType {
    case button
    case dropdown
}
```

### Documentation

Document all public APIs:

```swift
/// Manages the adaptive toolbar for tools
/// 
/// The ToolbarManager loads toolbar configurations from tool manifests
/// and provides a JavaScript bridge for webview communication.
@MainActor
class ToolbarManager: ObservableObject {
    /// Loads toolbar configuration for a specific tool
    /// - Parameters:
    ///   - tool: The tool to load toolbar for
    ///   - webView: The WKWebView instance for JavaScript communication
    func loadToolbar(for tool: Tool, webView: WKWebView) { }
}
```

## Documentation

### Required Documentation

- **README.md** - Project overview and setup
- **CHANGELOG.md** - Version history
- **TESTING.md** - Testing procedures
- **API Documentation** - Public API docs

### Documentation Updates

Update documentation when:
- Adding new features
- Changing existing behavior
- Deprecating functionality
- Fixing bugs that affect users

### Changelog Format

```markdown
## [1.1.0] - 2026-01-28

### Added
- Adaptive toolbar system with JavaScript bridge
- Plugin marketplace with 6 plugins
- Dashboard widgets with customizable layouts

### Changed
- Improved process management with auto-restart
- Enhanced error handling

### Fixed
- Fixed memory leak in WKWebView
- Resolved port conflict issues
```

## Questions?

- Open an issue for bugs or feature requests
- Join discussions for questions
- Check existing documentation first

Thank you for contributing to ToolHub!
