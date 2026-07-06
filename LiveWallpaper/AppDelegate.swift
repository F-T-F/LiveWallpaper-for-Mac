import Cocoa
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine = WallpaperEngine()
    private var statusItem: NSStatusItem!
    private let lastVideoKey = "LiveWallpaper.lastVideoURL"
    private let mutedKey = "LiveWallpaper.muted"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        engine.isMuted = UserDefaults.standard.object(forKey: mutedKey) as? Bool ?? true

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

        let chooseVideoItem = NSMenuItem(title: Localized.string("menu.chooseVideo"), action: #selector(chooseVideo), keyEquivalent: "o")
        chooseVideoItem.target = self
        settingsMenu.addItem(chooseVideoItem)

        let muteItem = NSMenuItem(title: Localized.string("menu.muted"), action: #selector(toggleMute), keyEquivalent: "m")
        muteItem.target = self
        muteItem.state = engine.isMuted ? .on : .off
        settingsMenu.addItem(muteItem)

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
            menu.addItem(withTitle: Localized.string("menu.pauseResume"), action: #selector(togglePause), keyEquivalent: "p").target = self
            menu.addItem(withTitle: Localized.string("menu.stopWallpaper"), action: #selector(stopWallpaper), keyEquivalent: "s").target = self
        }

        menu.addItem(.separator())

        menu.addItem(withTitle: Localized.string("menu.quit"), action: #selector(quit), keyEquivalent: "q").target = self

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
