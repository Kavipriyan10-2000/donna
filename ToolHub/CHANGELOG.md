# Changelog

All notable changes to ToolHub will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-28

### Added
- Initial release of ToolHub
- Native macOS app built with SwiftUI
- WKWebView container for embedding web-based tools
- Tool registry with JSON manifest support
- Process management with automatic start/stop
- Health check monitoring for tools
- Port finder with conflict resolution
- Sidebar navigation with tool list
- Tool catalog for discovering and installing tools
- Support for Moltbot (fixed port 18789)
- Support for Vibe Kanban (dynamic port range 3000-3100)
- Process status indicators (running, stopped, error, crashed)
- Auto-restart on process crash
- STDOUT/STDERR log capture
- User preferences persistence
- Keyboard shortcuts (⌘+R to start, ⌘+. to stop)
- Error handling and user-friendly error messages
- Unit tests for core components

### Technical
- Swift 5.9+ with modern concurrency
- macOS 13.0 (Ventura) minimum deployment target
- MVVM architecture with ObservableObject
- Sandboxed app with network entitlements
- Codable models for JSON persistence
- URLSession for health checks
- Process API for tool lifecycle management

## [Unreleased]

### Planned for v1.1
- Adaptive toolbar system
- Tool-specific toolbar actions
- Multiple layout types (split, tabs)
- Widget system for dashboard
- A2A (Agent-to-Agent) protocol support
- Agent discovery and task routing

### Planned for v1.2
- Plugin marketplace
- Custom themes
- Global quick launcher
- Import/export tool configurations
- Windows/Linux support (future)

## Release Notes

### v1.0.0 - MVP Release

This is the first stable release of ToolHub, providing core functionality for running open-source developer tools in a native macOS container.

**Key Features:**
- ✅ Run Moltbot and Vibe Kanban in a unified interface
- ✅ Automatic process management
- ✅ Tool discovery and installation
- ✅ Clean, native macOS UI
- ✅ Comprehensive error handling

**Known Issues:**
- Port conflicts require manual resolution
- No automatic port reassignment yet
- A2A protocol not yet implemented

**System Requirements:**
- macOS 13.0 (Ventura) or later
- 100MB free disk space
- Internet connection for tool installation
