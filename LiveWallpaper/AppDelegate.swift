import Cocoa
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine = WallpaperEngine()
    private var statusItem: NSStatusItem!
    private let lastVideoKey = "LiveWallpaper.lastVideoURL"
    private let mutedKey = "LiveWallpaper.muted"
    private let pingPongKey = "LiveWallpaper.pingPong"
    private let loopKey = "LiveWallpaper.loopPlayback"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        engine.isMuted = UserDefaults.standard.object(forKey: mutedKey) as? Bool ?? true
        engine.loopPlayback = UserDefaults.standard.object(forKey: loopKey) as? Bool ?? true
        engine.pingPongMode = UserDefaults.standard.object(forKey: pingPongKey) as? Bool ?? true

        buildStatusItem()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)

        if let saved = UserDefaults.standard.url(forKey: lastVideoKey),
           FileManager.default.fileExists(atPath: saved.path) {
            engine.start(url: saved)
        }

        refreshMenu()
    }

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "photo.tv", accessibilityDescription: "Live Wallpaper")
        }
    }

    private func refreshMenu() {
        let menu = NSMenu()

        let settingsMenu = NSMenu()

        let chooseVideoItem = NSMenuItem(title: Localized.string("menu.chooseVideo"), action: #selector(chooseVideo), keyEquivalent: "") // 快捷鍵已注釋: "o"
        chooseVideoItem.target = self
        settingsMenu.addItem(chooseVideoItem)

        let muteItem = NSMenuItem(title: Localized.string("menu.muted"), action: #selector(toggleMute), keyEquivalent: "") // 快捷鍵已注釋: "m"
        muteItem.target = self
        muteItem.state = engine.isMuted ? .on : .off
        settingsMenu.addItem(muteItem)

        let loopItem = NSMenuItem(title: Localized.string("menu.loopPlayback"), action: #selector(toggleLoop), keyEquivalent: "") // 快捷鍵已注釋: "r"
        loopItem.target = self
        loopItem.state = engine.loopPlayback ? .on : .off
        settingsMenu.addItem(loopItem)

        let pingPongItem = NSMenuItem(title: Localized.string("menu.pingPong"), action: #selector(togglePingPong), keyEquivalent: "") // 快捷鍵已注釋: "l"
        pingPongItem.target = self
        pingPongItem.state = engine.pingPongMode ? .on : .off
        settingsMenu.addItem(pingPongItem)

        let languageMenu = NSMenu()
        let supportedLanguages = [("en", "English"), ("zh-hk", "繁體中文")]
        let currentLanguage = UserDefaults.standard.string(forKey: "App.Language") ?? "en"
        for (code, title) in supportedLanguages {
            let item = NSMenuItem(title: title, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.state = (code == currentLanguage) ? .on : .off
            item.representedObject = code
            item.target = self
            languageMenu.addItem(item)
        }
        let languageItem = NSMenuItem(title: Localized.string("menu.language"), action: nil, keyEquivalent: "")
        settingsMenu.setSubmenu(languageMenu, for: languageItem)
        settingsMenu.addItem(languageItem)

        let settingsMenuItem = NSMenuItem(title: Localized.string("menu.settings"), action: nil, keyEquivalent: "")
        menu.setSubmenu(settingsMenu, for: settingsMenuItem)
        menu.addItem(settingsMenuItem)

        if engine.isPlaying {
            menu.addItem(withTitle: Localized.string("menu.pauseResume"), action: #selector(togglePause), keyEquivalent: "").target = self // 快捷鍵已注釋: "p"
            menu.addItem(withTitle: Localized.string("menu.stopWallpaper"), action: #selector(stopWallpaper), keyEquivalent: "").target = self // 快捷鍵已注釋: "s"
        }

        menu.addItem(.separator())

        menu.addItem(withTitle: Localized.string("menu.quit"), action: #selector(quit), keyEquivalent: "").target = self // 快捷鍵已注釋: "q"

        statusItem.menu = menu
    }

    @objc private func chooseVideo() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.movie, .video, .mpeg4Movie, .quickTimeMovie]
        panel.prompt = Localized.string("panel.setAsWallpaper")

        NSApp.activate(ignoringOtherApps: true)

        if panel.runModal() == .OK, let url = panel.url {
            UserDefaults.standard.set(url, forKey: lastVideoKey)
            engine.start(url: url)
            refreshMenu()
        }
    }

    @objc private func togglePause() { engine.togglePause() }

    @objc private func stopWallpaper() {
        engine.stop()
        refreshMenu()
    }

    @objc private func toggleMute() {
        engine.isMuted.toggle()
        UserDefaults.standard.set(engine.isMuted, forKey: mutedKey)
        refreshMenu()
    }

    @objc private func togglePingPong() {
        engine.pingPongMode.toggle()
        UserDefaults.standard.set(engine.pingPongMode, forKey: pingPongKey)
        refreshMenu()
    }

    @objc private func toggleLoop() {
        engine.setLoopPlayback(!engine.loopPlayback)
        UserDefaults.standard.set(engine.loopPlayback, forKey: loopKey)
        refreshMenu()
    }

    @objc private func screensChanged() {
        if engine.isPlaying { engine.rebuildWindows() }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        UserDefaults.standard.set(code, forKey: "App.Language")
        refreshMenu()
    }
}
