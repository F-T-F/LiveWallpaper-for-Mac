import Cocoa
import AVFoundation

final class WallpaperEngine {
    private var windows: [WallpaperWindow] = []
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private(set) var currentURL: URL?

    var isPlaying: Bool { player != nil }

    var isMuted: Bool = true {
        didSet { player?.isMuted = isMuted }
    }

    func start(url: URL) {
        currentURL = url
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        queue.isMuted = isMuted
        queue.actionAtItemEnd = .advance
        looper = AVPlayerLooper(player: queue, templateItem: item)
        player = queue

        rebuildWindows()
        queue.play()
    }

    func stop() {
        player?.pause()
        player = nil
        looper = nil
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
    }

    func togglePause() {
        guard let p = player else { return }
        if p.rate == 0 { p.play() } else { p.pause() }
    }

    func rebuildWindows() {
        for w in windows { w.orderOut(nil) }
        windows.removeAll()

        guard let p = player else { return }

        for screen in NSScreen.screens {
            let w = WallpaperWindow(screen: screen)
            w.attach(player: p)
            w.orderFront(nil)
            windows.append(w)
        }
    }
}
