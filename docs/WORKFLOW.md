# Git Workflow Documentation

> **Version**: 1.0  
> **Last Updated**: 2026-01-28  
> **Applies To**: All contributors to the Donna project

---

## Table of Contents

1. [Branch Naming Conventions](#1-branch-naming-conventions)
2. [Pull Request Template](#2-pull-request-template)
3. [Commit Message Format](#3-commit-message-format)
4. [Code Review Checklist](#4-code-review-checklist)
5. [Testing Requirements](#5-testing-requirements)

---

## 1. Branch Naming Conventions

### Format
```
<type>/<short-description>
```

### Types

| Type | Purpose | Example |
|------|---------|---------|
| `feature` | New features or enhancements | `feature/adaptive-toolbar` |
| `bugfix` | Bug fixes | `bugfix/process-manager-crash` |
| `hotfix` | Critical production fixes | `hotfix/memory-leak` |
| `docs` | Documentation updates | `docs/api-reference` |
| `refactor` | Code refactoring | `refactor/tool-registry` |
| `test` | Test additions or updates | `test/process-manager` |
| `chore` | Maintenance tasks | `chore/update-dependencies` |

### Rules

1. **Use lowercase letters only**: `feature/new-ui` not `Feature/New-UI`
2. **Use hyphens for spaces**: `feature/adaptive-toolbar` not `feature/adaptive_toolbar`
3. **Keep it short**: Maximum 50 characters for the description
4. **Be descriptive**: `feature/toolbar` is bad, `feature/adaptive-toolbar-system` is good
5. **Include issue number** (optional): `feature/42-adaptive-toolbar`

### Examples

```bash
# Good
feature/sidebar-navigation
bugfix/webview-memory-leak
refactor/process-manager
hotfix/crash-on-startup
docs/contributing-guide

# Bad
Feature-New-UI          # Wrong case, wrong separator
fix                     # Too vague
feature/a-very-long-branch-name-that-is-hard-to-read  # Too long
```

---

## 2. Pull Request Template

When creating a Pull Request, use the template located at [`.github/PULL_REQUEST_TEMPLATE.md`](../.github/PULL_REQUEST_TEMPLATE.md).

### PR Title Format

```
[<type>] <short description>
```

### Types

- `[FEATURE]` - New feature
- `[BUGFIX]` - Bug fix
- `[DOCS]` - Documentation
- `[REFACTOR]` - Code refactoring
- `[TEST]` - Tests
- `[CHORE]` - Maintenance

### Examples

```
[FEATURE] Implement adaptive toolbar system
[BUGFIX] Fix memory leak in WKWebView container
[DOCS] Add testing strategy documentation
[REFACTOR] Simplify process manager state handling
```

### PR Description Requirements

1. **What**: Describe what changed
2. **Why**: Explain why the change was needed
3. **How**: Briefly explain the approach
4. **Testing**: Describe how you tested the changes

### PR Size Guidelines

- **Small**: < 200 lines (ideal)
- **Medium**: 200-500 lines (acceptable)
- **Large**: 500-1000 lines (requires extra review)
- **Extra Large**: > 1000 lines (should be split)

---

## 3. Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | Description |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Changes that don't affect code meaning (formatting, semicolons, etc.) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Code change that improves performance |
| `test` | Adding or correcting tests |
| `chore` | Changes to build process, dependencies, etc. |

### Scope

The scope is optional and should be one of:

- `core` - Core platform
- `ui` - User interface
- `toolbar` - Adaptive toolbar
- `sidebar` - Sidebar navigation
- `webview` - WebView container
- `process` - Process manager
- `registry` - Tool registry
- `dashboard` - Dashboard module
- `a2a` - A2A protocol
- `docs` - Documentation

### Subject Rules

1. Use imperative mood: "Add feature" not "Added feature"
2. Don't capitalize first letter: "add feature" not "Add feature"
3. No period at the end
4. Maximum 50 characters

### Body Rules

1. Wrap at 72 characters
2. Explain **what** and **why**, not **how**
3. Use bullet points for multiple changes

### Footer Rules

1. Reference issues: `Closes #123`, `Fixes #456`
2. Breaking changes: `BREAKING CHANGE: description`

### Examples

```
feat(toolbar): add dynamic toolbar generation

Implement toolbar builder that creates native macOS toolbar
items from tool manifest definitions. Supports buttons,
dropdowns, and search fields.

Closes #42
```

```
fix(process): resolve race condition in health check

The health check would sometimes fail if the tool took
longer than expected to start. Added retry logic with
exponential backoff.

Fixes #78
```

```
docs: update architecture diagram

Replace outdated system architecture diagram with new
version showing A2A protocol integration.
```

```
refactor(registry): simplify tool discovery logic

- Extract port scanning to separate service
- Add caching for discovered tools
- Improve error handling for malformed manifests
```

---

## 4. Code Review Checklist

### For Authors

Before requesting a review, ensure:

- [ ] Code compiles without warnings
- [ ] All tests pass locally
- [ ] Self-review completed
- [ ] Documentation updated (if needed)
- [ ] Commit messages follow convention
- [ ] Branch is up to date with `main`
- [ ] No debug code or print statements left
- [ ] No sensitive data (API keys, passwords) committed

### For Reviewers

#### General

- [ ] PR description is clear and complete
- [ ] Changes align with project goals
- [ ] Scope is appropriate (not too large)
- [ ] Commit history is clean and logical

#### Code Quality

- [ ] Code follows Swift style guidelines
- [ ] Naming is clear and consistent
- [ ] Functions are appropriately sized
- [ ] No code duplication
- [ ] Error handling is comprehensive
- [ ] No force unwrapping (`!`) without justification
- [ ] No force casting (`as!`) without justification

#### Architecture

- [ ] Changes follow established patterns
- [ ] MVVM pattern is correctly applied
- [ ] Dependencies are properly injected
- [ ] No circular dependencies introduced
- [ ] Thread safety considered (use of `@MainActor`)

#### SwiftUI Specific

- [ ] Views are appropriately decomposed
- [ ] State management is correct (`@State`, `@StateObject`, `@ObservedObject`)
- [ ] No unnecessary view rebuilds
- [ ] Accessibility labels added where needed

#### Testing

- [ ] Unit tests added for new logic
- [ ] UI tests added for new features
- [ ] Edge cases are covered
- [ ] Tests are meaningful (not just for coverage)

#### Documentation

- [ ] Public APIs have documentation comments
- [ ] Complex logic has inline comments
- [ ] README updated if needed
- [ ] Architecture docs updated if needed

### Review Comments

- Be constructive and respectful
- Explain the "why" behind suggestions
- Use GitHub's suggestion feature for simple changes
- Distinguish between "required" and "optional" changes
- Approve when only minor issues remain

### Approval Levels

- **1 approval**: Documentation, tests, minor fixes
- **2 approvals**: New features, significant changes
- **3 approvals**: Breaking changes, architectural changes

---

## 5. Testing Requirements

### Required Tests by Change Type

| Change Type | Unit Tests | Integration Tests | UI Tests | Manual |
|-------------|------------|-------------------|----------|--------|
| Bug fix | Required | Recommended | If UI-related | Required |
| New feature | Required | Required | Required | Required |
| Refactoring | Required | Recommended | If UI-related | Recommended |
| Documentation | N/A | N/A | N/A | Recommended |
| Performance | Required | Required | N/A | Recommended |

### Test Coverage Requirements

- **Minimum overall coverage**: 70%
- **New code coverage**: 80%
- **Critical paths**: 90%

Critical paths include:
- Process management
- Tool lifecycle
- Data persistence
- A2A protocol communication

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme Donna -destination 'platform=macOS'

# Run unit tests only
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaTests

# Run UI tests only
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaUITests

# Run specific test
xcodebuild test -scheme Donna -destination 'platform=macOS' -only-testing:DonnaTests/ProcessManagerTests/testStartTool
```

### Test Naming Conventions

```swift
// Test class naming
class FeatureNameTests: XCTestCase {
    // Test method naming: test<Condition><ExpectedResult>
    func testStartToolWithValidConfigReturnsSuccess() { }
    func testStartToolWithInvalidPortThrowsError() { }
    func testStopToolTerminatesRunningProcess() { }
}
```

### Pre-Merge Verification

Before merging a PR, the following must pass:

1. **CI/CD Pipeline**: All automated checks
2. **Unit Tests**: 100% pass rate
3. **Integration Tests**: 100% pass rate
4. **Linting**: No SwiftLint warnings
5. **Code Review**: Required approvals obtained

---

## Quick Reference

### Starting New Work

```bash
# 1. Update main
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b feature/my-feature

# 3. Make changes and commit
git add .
git commit -m "feat(scope): description"

# 4. Push branch
git push -u origin feature/my-feature

# 5. Create Pull Request on GitHub
```

### Syncing with Main

```bash
# While on your feature branch
git fetch origin
git rebase origin/main

# If conflicts exist, resolve them and continue
git add .
git rebase --continue
```

### Emergency Hotfix

```bash
# Create hotfix from main
git checkout main
git checkout -b hotfix/critical-fix

# Make fix and commit
git commit -m "fix(scope): critical fix description"

# Create PR with [HOTFIX] prefix
```

---

*This document should be updated as the project evolves. Suggestions for improvements are welcome.*