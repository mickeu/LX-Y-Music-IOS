import Foundation
import ActivityKit
import React

@available(iOS 16.2, *)
@objc(LiveActivityModule)
class LiveActivityModule: NSObject, RCTBridgeModule {
    static func moduleName() -> String { "LiveActivityModule" }
    @objc static func requiresMainQueueSetup() -> Bool { false }

    private var currentActivity: Activity<LyricsActivityAttributes>?
    private var songName = ""
    private var artist = ""
    private var currentFontSize = 15
    private var pendingLyric = ""
    // 保存当前歌词状态，updateFontSize 时复用（避免覆盖当前播放的歌词/播放状态）
    private var currentLyricText = ""
    private var currentNextLyric = ""
    private var currentIsPlaying = true

    private func endAllActivities() async {
        for activity in Activity<LyricsActivityAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }

    @objc(startLyricsActivity:artist:fontSize:resolve:reject:)
    func startLyricsActivity(songName: String, artist: String, fontSize: Int,
                             resolve: @escaping RCTPromiseResolveBlock,
                             reject: @escaping RCTPromiseRejectBlock) {
        self.songName = songName
        self.artist = artist
        self.currentFontSize = fontSize

        Task {
            await endAllActivities()
            let initLyric = pendingLyric.isEmpty ? songName : pendingLyric
            let attributes = LyricsActivityAttributes(id: UUID().uuidString)
            let state = LyricsActivityAttributes.ContentState(
                songName: songName, artist: artist,
                currentLyric: initLyric, nextLyric: "",
                fontSize: fontSize, isPlaying: true
            )
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
                try? await Task.sleep(nanoseconds: 500_000_000)
                currentActivity = activity
                resolve(true)
            } catch {
                NSLog("[LiveActivity] 启动失败: \(error)")
                resolve(false)
            }
        }
    }

    // 换行时调用：只推当前歌词文本，滚动动画由 Widget 内 TimelineView 自己做
    @objc(updateLyric:nextLyric:isPlaying:)
    func updateLyric(lyric: String, nextLyric: String, isPlaying: Bool) {
        let displayLyric = lyric.isEmpty ? songName : lyric
        guard let activity = currentActivity else {
            pendingLyric = displayLyric
            currentLyricText = displayLyric
            currentNextLyric = nextLyric
            currentIsPlaying = isPlaying
            return
        }
        pendingLyric = ""
        currentLyricText = displayLyric
        currentNextLyric = nextLyric
        currentIsPlaying = isPlaying
        let state = LyricsActivityAttributes.ContentState(
            songName: songName, artist: artist,
            currentLyric: displayLyric, nextLyric: nextLyric,
            fontSize: currentFontSize, isPlaying: isPlaying
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    @objc(updateFontSize:)
    func updateFontSize(fontSize: Int) {
        self.currentFontSize = fontSize
        guard let activity = currentActivity else { return }
        // 复用当前歌词/播放状态，只改字号（避免调字号时把歌词覆盖成歌名）
        let state = LyricsActivityAttributes.ContentState(
            songName: songName, artist: artist,
            currentLyric: currentLyricText.isEmpty ? songName : currentLyricText,
            nextLyric: currentNextLyric,
            fontSize: fontSize, isPlaying: currentIsPlaying
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    @objc(endLyricsActivity)
    func endLyricsActivity() {
        Task {
            await endAllActivities()
            pendingLyric = ""
        }
    }

    @objc(isAvailable:reject:)
    func isAvailable(resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(ActivityAuthorizationInfo().areActivitiesEnabled)
    }
}
