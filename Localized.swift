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
            "menu.language": "Language",
            "menu.quit": "Quit",
            "panel.setAsWallpaper": "Set as Wallpaper",
            "menu.settings": "Setting",
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
            "menu.language": "語言",
            "menu.quit": "結束",
            "panel.setAsWallpaper": "設為桌布",
            "menu.settings": "設置",
        ],
    ]

    static func string(_ key: String) -> String {
        translations[currentLanguage]?[key]
            ?? translations["en"]?[key]
            ?? key
    }
}
