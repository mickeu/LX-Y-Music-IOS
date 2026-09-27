import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.2, *)
struct LyricsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LyricsActivityAttributes.self) { context in
            ZStack {
                LinearGradient(colors: [.black.opacity(0.95), .black], startPoint: .leading, endPoint: .trailing)
                VStack(alignment: .center, spacing: 8) {
                    HStack {
                        Text(context.state.songName).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        Spacer()
                        Image(systemName: context.state.isPlaying ? "music.note" : "pause.circle.fill").foregroundColor(.green)
                    }
                    Text(context.state.currentLyric)
                        .font(.system(size: CGFloat(context.state.fontSize), weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    if !context.state.nextLyric.isEmpty {
                        Text(context.state.nextLyric).font(.system(size: 13)).foregroundColor(.gray).lineLimit(1)
                    }
                }
                .padding(16)
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill").font(.system(size: 28)).foregroundColor(.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.songName).font(.system(size: 12, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                        Text(context.state.artist).font(.system(size: 10)).foregroundColor(.gray).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.currentLyric).font(.system(size: CGFloat(context.state.fontSize), weight: .medium)).foregroundColor(.white).multilineTextAlignment(.center).lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill").font(.system(size: 12)).foregroundColor(.green)
            } compactTrailing: {
                Text(context.state.currentLyric).font(.system(size: 11, weight: .medium)).foregroundColor(.white).lineLimit(1).frame(maxWidth: 100)
            } minimal: {
                Image(systemName: "music.note").font(.system(size: 14)).foregroundColor(.green)
            }
        }
    }
}
