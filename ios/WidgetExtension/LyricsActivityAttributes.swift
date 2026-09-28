import Foundation
import ActivityKit

@available(iOS 16.2, *)
public struct LyricsActivityAttributes: ActivityAttributes {
    public struct ContentState: Hashable, Codable {
        var songName: String
        var artist: String
        var fontSize: Int
        var isPlaying: Bool
    }
    var id: String
}
