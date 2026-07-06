import Cocoa
import AVKit

final class WallpaperWindow: NSWindow {
    private let playerView = AVPlayerView()

    init(screen: NSScreen) {
        super.init(contentRect: screen.frame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)

        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = true
        self.backgroundColor = .black
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isReleasedWhenClosed = false
        self.setFrame(screen.frame, display: true)

        playerView.frame = self.contentRect(forFrameRect: self.frame)
        playerView.autoresizingMask = [.width, .height]
        playerView.controlsStyle = .none
        playerView.videoGravity = .resizeAspectFill
        self.contentView?.addSubview(playerView)
    }

    func attach(player: AVPlayer) {
        playerView.player = player
    }

    func updateFrame(to screen: NSScreen) {
        self.setFrame(screen.frame, display: true)
    }
}
