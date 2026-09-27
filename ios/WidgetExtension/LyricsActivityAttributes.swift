import Foundation
import ActivityKit

@available(iOS 16.2, *)
public struct LyricsActivityAttributes: ActivityAttributes {
    public struct ContentState: Hashable, Codable {
        var songName: String
        var artist: String
        var currentLyric: String
        var nextLyric: String
        var fontSize: Int
        var isPlaying: Bool
        // 滚动偏移量（像素）：正值=文字在右边，负值=文字向左移动
        var scrollOffset: Double
    }
    var id: String
}
