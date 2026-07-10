import Foundation

enum Localized {
    static var currentLanguage: String {
        UserDefaults.standard.string(forKey: "App.Language") ?? "en"
    }

    private static let translations: [String: [String: String]] = [
        "en": [
            "menu.noWallpaper": "No wallpaper",
            "menu.playing": "Playing",
            "menu.chooseVideo": "Choose Video…",
            "menu.pauseResume": "Pause / Resume",
            "menu.stopWallpaper": "Stop Wallpaper",
            "menu.muted": "Muted",
            "menu.loopPlayback": "Loop Playback",
            "menu.pingPong": "Ping-Pong Loop",
            "menu.launchAtLogin": "Launch at Login",
            "menu.launchAtLoginUnsupported": "Launch at Login (macOS 13+)",
            "menu.language": "Language",
            "menu.quit": "Quit",
            "panel.setAsWallpaper": "Set as Wallpaper",
            "menu.settings": "Setting",
            "alert.launchAtLoginFailed": "Could not update login item",
        ],
        "zh-hk": [
            "menu.noWallpaper": "沒有桌布",
            "menu.playing": "播放中",
            "menu.chooseVideo": "選擇影片…",
            "menu.pauseResume": "暫停 / 繼續",
            "menu.stopWallpaper": "停止桌布",
            "menu.muted": "靜音",
            "menu.loopPlayback": "循環播放",
            "menu.pingPong": "來回播放",
            "menu.launchAtLogin": "開機自動啟動",
            "menu.launchAtLoginUnsupported": "開機自動啟動（macOS 13+）",
            "menu.language": "語言",
            "menu.quit": "結束",
            "panel.setAsWallpaper": "設為桌布",
            "menu.settings": "設置",
            "alert.launchAtLoginFailed": "無法更新開機自動啟動",
        ],
    ]

    static func string(_ key: String) -> String {
        translations[currentLanguage]?[key]
            ?? translations["en"]?[key]
            ?? key
    }
}
