# ToolHub Testing Guide

## Overview

This document describes the testing strategy and procedures for ToolHub.

## Test Categories

### 1. Unit Tests

Located in `ToolHubTests/ToolHubTests.swift`

**Run Tests:**
```bash
xcodebuild test -project ToolHub.xcodeproj -scheme ToolHub -destination 'platform=macOS'
```

**Covered Components:**
- Tool Manifest parsing and validation
- Port availability checking
- Health check functionality
- User preferences persistence
- Tool model behavior

### 2. Integration Tests

**Manual Testing Checklist:**

#### Tool Installation
- [ ] Open ToolHub
- [ ] Click "Add Tool" button
- [ ] Select Moltbot from catalog
- [ ] Verify installation completes
- [ ] Verify Moltbot appears in sidebar

#### Tool Launch
- [ ] Select Moltbot in sidebar
- [ ] Click "Start" button
- [ ] Verify status changes to "Starting" then "Running"
- [ ] Verify port is displayed in status bar
- [ ] Verify webview loads Moltbot UI

#### Tool Stop
- [ ] With Moltbot running, click "Stop"
- [ ] Verify status changes to "Stopped"
- [ ] Verify webview shows "Not Running" state

#### Tool Restart
- [ ] With Moltbot running, click "Restart"
- [ ] Verify tool stops and starts again
- [ ] Verify webview reloads

#### Tool Removal
- [ ] Right-click Moltbot in sidebar
- [ ] Select "Remove"
- [ ] Confirm removal
- [ ] Verify tool disappears from sidebar
- [ ] Verify process is stopped

### 3. E2E Tests with Real Tools

#### Prerequisites
- Install Moltbot: `npm install -g moltbot`
- Install Vibe Kanban: `npm install -g vibe-kanban`

#### Moltbot Test
1. Add Moltbot from catalog
2. Start Moltbot
3. Wait for health check (port 18789)
4. Verify WebChat UI loads
5. Create a test chat
6. Stop Moltbot
7. Verify process terminates

#### Vibe Kanban Test
1. Add Vibe Kanban from catalog
2. Start Vibe Kanban
3. Wait for health check (dynamic port 3000-3100)
4. Verify Kanban board loads
5. Create a test board
6. Stop Vibe Kanban
7. Verify process terminates

#### Multiple Tools Test
1. Start both Moltbot and Vibe Kanban
2. Switch between tools
3. Verify both processes remain running
4. Stop one tool
5. Verify the other continues running

### 4. Error Handling Tests

#### Port Conflict
- [ ] Start a server on port 18789 manually
- [ ] Try to start Moltbot
- [ ] Verify error message about port conflict
- [ ] Verify tool doesn't crash

#### Health Check Timeout
- [ ] Modify manifest to use invalid health endpoint
- [ ] Try to start tool
- [ ] Verify timeout after 30 seconds
- [ ] Verify error message

#### Process Crash
- [ ] Start a tool
- [ ] Kill the process externally
- [ ] Verify ToolHub detects crash
- [ ] Verify auto-restart if enabled

### 5. UI/UX Tests

#### Sidebar
- [ ] Verify tool list displays correctly
- [ ] Verify status indicators (green/red/yellow dots)
- [ ] Verify selection highlighting
- [ ] Test collapse/expand

#### WebView
- [ ] Verify loading indicator appears
- [ ] Verify tool UI renders correctly
- [ ] Test scrolling within webview
- [ ] Test interactions (buttons, forms)

#### Status Bar
- [ ] Verify status text updates
- [ ] Verify port displays when running
- [ ] Verify PID displays when running

### 6. Performance Tests

#### Startup Time
- [ ] Measure time from launch to interactive: Target < 3 seconds

#### Tool Switch Time
- [ ] Measure time between tool selections: Target < 1 second

#### Memory Usage
- [ ] Monitor memory with Activity Monitor
- [ ] Target: < 500MB with 3 tools running

## Test Data

### Sample Tool Manifests

See `ToolHub/Resources/Manifests/` for test manifests:
- `moltbot.json` - Fixed port (18789)
- `vibe-kanban.json` - Dynamic port range (3000-3100)

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: xcodebuild build -project ToolHub.xcodeproj -scheme ToolHub
      - name: Test
        run: xcodebuild test -project ToolHub.xcodeproj -scheme ToolHub -destination 'platform=macOS'
```

## Bug Reporting Template

```
**Bug Description:**
[Clear description of the bug]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Environment:**
- macOS Version: [e.g., 14.0]
- ToolHub Version: [e.g., 1.0.0]
- Tool: [e.g., Moltbot v1.2.0]

**Logs:**
[Relevant log output]

**Screenshots:**
[If applicable]
```

## Release Checklist

Before releasing a new version:

- [ ] All unit tests pass
- [ ] Manual integration tests pass
- [ ] E2E tests with Moltbot pass
- [ ] E2E tests with Vibe Kanban pass
- [ ] Error handling tests pass
- [ ] Performance targets met
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in project settings
- [ ] Git tag created

## Known Limitations

1. **Sandboxing**: App sandbox may restrict some tool operations
2. **Port Conflicts**: No automatic port reassignment yet
3. **Process Monitoring**: Limited to health check polling
4. **A2A Protocol**: Not yet implemented (Phase 2)

## Future Testing Improvements

- [ ] Automated UI tests with XCUITest
- [ ] Performance benchmarking
- [ ] Security penetration testing
- [ ] Accessibility testing with VoiceOver
- [ ] Multi-user scenario testing
