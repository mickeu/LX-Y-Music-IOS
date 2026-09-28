import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.2, *)
struct LyricsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LyricsActivityAttributes.self) { context in
            LockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.songName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(context.state.artist)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LyricTimelineView(state: context.state, maxWidth: 260)
                }
            } compactLeading: {
                Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            } compactTrailing: {
                LyricTimelineView(state: context.state, maxWidth: 120)
            } minimal: {
                LyricTimelineView(state: context.state, maxWidth: 40)
            }
        }
    }
}

/// 歌词时间线视图：TimelineView 驱动刷新，LRC 解析在外层缓存（不在每帧重解析）
struct LyricTimelineView: View {
    let state: LyricsActivityAttributes.ContentState
    let maxWidth: CGFloat

    // 缓存：只在 lrcText 变化时重新解析
    @State private var cachedLrcText: String = ""
    @State private var cachedLines: [LrcLine] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            // 每帧只读 AppGroup 快照 + 二分查找，不重解析 LRC
            let lyric = currentLyric(date: timeline.date)
            ScrollingLyricText(
                text: lyric,
                fontSize: CGFloat(state.fontSize),
                maxWidth: maxWidth,
                color: .white,
                date: timeline.date
            )
        }
    }

    private func currentLyric(date: Date) -> String {
        guard let snapshot = LyricsSharedData.load() else { return state.songName }
        // LRC 文本变化时才重新解析
        if snapshot.lrcText != cachedLrcText {
            cachedLrcText = snapshot.lrcText
            cachedLines = LrcParser.parse(snapshot.lrcText)
        }
        guard !cachedLines.isEmpty else { return state.songName }
        let time = LyricsSharedData.estimatedCurrentTime(snapshot: snapshot)
        let idx = LyricsSharedData.currentLineIndex(at: time, in: cachedLines)
        guard idx >= 0 else { return state.songName }
        return cachedLines[idx].text
    }
}

/// 锁屏 / 桌面 Live Activity 视图
struct LockScreenView: View {
    let state: LyricsActivityAttributes.ContentState
    @State private var cachedLrcText: String = ""
    @State private var cachedLines: [LrcLine] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            let lyric = currentLyric(date: timeline.date)
            ZStack {
                LinearGradient(colors: [.black.opacity(0.95), .black], startPoint: .leading, endPoint: .trailing)
                VStack(alignment: .center, spacing: 6) {
                    HStack {
                        Text(state.songName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: state.isPlaying ? "music.note" : "pause.circle.fill")
                            .foregroundColor(.green)
                    }
                    ScrollingLyricText(
                        text: lyric,
                        fontSize: CGFloat(state.fontSize),
                        maxWidth: 280,
                        color: .white,
                        date: timeline.date
                    )
                }
                .padding(16)
            }
        }
    }

    private func currentLyric(date: Date) -> String {
        guard let snapshot = LyricsSharedData.load() else { return state.songName }
        if snapshot.lrcText != cachedLrcText {
            cachedLrcText = snapshot.lrcText
            cachedLines = LrcParser.parse(snapshot.lrcText)
        }
        guard !cachedLines.isEmpty else { return state.songName }
        let time = LyricsSharedData.estimatedCurrentTime(snapshot: snapshot)
        let idx = LyricsSharedData.currentLineIndex(at: time, in: cachedLines)
        guard idx >= 0 else { return state.songName }
        return cachedLines[idx].text
    }
}
