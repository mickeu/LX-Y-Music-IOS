import ActivityKit
import WidgetKit
import SwiftUI

/// 滚动歌词文本：用 TimelineView 按帧重绘，从右往左循环滚动（marquee）。
/// 文字短于容器时居中不动，长于容器时滚动。无需外部推送 scrollOffset。
struct ScrollingLyricText: View {
    let text: String
    let fontSize: CGFloat
    let maxWidth: CGFloat
    let color: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { context in
            body(date: context.date)
        }
    }

    @ViewBuilder
    private func body(date: Date) -> some View {
        if text.isEmpty {
            Color.clear.frame(width: maxWidth, height: fontSize + 2)
        } else {
            let isCJK = text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
            let charWidth = fontSize * (isCJK ? 1.0 : 0.55)
            let textWidth = CGFloat(text.count) * charWidth
            if textWidth <= maxWidth {
                Text(text)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .frame(maxWidth: maxWidth)
            } else {
                let scrollDistance = textWidth + maxWidth
                let speed: CGFloat = 30
                let period = Double(scrollDistance / speed)
                let t = date.timeIntervalSinceReferenceDate
                let phase = t.truncatingRemainder(dividingBy: period) / period
                let offset = maxWidth - CGFloat(phase) * scrollDistance
                Text(text)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: offset)
                    .frame(maxWidth: maxWidth, alignment: .leading)
                    .clipped()
            }
        }
    }
}

@available(iOS 16.2, *)
struct LyricsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LyricsActivityAttributes.self) { context in
            // 锁屏 / 桌面 Live Activity（与灵动岛共用同一 ContentState，换行即刷新）
            ZStack {
                LinearGradient(colors: [.black.opacity(0.95), .black], startPoint: .leading, endPoint: .trailing)
                VStack(alignment: .center, spacing: 6) {
                    HStack {
                        Text(context.state.songName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: context.state.isPlaying ? "music.note" : "pause.circle.fill")
                            .foregroundColor(.green)
                    }
                    ScrollingLyricText(
                        text: context.state.currentLyric,
                        fontSize: CGFloat(context.state.fontSize),
                        maxWidth: 280,
                        color: .white
                    )
                    if !context.state.nextLyric.isEmpty {
                        Text(context.state.nextLyric)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .padding(16)
            }
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
                        text: context.state.currentLyric,
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
                    text: context.state.currentLyric,
                    fontSize: 11,
                    maxWidth: 120,
                    color: .white
                )
            } minimal: {
                ScrollingLyricText(
                    text: context.state.currentLyric,
                    fontSize: 9,
                    maxWidth: 40,
                    color: .white
                )
            }
        }
    }
}
