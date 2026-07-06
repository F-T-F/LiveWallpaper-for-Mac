import Cocoa
import AVFoundation

final class WallpaperEngine {
    private var windows: [WallpaperWindow] = []
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private(set) var currentURL: URL?

    var loopStart: CMTime = .zero
    var loopEnd: CMTime = .indefinite

    var loopPlayback: Bool = true

    var pingPongMode: Bool = true

    private var direction: Float = 1.0

    private var isRewinding = false

    private var userPaused = false

    private var finished = false

    private let edgeEpsilon = CMTime(seconds: 0.05, preferredTimescale: 600)

    var isPlaying: Bool { player != nil }

    var isMuted: Bool = true {
        didSet { player?.isMuted = isMuted }
    }

    func start(url: URL) {
        stop()
        currentURL = url

        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = isMuted
        p.actionAtItemEnd = .pause
        p.automaticallyWaitsToMinimizeStalling = false
        player = p

        rebuildWindows()

        direction = 1.0
        userPaused = false
        finished = false
        p.play()

        addObservers(item: item, player: p)
    }

    func stop() {
        removeObservers()
        player?.pause()
        player = nil
        currentURL = nil
        direction = 1.0
        isRewinding = false
        userPaused = false
        finished = false
        for w in windows { w.orderOut(nil) }
        windows.removeAll()
    }

    func togglePause() {
        guard let p = player else { return }
        if finished {
            if let url = currentURL { start(url: url) }
            return
        }
        if userPaused {
            userPaused = false
            p.rate = direction
        } else {
            userPaused = true
            p.rate = 0
        }
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

    private func addObservers(item: AVPlayerItem, player p: AVPlayer) {
        let interval = CMTime(seconds: 1.0 / 60.0, preferredTimescale: 600)
        timeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handle(time: time)
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.handleReachedEnd()
        }
    }

    private func removeObservers() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
        if let obs = endObserver {
            NotificationCenter.default.removeObserver(obs)
            endObserver = nil
        }
    }

    private func effectiveEnd() -> CMTime {
        let duration = player?.currentItem?.duration ?? .indefinite
        guard duration.isNumeric else { return loopEnd }
        if loopEnd.isNumeric && CMTimeCompare(loopEnd, duration) < 0 {
            return loopEnd
        }
        return duration
    }

    private func effectiveStart() -> CMTime {
        loopStart.isNumeric ? loopStart : .zero
    }

    private func pingPongActive() -> Bool {
        pingPongMode && (player?.currentItem?.canPlayReverse == true)
    }

    private func handle(time: CMTime) {
        guard let p = player, !userPaused, !finished else { return }
        let start = effectiveStart()
        let end = effectiveEnd()
        guard end.isNumeric else { return }

        if direction > 0 {
            if CMTimeCompare(time, CMTimeSubtract(end, edgeEpsilon)) >= 0 {
                if pingPongActive() {
                    flipToReverse()
                } else if loopPlayback {
                    loopToStart(p)
                } else {
                    finishPlayback()
                }
            }
        } else {
            if CMTimeCompare(time, CMTimeAdd(start, edgeEpsilon)) <= 0 {
                if loopPlayback {
                    flipToForward()
                } else {
                    finishPlayback()
                }
            }
        }
    }

    private func handleReachedEnd() {
        guard let p = player, !userPaused, !finished else { return }
        if pingPongActive() {
            flipToReverse()
        } else if loopPlayback {
            loopToStart(p)
        } else {
            finishPlayback()
        }
    }

    private func finishPlayback() {
        player?.pause()
        finished = true
    }

    func setLoopPlayback(_ on: Bool) {
        loopPlayback = on
        if on, finished, let url = currentURL {
            start(url: url)
        }
    }

    private func loopToStart(_ p: AVPlayer) {
        guard !isRewinding else { return }
        isRewinding = true
        p.seek(to: effectiveStart(), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self = self else { return }
            self.isRewinding = false
            self.direction = 1.0
            p.play()
        }
    }

    private func flipToReverse() {
        guard let p = player else { return }
        direction = -1.0
        p.rate = -1.0
    }

    private func flipToForward() {
        guard let p = player else { return }
        direction = 1.0
        p.rate = 1.0
    }
}
