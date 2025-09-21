# Ora Browser - AI Development Guide

## Overview

Ora is a modern, native macOS web browser built with SwiftUI and AppKit. It's designed to provide a fast, secure, and beautiful browsing experience inspired by Safari and Arc, with a focus on privacy, performance, and user experience.

## Architecture Overview

### Core Application Structure

**Entry Point**: `oraApp.swift`
- Main SwiftUI App struct that sets up the application
- Handles window management for normal and private browsing modes
- Configures the Settings window and commands

**Root Component**: `OraRoot.swift`
- Central state management with multiple ObservableObject managers
- Sets up SwiftData model containers for persistence
- Manages global application state and notifications
- Handles keyboard shortcuts and system events

### Key Components

#### 1. Browser View (`Modules/Browser/BrowserView.swift`)
The main browser interface that orchestrates:
- **Sidebar management**: Collapsible vertical sidebar with resizable width
- **Tab management**: Active tab display with content switching
- **URL bar**: Address bar with search functionality
- **Web view**: Main content area with WebKit integration
- **Floating components**: Launcher and tab switcher overlays

#### 2. Tab System
**TabManager** (`Services/TabManager.swift`):
- Manages tab containers (spaces) and individual tabs
- Handles tab creation, switching, closing, and restoration
- Supports pinned tabs, favorite tabs, and normal tabs
- Integrates with SwiftData for persistence
- Manages WebKit configurations for each tab

**Tab Model** (`Models/Tab.swift`):
- Core data structure for browser tabs
- Manages WebKit webView instances
- Handles navigation state, history, and media playback
- Integrates with background color extraction
- Supports private browsing with in-memory storage

**TabContainer Model** (`Models/TabContainer.swift`):
- Groups tabs into logical containers/spaces
- Manages tab ordering and organization
- Supports custom names and emojis for identification

#### 3. Services Layer

**SearchEngineService** (`Services/SearchEngineService.swift`):
- Manages multiple search engines and AI chat services
- Supports custom search engines with aliases
- Handles search suggestions and URL construction
- Integrates with container-specific settings

**TabScriptHandler** (`Services/TabScriptHandler.swift`):
- Manages JavaScript injection and message handling
- Processes page title, URL, and favicon updates
- Handles link hover detection and media events
- Configures WebKit settings for performance

**MediaController** (`Services/MediaController.swift`):
- Manages media playback across tabs
- Handles Picture-in-Picture functionality
- Coordinates media state between tabs

**HistoryManager** (`Services/HistoryManager.swift`):
- Records browsing history with metadata
- Manages favicon storage and retrieval
- Provides search and filtering capabilities

**DownloadManager** (`Services/DownloadManager.swift`):
- Handles file downloads from web pages
- Manages download state and progress
- Integrates with system download APIs

#### 4. UI Components

**URLBar** (`UI/URLBar.swift`):
- Address bar with editing capabilities
- Security indicators and loading states
- Copy URL functionality with animations
- Keyboard shortcuts for navigation

**Sidebar** (`Modules/Sidebar/`):
- Vertical navigation with collapsible sections
- Tab organization and management
- Container switching and creation
- Search functionality within tabs

**Launcher** (`Modules/Launcher/`):
- Quick access search and navigation
- AI chat integration
- Bookmark and history access
- Customizable shortcuts

#### 5. Data Models

**Core Models** (`Models/`):
- **Tab**: Individual browser tab with WebKit integration
- **TabContainer**: Tab grouping and organization
- **History**: Browsing history entries
- **Download**: Download management
- **SearchEngine**: Search engine configuration

**SwiftData Integration**:
- Uses SwiftData for local persistence
- Handles migration between versions
- Supports private browsing with in-memory storage
- Manages relationships between entities

## How AI Should Interact with the Codebase

### 1. Understanding the Architecture

When working with Ora Browser, always consider:

**State Management**:
- Use `@EnvironmentObject` for shared state managers
- Prefer `@ObservedObject` for view-specific state
- Understand the relationship between managers and views

**Data Flow**:
- SwiftData contexts are injected via environment
- Changes propagate through ObservableObject publishers
- Use SwiftData queries with `@Query` for reactive data fetching

**UI Patterns**:
- SwiftUI views compose the interface
- Custom modifiers handle common patterns
- Environment values provide theme and configuration

### 2. Working with Tabs

**Creating Tabs**:
```swift
// Always use TabManager to create tabs
let newTab = tabManager.addTab(
    title: "New Tab",
    url: URL(string: "https://example.com")!,
    container: activeContainer,
    historyManager: historyManager,
    isPrivate: false
)
```

**Tab State**:
- Check `tab.isWebViewReady` before accessing webView
- Use `tab.webView` for direct WebKit operations
- Monitor `tab.isLoading` and `tab.loadingProgress`

### 3. WebKit Integration

**Configuration**:
- Use `TabScriptHandler.customWKConfig()` for WebKit setup
- Handle JavaScript messages through `WKScriptMessageHandler`
- Configure user content controllers for custom scripts

**Navigation**:
- Use `tab.webView.load(URLRequest(url: url))` for navigation
- Handle navigation errors through `WebViewNavigationDelegate`
- Implement custom URL schemes and handling

### 4. Service Integration

**Search Engines**:
```swift
// Use SearchEngineService for search functionality
let searchService = SearchEngineService()
if let engine = searchService.getDefaultSearchEngine(for: containerId),
   let url = searchService.createSearchURL(for: engine, query: "search term") {
    tabManager.openTab(url: url, historyManager: historyManager, isPrivate: false)
}
```

**Media Handling**:
- MediaController coordinates media playback
- Use Picture-in-Picture APIs for video
- Handle media events through JavaScript injection

### 5. UI Development

**Theme Integration**:
- Use `@Environment(\.theme)` for theming
- Access colors through `theme.background`, `theme.foreground`
- Support light/dark mode through system preferences

**Custom Modifiers**:
- Use existing modifiers for common patterns
- Create custom modifiers for reusable UI components
- Follow the established modifier patterns

### 6. Testing and Debugging

**Testing Strategy**:
- Write tests for service classes
- Use SwiftUI previews for UI components
- Test WebKit integration with mock data
- Validate tab state management

**Debugging Tips**:
- Use WebKit inspector for web content debugging
- Monitor SwiftData changes through console logs
- Test keyboard shortcuts and system integration
- Validate private browsing isolation

### 7. Performance Considerations

**Memory Management**:
- WebKit views consume significant memory
- Use proper cleanup in `destroyWebView()`
- Monitor tab lifecycle and resource usage

**Optimization**:
- Use hardware acceleration for WebKit views
- Implement lazy loading for non-visible tabs
- Optimize JavaScript injection and message handling

## Development Guidelines

### 1. Code Style
- Follow SwiftUI naming conventions
- Use descriptive variable and function names
- Maintain consistent indentation and formatting
- Add comprehensive documentation for public APIs

### 2. Error Handling
- Use proper error propagation in async operations
- Handle WebKit navigation errors gracefully
- Implement fallback behaviors for failed operations

### 3. Accessibility
- Add accessibility labels and hints
- Support keyboard navigation
- Ensure proper focus management
- Test with VoiceOver and other assistive technologies

### 4. Security
- Validate user input before processing
- Sanitize URLs and search queries
- Follow macOS security best practices
- Implement proper sandboxing where applicable

## Common Patterns

### 1. Environment Setup
```swift
struct MyView: View {
    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject var historyManager: HistoryManager
    @Environment(\.theme) var theme

    var body: some View {
        // View implementation
    }
}
```

### 2. Data Queries
```swift
struct TabListView: View {
    @Query(sort: \Tab.lastAccessedAt, order: .reverse) var tabs: [Tab]

    var body: some View {
        ForEach(tabs) { tab in
            TabItem(tab: tab)
        }
    }
}
```

### 3. Async Operations
```swift
Task {
    do {
        let result = try await performAsyncOperation()
        // Handle result
    } catch {
        // Handle error
    }
}
```

## Extension Points

### 1. Custom Search Engines
- Add new search engines in `SearchEngineService`
- Support custom icons and colors
- Implement suggestion providers
- Add keyboard shortcuts

### 2. UI Extensions
- Create custom URL bar buttons
- Implement new sidebar sections
- Add floating components
- Customize theme colors

### 3. WebKit Extensions
- Add custom JavaScript handlers
- Implement content blocking
- Create custom navigation schemes
- Add user script support

## Troubleshooting

### Common Issues

1. **Tab not loading**: Check `isWebViewReady` and WebKit configuration
2. **State not updating**: Verify ObservableObject publishers and SwiftUI updates
3. **Memory leaks**: Monitor WebKit view lifecycle and cleanup
4. **UI not responding**: Check main thread operations and async handling

### Debugging Tools

- WebKit Inspector for web content
- Xcode debugging for Swift code
- Console logs for state changes
- SwiftUI previews for UI testing

## Integration with System

### 1. macOS Integration
- Use AppKit APIs for system integration
- Handle window management and lifecycle
- Implement proper menu bar integration
- Support system keyboard shortcuts

### 2. Security and Privacy
- Implement content blocking for tracking
- Handle permissions for media and location
- Support private browsing isolation
- Follow macOS security guidelines

This guide provides a comprehensive understanding of the Ora Browser codebase and how to work with it effectively as an AI assistant.
