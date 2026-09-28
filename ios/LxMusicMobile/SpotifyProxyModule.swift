import Foundation
import React

@objc(SpotifyProxyModule)
class SpotifyProxyModule: NSObject, RCTBridgeModule {
    static func moduleName() -> String { "SpotifyProxyModule" }
    @objc static func requiresMainQueueSetup() -> Bool { false }

    @objc(start)
    func start() {
        SpotifyProxyServer.shared.start()
    }

    @objc(stop)
    func stop() {
        SpotifyProxyServer.shared.stop()
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
