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
                    // 歌词：用 fontSize，fixedSize+clipped 去掉 ...
                    Text(context.state.currentLyric)
                        .font(.system(size: CGFloat(context.state.fontSize), weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
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
                    // 歌词用用户设置的 fontSize，不截断
                    Text(context.state.currentLyric)
                        .font(.system(size: CGFloat(context.state.fontSize), weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            } compactTrailing: {
                // 紧凑模式：歌词从右往左滚动，不带 ...
                ScrollingLyric(text: context.state.currentLyric, fontSize: 11, maxWidth: 120)
            } minimal: {
                // 最小模式：歌词滚动，不带 ...，根据字号自动裁剪
                ScrollingLyric(text: context.state.currentLyric, fontSize: 9, maxWidth: 36)
            }
        }
    }
}

// 滚动歌词：fixedSize + clipped 去掉 ...，TimelineView 从右往左滚动
struct ScrollingLyric: View {
    let text: String
    let fontSize: CGFloat
    let maxWidth: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.3)) { timeline in
            let textWidth = estimateWidth()
            if textWidth <= maxWidth {
                // 文字短于容器，居中显示
                Text(text)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: maxWidth)
                    .clipped()
            } else {
                // 文字长于容器，从右往左滚动
                let offset = calcOffset(date: timeline.date, textWidth: textWidth)
                Text(text)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: offset)
                    .frame(maxWidth: maxWidth, alignment: .leading)
                    .clipped()
            }
        }
    }

    private func calcOffset(date: Date, textWidth: CGFloat) -> CGFloat {
        let cycle = textWidth + maxWidth
        let speed: CGFloat = 15
        let elapsed = CGFloat(date.timeIntervalSinceReferenceDate)
        let progress = (elapsed * speed).truncatingRemainder(dividingBy: Double(cycle))
        return maxWidth - progress
    }

    private func estimateWidth() -> CGFloat {
        return CGFloat(text.count) * fontSize * 0.55
    }
}
