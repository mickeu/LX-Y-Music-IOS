import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.2, *)
struct LyricsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LyricsActivityAttributes.self) { context in
            // 锁屏/桌面 Live Activity 视图
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
                    Text(context.state.currentLyric)
                        .font(.system(size: CGFloat(context.state.fontSize), weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
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
                // 展开模式（大窗口）
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
                    Text(context.state.currentLyric)
                        .font(.system(size: CGFloat(context.state.fontSize), weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            } compactLeading: {
                // 紧凑模式左侧：图标
                Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            } compactTrailing: {
                // 紧凑模式右侧：歌词滚动
                // 用 TimelineView 实现从右往左滚动
                RollingText(text: context.state.currentLyric, fontSize: 11, maxWidth: 120)
            } minimal: {
                // 最小模式：只显示3个字，滚动
                RollingText(text: context.state.currentLyric, fontSize: 9, maxWidth: 36, maxChars: 3)
            }
        }
    }
}

// 滚动文本组件：从右往左滚动显示
struct RollingText: View {
    let text: String
    let fontSize: CGFloat
    let maxWidth: CGFloat
    var maxChars: Int? = nil

    var displayText: String {
        if let maxChars = maxChars, text.count > maxChars {
            return String(text.prefix(maxChars))
        }
        return text
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.3)) { timeline in
            let offset = calculateOffset(date: timeline.date)
            Text(displayText)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: maxWidth)
                .clipped()
                .offset(x: offset)
        }
    }

    // 计算滚动偏移量：从右往左循环
    private func calculateOffset(date: Date) -> CGFloat {
        let textWidth = estimateTextWidth()
        if textWidth <= maxWidth { return 0 }
        let cycle = textWidth + maxWidth
        let elapsed = date.timeIntervalSinceReferenceDate
        let progress = CGFloat(elapsed.truncatingRemainder(dividingBy: Double(cycle / 20))) / (cycle / 20)
        return maxWidth - progress * cycle
    }

    private func estimateTextWidth() -> CGFloat {
        return CGFloat(displayText.count) * fontSize * 0.6
    }
}
