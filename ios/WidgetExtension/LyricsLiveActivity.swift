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
                    ScrollingLyricText(
                        text: currentLyricText(state: context.state),
                        fontSize: CGFloat(context.state.fontSize),
                        maxWidth: 260,
                        color: .white
                    )
                }
            } compactLeading: {
                Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            } compactTrailing: {
                ScrollingLyricText(
                    text: currentLyricText(state: context.state),
                    fontSize: CGFloat(context.state.fontSize),
                    maxWidth: 120,
                    color: .white
                )
            } minimal: {
                ScrollingLyricText(
                    text: currentLyricText(state: context.state),
                    fontSize: CGFloat(context.state.fontSize),
                    maxWidth: 40,
                    color: .white
                )
            }
        }
    }

    /// 从 AppGroup 读取歌词数据，根据当前播放进度找到当前行歌词文本。
    /// 如果 AppGroup 没有歌词数据，回退到 songName。
    private func currentLyricText(state: LyricsActivityAttributes.ContentState) -> String {
        guard let snapshot = LyricsSharedData.load() else {
            return state.songName
        }
        let lines = LrcParser.parse(snapshot.lrcText)
        guard !lines.isEmpty else { return state.songName }
        let time = LyricsSharedData.estimatedCurrentTime(snapshot: snapshot)
        let idx = LyricsSharedData.currentLineIndex(at: time, in: lines)
        guard idx >= 0 else { return state.songName }
        return lines[idx].text
    }
}

/// 锁屏 / 桌面 Live Activity 视图
struct LockScreenView: View {
    let state: LyricsActivityAttributes.ContentState

    var body: some View {
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
                    text: currentLyricText,
                    fontSize: CGFloat(state.fontSize),
                    maxWidth: 280,
                    color: .white
                )
            }
            .padding(16)
        }
    }

    private var currentLyricText: String {
        guard let snapshot = LyricsSharedData.load() else { return state.songName }
        let lines = LrcParser.parse(snapshot.lrcText)
        guard !lines.isEmpty else { return state.songName }
        let time = LyricsSharedData.estimatedCurrentTime(snapshot: snapshot)
        let idx = LyricsSharedData.currentLineIndex(at: time, in: lines)
        guard idx >= 0 else { return state.songName }
        return lines[idx].text
    }
}
