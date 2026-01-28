# Contributing to Donna

Thank you for your interest in contributing to Donna! This document provides guidelines and instructions for contributing to the project.

> **Version**: 1.0  
> **Last Updated**: 2026-01-28

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Environment Setup](#development-environment-setup)
3. [How to Create a Branch](#how-to-create-a-branch)
4. [How to Submit a PR](#how-to-submit-a-pr)
5. [Code Style Guide](#code-style-guide)
6. [Commit Message Guidelines](#commit-message-guidelines)
7. [Testing Guidelines](#testing-guidelines)
8. [Reporting Issues](#reporting-issues)
9. [Community Guidelines](#community-guidelines)

---

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **macOS 14.0+** (Sonoma or later)
- **Xcode 15.0+** (available from Mac App Store or [Apple Developer](https://developer.apple.com/xcode/))
- **Swift 5.9+** (included with Xcode)
- **Git** (for version control)
- **GitHub account** (for submitting PRs)

### Repository Structure

```
donna/
├── docs/                    # Documentation
│   ├── ARCHITECTURE.md     # Technical architecture
│   ├── WORKFLOW.md         # Git workflow
│   └── TESTING.md          # Testing strategy
├── .github/                # GitHub templates
│   ├── ISSUE_TEMPLATE/     # Issue templates
│   └── PULL_REQUEST_TEMPLATE.md
├── Donna/                  # Main app source (to be created)
├── DonnaTests/             # Unit tests (to be created)
├── DonnaUITests/           # UI tests (to be created)
├── README.md               # Project overview
├── LICENSE                 # MIT License
└── CONTRIBUTING.md         # This file
```

---

## Development Environment Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub first, then clone your fork
git clone https://github.com/YOUR_USERNAME/donna.git
cd donna

# Add upstream remote
git remote add upstream https://github.com/Kavipriyan10-2000/donna.git
```

### 2. Verify Setup

```bash
# Check Swift version
swift --version
# Should be 5.9 or later

# Check Xcode version
xcodebuild -version
# Should be 15.0 or later
```

### 3. Open in Xcode

```bash
# When the Xcode project exists
open Donna.xcodeproj

# Or if using Xcode 15+ with Swift Packages
open Donna.xcworkspace
```

### 4. Build the Project

In Xcode:
1. Select the `Donna` scheme
2. Choose your Mac as the destination
3. Press `Cmd+B` to build

Or via command line:
```bash
xcodebuild -scheme Donna -destination 'platform=macOS' build
```

### 5. Run Tests

```bash
# Run all tests
xcodebuild test -scheme Donna -destination 'platform=macOS'

# Run specific test target
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaTests
```

---

## How to Create a Branch

We follow the [Git Flow](https://docs.github.com/en/get-started/quickstart/github-flow) workflow.

### 1. Update Your Local Main

```bash
# Switch to main branch
git checkout main

# Fetch latest changes from upstream
git fetch upstream

# Merge upstream changes into your local main
git merge upstream/main

# Push to your fork (optional)
git push origin main
```

### 2. Create a Feature Branch

```bash
# Create and switch to new branch
git checkout -b feature/your-feature-name

# Example:
git checkout -b feature/adaptive-toolbar
```

### Branch Naming Conventions

See [docs/WORKFLOW.md](docs/WORKFLOW.md) for detailed naming conventions.

Quick reference:
- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Critical fixes
- `docs/description` - Documentation
- `refactor/description` - Code refactoring
- `test/description` - Test additions

### 3. Make Your Changes

- Write clean, well-documented code
- Follow the [Code Style Guide](#code-style-guide)
- Add tests for new functionality
- Update documentation as needed

### 4. Commit Your Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat(toolbar): add dynamic toolbar generation

Implement toolbar builder that creates native macOS toolbar
items from tool manifest definitions."
```

See [Commit Message Guidelines](#commit-message-guidelines) for details.

### 5. Push Your Branch

```bash
# Push to your fork
git push -u origin feature/your-feature-name
```

---

## How to Submit a PR

### 1. Before Submitting

- [ ] All tests pass locally
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Self-review completed
- [ ] Branch is up to date with `main`

### 2. Create Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Fill in the PR template
4. Link related issues: `Closes #123`
5. Request review from maintainers

### 3. PR Title Format

```
[<TYPE>] <Short Description>
```

Examples:
- `[FEATURE] Implement adaptive toolbar system`
- `[BUGFIX] Fix memory leak in WKWebView container`
- `[DOCS] Add testing strategy documentation`

### 4. PR Description

Use the template provided. Include:
- What changed
- Why it changed
- How to test it
- Screenshots (if UI changes)

### 5. Address Review Feedback

- Respond to all comments
- Make requested changes
- Push updates to the same branch
- Re-request review when ready

### 6. Merge

Once approved:
1. Ensure CI passes
2. Squash and merge (maintainers will do this)
3. Delete your branch after merge

---

## Code Style Guide

We follow standard Swift conventions with some project-specific rules.

### General Principles

- **Clarity over brevity**: Code should be self-documenting
- **Consistency**: Match the existing code style
- **Modern Swift**: Use current Swift features appropriately

### Formatting

#### Indentation

- Use **4 spaces** for indentation (not tabs)
- Xcode setting: `Indentation > Tab width: 4, Indent width: 4`

#### Line Length

- Maximum **120 characters** per line
- Break long lines at logical points

#### Spacing

```swift
// Good
func example() {
    let x = 5
    let y = 10
    return x + y
}

// Bad - inconsistent spacing
func example(){
    let x=5
    let y =10
    return x+y
}
```

### Naming Conventions

#### Types (Classes, Structs, Enums, Protocols)

- Use **PascalCase**
- Be descriptive and clear

```swift
class ToolManager { }
struct ToolConfiguration { }
enum ProcessStatus { }
protocol ToolRegistryProtocol { }
```

#### Variables and Functions

- Use **camelCase**
- Verbose is better than cryptic

```swift
let activeTool: Tool
var isLoading: Bool
func startTool(_ tool: Tool) async throws { }
```

#### Boolean Properties

- Use `is`, `has`, `should` prefixes

```swift
var isRunning: Bool
var hasError: Bool
var shouldRefresh: Bool
```

#### Acronyms

- Treat acronyms as words (except when they're well-known like `URL`, `ID`)

```swift
let userID: String      // OK - well-known
let htmlString: String  // OK - treat as word
let a2aHub: A2AHub      // OK - A2A is project-specific
```

### SwiftUI Specific

#### View Naming

- Suffix with `View`
- Group related views in extensions

```swift
struct ToolDetailView: View { }
struct SettingsView: View { }
```

#### ViewModel Naming

- Suffix with `ViewModel`
- Use `@MainActor` for UI-related view models

```swift
@MainActor
class ToolViewModel: ObservableObject { }
```

#### State Management

```swift
struct ExampleView: View {
    // Local state
    @State private var isExpanded = false
    
    // Owned reference type
    @StateObject private var viewModel = ToolViewModel()
    
    // Injected reference type
    @ObservedObject var sharedModel: SharedModel
    
    // Environment value
    @Environment(\.colorScheme) private var colorScheme
}
```

### Comments and Documentation

#### Documentation Comments

Use Swift's documentation comments for public APIs:

```swift
/// Starts the specified tool if not already running.
/// - Parameters:
///   - tool: The tool to start
/// - Throws: `AppError.toolStartupTimeout` if the tool fails to start
/// - Returns: Nothing; tool state is updated asynchronously
func startTool(_ tool: Tool) async throws {
    // Implementation
}
```

#### Inline Comments

- Explain **why**, not **what**
- Keep comments current with code

```swift
// Good: Explains business logic
// Health check may fail initially while the tool initializes
// so we retry with exponential backoff

// Bad: States the obvious
// Increment counter by 1
counter += 1
```

### Error Handling

#### Prefer Result Type for Complex Operations

```swift
enum ToolResult {
    case success(Tool)
    case failure(ToolError)
}
```

#### Use Do-Catch for Multiple Throws

```swift
do {
    let data = try fetchData()
    let parsed = try parse(data)
    return try process(parsed)
} catch {
    handleError(error)
}
```

#### Avoid Force Unwrapping

```swift
// Bad
let value = optionalValue!

// Good
if let value = optionalValue {
    // Use value
}

// Or
let value = optionalValue ?? defaultValue
```

### Access Control

- Use the most restrictive access level possible
- Default to `internal` within modules
- Mark protocols and their implementations consistently

```swift
// Public API
public protocol ToolProtocol { }

// Internal implementation
class ToolManager: ToolProtocol {
    // Private helper
    private func validate() { }
}
```

### Imports

- Group imports: System, Third-party, Project
- Alphabetize within groups

```swift
import Combine
import SwiftUI
import WebKit

import ThirdPartyLibrary

import DonnaCore
```

---

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Code style (formatting, semicolons) |
| `refactor` | Code restructuring |
| `perf` | Performance improvement |
| `test` | Test additions/changes |
| `chore` | Build process, dependencies |

### Examples

```
feat(toolbar): add dynamic toolbar generation

Implement toolbar builder that creates native macOS toolbar
items from tool manifest definitions.

Closes #42
```

```
fix(process): resolve race condition in health check

The health check would sometimes fail if the tool took
longer than expected to start.

Fixes #78
```

See [docs/WORKFLOW.md](docs/WORKFLOW.md) for complete details.

---

## Testing Guidelines

### Required Tests

All contributions should include appropriate tests:

| Change Type | Unit Tests | Integration Tests | UI Tests |
|-------------|------------|-------------------|----------|
| Bug fix | Required | Recommended | If UI |
| New feature | Required | Required | Required |
| Refactoring | Required | Recommended | If UI |

### Test Coverage

- Aim for **80%+ coverage** on new code
- Critical paths require **90%+ coverage**

### Running Tests

```bash
# All tests
xcodebuild test -scheme Donna -destination 'platform=macOS'

# Specific test
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaTests/ProcessManagerTests
```

See [docs/TESTING.md](docs/TESTING.md) for comprehensive testing guidelines.

---

## Reporting Issues

### Before Reporting

1. Search existing issues
2. Check if it's already fixed in `main`
3. Try to reproduce with minimal steps

### Bug Reports

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md). Include:

- Clear description
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Screenshots/logs if applicable

### Feature Requests

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md). Include:

- Problem statement
- Proposed solution
- Use cases
- Mockups/examples

---

## Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Assume good intentions
- Focus on constructive feedback

### Communication

- GitHub Issues: Bug reports, feature requests
- GitHub Discussions: Questions, ideas, general chat
- Pull Requests: Code reviews, implementation details

### Recognition

Contributors will be recognized in:
- Release notes
- CONTRIBUTORS.md file
- Project documentation

---

## Questions?

If you have questions not covered here:

1. Check the [documentation](docs/)
2. Search [existing issues](https://github.com/Kavipriyan10-2000/donna/issues)
3. Start a [GitHub Discussion](https://github.com/Kavipriyan10-2000/donna/discussions)
4. Ask in an issue/PR comment

---

Thank you for contributing to Donna! 🎉

*This document is a living document. Suggestions for improvements are welcome.*