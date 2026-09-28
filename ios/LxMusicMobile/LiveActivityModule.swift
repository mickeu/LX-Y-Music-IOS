import Foundation
import ActivityKit
import React

@available(iOS 16.2, *)
@objc(LiveActivityModule)
class LiveActivityModule: NSObject, RCTBridgeModule {
    static func moduleName() -> String { "LiveActivityModule" }
    @objc static func requiresMainQueueSetup() -> Bool { false }

    private var currentActivity: Activity<LyricsActivityAttributes>?
    private let suiteName = "group.com.LX-YMusic.shuhao"

    private func endAllActivities() async {
        for activity in Activity<LyricsActivityAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }

    /// 写歌词数据到 AppGroup，Widget Extension 读取后自行解析 LRC + 算换行
    @objc(writeLyricData:songName:artist:currentTime:duration:isPlaying:)
    func writeLyricData(lrc: String, songName: String, artist: String,
                        currentTime: Double, duration: Double, isPlaying: Bool) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            NSLog("[LiveActivity] AppGroup unavailable")
            return
        }
        defaults.set(lrc, forKey: "lyric")
        defaults.set(songName, forKey: "songName")
        defaults.set(artist, forKey: "artist")
        defaults.set(currentTime, forKey: "currentTime")
        defaults.set(duration, forKey: "duration")
        defaults.set(isPlaying, forKey: "isPlaying")
        defaults.set(Date(), forKey: "lastUpdate")
    }

    /// 写字号到 AppGroup
    @objc(writeFontSize:)
    func writeFontSize(fontSize: Int) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(fontSize, forKey: "fontSize")
    }

    @objc(startLyricsActivity:songName:artist:fontSize:resolve:reject:)
    func startLyricsActivity(lrc: String, songName: String, artist: String, fontSize: Int,
                             resolve: @escaping RCTPromiseResolveBlock,
                             reject: @escaping RCTPromiseRejectBlock) {
        // 先把歌词数据写入 AppGroup（含 currentTime/duration/isPlaying，避免 1 秒空窗）
        if let defaults = UserDefaults(suiteName: suiteName) {
            defaults.set(lrc, forKey: "lyric")
            defaults.set(songName, forKey: "songName")
            defaults.set(artist, forKey: "artist")
            defaults.set(fontSize, forKey: "fontSize")
            defaults.set(0.0, forKey: "currentTime")
            defaults.set(0.0, forKey: "duration")
            defaults.set(true, forKey: "isPlaying")
            defaults.set(Date(), forKey: "lastUpdate")
        }

        Task {
            await endAllActivities()
            let attributes = LyricsActivityAttributes(id: UUID().uuidString)
            let state = LyricsActivityAttributes.ContentState(
                songName: songName, artist: artist,
                fontSize: fontSize, isPlaying: true
            )
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil, relevanceScore: 1.0)
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

    /// 更新播放状态（暂停/恢复/切歌时调用）
    @objc(updatePlaybackState:currentTime:isPlaying:)
    func updatePlaybackState(songName: String, currentTime: Double, isPlaying: Bool) {
        guard let activity = currentActivity else { return }
        if let defaults = UserDefaults(suiteName: suiteName) {
            defaults.set(currentTime, forKey: "currentTime")
            defaults.set(isPlaying, forKey: "isPlaying")
            defaults.set(Date(), forKey: "lastUpdate")
        }
        // 更新 ContentState（触发 Widget 重新读取 AppGroup）
        let state = LyricsActivityAttributes.ContentState(
            songName: songName,
            artist: (UserDefaults(suiteName: suiteName)?.string(forKey: "artist")) ?? "",
            fontSize: (UserDefaults(suiteName: suiteName)?.integer(forKey: "fontSize")) ?? 15,
            isPlaying: isPlaying
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil, relevanceScore: 1.0))
        }
    }

    @objc(endLyricsActivity)
    func endLyricsActivity() {
        Task {
            await endAllActivities()
        }
    }

    @objc(isAvailable:reject:)
    func isAvailable(resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(ActivityAuthorizationInfo().areActivitiesEnabled)
    }
}
