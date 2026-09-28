import Foundation
import React

@objc(SpotifyProxyModule)
class SpotifyProxyModule: RCTEventEmitter {

    private var observer: NSObjectProtocol?
    private var hasListeners = false

    override func supportedEvents() -> [String] {
        return ["SpotifyPlayMedia"]
    }

    override func startObserving() {
        hasListeners = true
    }

    override func stopObserving() {
        hasListeners = false
    }

    @objc(start)
    func start() {
        SpotifyProxyServer.shared.start()
        // 监听快捷指令事件
        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LXSpotifyPlayMedia"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, self.hasListeners else { return }
            let items = notification.userInfo?["mediaItems"] as? [String] ?? []
            let shuffled = notification.userInfo?["playShuffled"] as? Bool ?? false
            self.sendEvent(withName: "SpotifyPlayMedia", body: [
                "mediaItems": items,
                "playShuffled": shuffled
            ])
        }
    }

    @objc(stop)
    func stop() {
        SpotifyProxyServer.shared.stop()
        if let o = observer {
            NotificationCenter.default.removeObserver(o)
            observer = nil
        }
    }

    @objc(updateInfo:songName:artist:progressMs:durationMs:isPlaying:)
    func updateInfo(trackId: String, songName: String, artist: String,
                    progressMs: Int, durationMs: Int, isPlaying: Bool) {
        let s = SpotifyProxyServer.shared
        s.songName = songName
        s.artist = artist
        s.progressMs = progressMs
        s.durationMs = durationMs
        s.isPlaying = isPlaying
    }
}
