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
            return
        }
        pendingLyric = ""
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
        let displayLyric = pendingLyric.isEmpty ? songName : pendingLyric
        let state = LyricsActivityAttributes.ContentState(
            songName: songName, artist: artist,
            currentLyric: displayLyric, nextLyric: "",
            fontSize: fontSize, isPlaying: true
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
