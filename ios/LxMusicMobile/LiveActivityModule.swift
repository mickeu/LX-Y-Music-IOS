import Foundation
import ActivityKit
import React

@available(iOS 16.1, *)
@objc(LiveActivityModule)
class LiveActivityModule: NSObject, RCTBridgeModule {
    static func moduleName() -> String { "LiveActivityModule" }
    @objc static func requiresMainQueueSetup() -> Bool { false }

    private var currentActivity: Activity<LyricsActivityAttributes>?
    private var songName = ""
    private var artist = ""
    private var currentFontSize = 15

    // 启动灵动岛歌词 Live Activity
    @objc(startLyricsActivity:artist:fontSize:)
    func startLyricsActivity(songName: String, artist: String, fontSize: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            NSLog("[LiveActivity] 灵动岛权限未开启")
            return
        }
        self.songName = songName
        self.artist = artist
        self.currentFontSize = fontSize

        // 停止之前的
        endLyricsActivity()

        let attributes = LyricsActivityAttributes(id: UUID().uuidString)
        let state = LyricsActivityAttributes.ContentState(
            songName: songName,
            artist: artist,
            currentLyric: "",
            nextLyric: "",
            fontSize: fontSize,
            isPlaying: true
        )
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            NSLog("[LiveActivity] 启动成功")
        } catch {
            NSLog("[LiveActivity] 启动失败: \(error)")
        }
    }

    // 更新歌词
    @objc(updateLyric:nextLyric:isPlaying:)
    func updateLyric(lyric: String, nextLyric: String, isPlaying: Bool) {
        guard let activity = currentActivity else { return }
        let state = LyricsActivityAttributes.ContentState(
            songName: songName,
            artist: artist,
            currentLyric: lyric,
            nextLyric: nextLyric,
            fontSize: currentFontSize,
            isPlaying: isPlaying
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    // 更新字号
    @objc(updateFontSize:)
    func updateFontSize(fontSize: Int) {
        guard let activity = currentActivity else { return }
        self.currentFontSize = fontSize
        let state = LyricsActivityAttributes.ContentState(
            songName: songName,
            artist: artist,
            currentLyric: "",
            nextLyric: "",
            fontSize: fontSize,
            isPlaying: true
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    // 更新播放状态
    @objc(updatePlaying:)
    func updatePlaying(isPlaying: Bool) {
        guard let activity = currentActivity else { return }
        let state = LyricsActivityAttributes.ContentState(
            songName: songName,
            artist: artist,
            currentLyric: "",
            nextLyric: "",
            fontSize: currentFontSize,
            isPlaying: isPlaying
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    // 结束 Live Activity
    @objc(endLyricsActivity)
    func endLyricsActivity() {
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    // 检查灵动岛是否可用
    @objc(isAvailable:reject:)
    func isAvailable(resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(ActivityAuthorizationInfo().areActivitiesEnabled)
    }
}
