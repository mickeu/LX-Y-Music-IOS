import SwiftUI

/// 滚动歌词文本：接收外部 TimelineView 的 date 来算 marquee 偏移。
/// 不再自己包 TimelineView——外层统一用一个 TimelineView 驱动读歌词+动画。
struct ScrollingLyricText: View {
    let text: String
    let fontSize: CGFloat
    let maxWidth: CGFloat
    let color: Color
    let date: Date

    var body: some View {
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
                // marquee：从右到左循环滚动
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
