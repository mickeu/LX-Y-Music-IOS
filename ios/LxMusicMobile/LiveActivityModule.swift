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
    // 缓存：Activity 创建前的歌词，创建后立即写入
    private var pendingLyric = ""

    // 启动灵动岛歌词 Live Activity（Promise，确保创建完成后才 resolve）
    @objc(startLyricsActivity:artist:fontSize:resolve:reject:)
    func startLyricsActivity(songName: String, artist: String, fontSize: Int,
                             resolve: @escaping RCTPromiseResolveBlock,
                             reject: @escaping RCTPromiseRejectBlock) {
        self.songName = songName
        self.artist = artist
        self.currentFontSize = fontSize

        let oldActivity = currentActivity
        currentActivity = nil

        Task {
            // 先结束旧 Activity（确保同时只有一个）
            await oldActivity?.end(dismissalPolicy: .immediate)

            // 再创建新的，初始歌词用歌曲名（无歌词时也显示）
            let initLyric = pendingLyric.isEmpty ? songName : pendingLyric
            let attributes = LyricsActivityAttributes(id: UUID().uuidString)
            let state = LyricsActivityAttributes.ContentState(
                songName: songName,
                artist: artist,
                currentLyric: initLyric,
                nextLyric: "",
                fontSize: fontSize,
                isPlaying: true
            )
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
                NSLog("[LiveActivity] 启动成功: \(songName)")
                resolve(true)
            } catch {
                NSLog("[LiveActivity] 启动失败: \(error)")
                resolve(false)
            }
        }
    }

    // 更新歌词
    @objc(updateLyric:nextLyric:isPlaying:)
    func updateLyric(lyric: String, nextLyric: String, isPlaying: Bool) {
        let displayLyric = lyric.isEmpty ? songName : lyric
        guard let activity = currentActivity else {
            // Activity 还没创建，缓存歌词，创建后写入
            pendingLyric = displayLyric
            NSLog("[LiveActivity] 缓存歌词: \(displayLyric)")
            return
        }
        pendingLyric = ""
        let state = LyricsActivityAttributes.ContentState(
            songName: songName,
            artist: artist,
            currentLyric: displayLyric,
            nextLyric: nextLyric,
            fontSize: currentFontSize,
            isPlaying: isPlaying
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    // 更新字号（保留当前歌词，不重置）
    @objc(updateFontSize:)
    func updateFontSize(fontSize: Int) {
        self.currentFontSize = fontSize
        guard let activity = currentActivity else { return }
        let state = LyricsActivityAttributes.ContentState(
            songName: songName,
            artist: artist,
            currentLyric: pendingLyric.isEmpty ? songName : pendingLyric,
            nextLyric: "",
            fontSize: fontSize,
            isPlaying: true
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
            pendingLyric = ""
        }
    }

    // 检查灵动岛是否可用
    @objc(isAvailable:reject:)
    func isAvailable(resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(ActivityAuthorizationInfo().areActivitiesEnabled)
    }
}
