import SwiftUI

/// 滚动歌词文本视图：用 AnimationTimelineSchedule 驱动连续 marquee 滚动。
/// AnimationTimelineSchedule 是 SwiftUI 给 Widget/Live Activity 专用的动画 schedule，
/// 系统允许它以较高频率更新（比 .periodic 高），实现平滑滚动。
struct ScrollingLyricText: View {
    let text: String
    let fontSize: CGFloat
    let maxWidth: CGFloat
    let color: Color

    var body: some View {
        if text.isEmpty {
            Color.clear.frame(width: maxWidth, height: fontSize + 2)
        } else {
            // 估算文字宽度：CJK ≈ 字号，英文 ≈ 0.55
            let isCJK = text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
            let charWidth = fontSize * (isCJK ? 1.0 : 0.55)
            let textWidth = CGFloat(text.count) * charWidth

            if textWidth <= maxWidth {
                // 短文本：居中显示，不滚动
                Text(text)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .frame(maxWidth: maxWidth)
            } else {
                // 长文本：marquee 滚动（从右到左循环）
                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let scrollDistance = textWidth + maxWidth
                    let speed: CGFloat = 30 // px/s
                    let period = Double(scrollDistance / speed)
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
}
