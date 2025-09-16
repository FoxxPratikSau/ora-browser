import AppKit
import SwiftUI

struct LauncherView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var privacyMode: PrivacyMode
    @Environment(\.theme) private var theme
    @StateObject private var searchEngineService = SearchEngineService()
    @StateObject private var faviconService = FaviconService()

    @State private var input = ""
    @State private var isVisible = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var match: LauncherMain.Match?
    @State private var isEditingCurrentURL: Bool = false

    var clearOverlay: Bool? = false

    private func onTabPress() {
        guard !input.isEmpty else { return }
        if let searchEngine = searchEngineService.findSearchEngine(for: input) {
            let customEngine = searchEngineService.settings.customSearchEngines
                .first { $0.searchURL == searchEngine.searchURL }
            match = searchEngine.toLauncherMatch(
                originalAlias: input,
                faviconService: faviconService,
                customEngine: customEngine
            )
            input = ""
        }
    }

    /// Submits the launcher input: either navigates the active tab (when editing the current URL) or performs a search and opens a new tab.
    /// 
    /// If `newInput` is provided it is used; otherwise the current `input` state is used.
    /// - When `isEditingCurrentURL` is true and there is an active tab, loads the resolved input into that tab, hides the launcher, resets `isEditingCurrentURL`, and returns.
    /// - Otherwise, resolves an appropriate search engine (using an existing match or the default engine for the active container) and, if a search URL can be produced, opens a new tab for that URL. In all cases the launcher is hidden after processing.
    /// - Parameters:
    ///   - newInput: An optional input string to submit instead of the current launcher `input`.
    private func onSubmit(_ newInput: String? = nil) {
        let correctInput = newInput ?? input

        if isEditingCurrentURL, let activeTab = tabManager.activeTab {
            activeTab.loadURL(correctInput)
            appState.showLauncher = false
            isEditingCurrentURL = false
            return
        }

        var engineToUse = match

        if engineToUse == nil,
           let defaultEngine = searchEngineService.getDefaultSearchEngine(for: tabManager.activeContainer?.id)
        {
            let customEngine = searchEngineService.settings.customSearchEngines
                .first { $0.searchURL == defaultEngine.searchURL }
            engineToUse = defaultEngine.toLauncherMatch(
                originalAlias: correctInput,
                faviconService: faviconService,
                customEngine: customEngine
            )
        }

        if let engine = engineToUse,
           let url = searchEngineService.createSearchURL(for: engine, query: correctInput)
        {
            tabManager
                .openTab(
                    url: url,
                    historyManager: historyManager,
                    downloadManager: downloadManager,
                    isPrivate: privacyMode.isPrivate
                )
        }
        appState.showLauncher = false
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(clearOverlay! ? 0 : 0.3)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeOut(duration: 0.1), value: isVisible)
                .onTapGesture {
                    if tabManager.activeTab != nil {
                        isVisible = false
                        DispatchQueue.main.async {
                            appState.showLauncher = false
                            appState.launcherSearchText = ""
                        }
                    }
                }

            LauncherMain(
                text: $input,
                match: $match,
                isFocused: $isTextFieldFocused,
                onTabPress: onTabPress,
                onSubmit: onSubmit,
                isEditingCurrentURL: isEditingCurrentURL
            )
            .gradientAnimatingBorder(
                color: match?.faviconBackgroundColor ?? match?.color ?? .clear,
                trigger: match != nil
            )
            .offset(y: 250)
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .opacity(isVisible ? 1.0 : 0.0)
            .blur(radius: isVisible ? 0 : 2)
            .animation(.easeOut(duration: 0.1), value: isVisible)
            .onAppear {
                isVisible = true
                isTextFieldFocused = true
                searchEngineService.setTheme(theme)
                if !appState.launcherSearchText.isEmpty {
                    input = appState.launcherSearchText
                    isEditingCurrentURL = true
                    match = nil
                    appState.launcherSearchText = ""
                }
            }
            .onChange(of: appState.showLauncher) { _, newValue in
                isVisible = newValue
                if newValue {
                    if !appState.launcherSearchText.isEmpty {
                        input = appState.launcherSearchText
                        isEditingCurrentURL = true
                        match = nil
                        appState.launcherSearchText = ""
                    }
                } else {
                    input = ""
                    match = nil
                    isEditingCurrentURL = false
                }
            }
            // .onChange(of: theme) { _, newValue in
            //     searchEngineService.setTheme(newValue)
            // }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onExitCommand {
            if tabManager.activeTab != nil {
                isVisible = false
                DispatchQueue.main.async {
                    appState.showLauncher = false
                    appState.launcherSearchText = ""
                    isEditingCurrentURL = false
                }
            }
        }
    }
}
