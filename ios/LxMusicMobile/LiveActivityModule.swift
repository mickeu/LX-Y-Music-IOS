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
    private var currentScrollOffset: Double = 0
    private var currentLyricText = ""
    private var currentNextLyric = ""
    private var currentIsPlaying = true
    private var lyricTimer: Timer?
    private var lyricCallback: (() -> (String, String, Bool, Double))?
    private var lyricTimer: Timer?
    private var lyricCallback: (() -> (String, String, Bool, Double))?
    private var currentLyricText = ""
    private var currentNextLyric = ""
    private var currentIsPlaying = true
    private var currentLyricText = ""
    private var currentNextLyric = ""
    private var currentIsPlaying = true
    private var currentLyricText = ""
    private var currentNextLyric = ""
    private var currentIsPlaying = true
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
        currentScrollOffset = 0

        Task {
            await endAllActivities()
            let initLyric = pendingLyric.isEmpty ? songName : pendingLyric
            let attributes = LyricsActivityAttributes(id: UUID().uuidString)
            let state = LyricsActivityAttributes.ContentState(
                songName: songName, artist: artist,
                currentLyric: initLyric, nextLyric: "",
                fontSize: fontSize, isPlaying: true,
                scrollOffset: 0
            )
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
                // 等待一小段时间确保 Activity 完全就绪
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
                currentActivity = activity
                resolve(true)
            } catch {
                NSLog("[LiveActivity] 启动失败: \(error)")
                resolve(false)
            }
        }
    }

    // 更新歌词 + 滚动偏移量
    @objc(updateLyric:nextLyric:isPlaying:scrollOffset:)
    func updateLyric(lyric: String, nextLyric: String, isPlaying: Bool, scrollOffset: Double) {
        let displayLyric = lyric.isEmpty ? songName : lyric
        guard let activity = currentActivity else {
            pendingLyric = displayLyric
            currentScrollOffset = scrollOffset
            return
        }
        pendingLyric = ""
        currentScrollOffset = scrollOffset
        currentLyricText = displayLyric
        currentNextLyric = nextLyric
        currentIsPlaying = isPlaying
        let state = LyricsActivityAttributes.ContentState(
            songName: songName, artist: artist,
            currentLyric: displayLyric, nextLyric: nextLyric,
            fontSize: currentFontSize, isPlaying: isPlaying,
            scrollOffset: scrollOffset
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    // 兼容旧调用（无 scrollOffset）
    @objc(updateLyric:nextLyric:isPlaying:)
    func updateLyric(lyric: String, nextLyric: String, isPlaying: Bool) {
        updateLyric(lyric: lyric, nextLyric: nextLyric, isPlaying: isPlaying, scrollOffset: 0)
    }

    @objc(updateFontSize:)
    func updateFontSize(fontSize: Int) {
        self.currentFontSize = fontSize
        guard let activity = currentActivity else {
            NSLog("[LiveActivity] updateFontSize: no active activity")
            return
        }
        let displayLyric = pendingLyric.isEmpty ? songName : pendingLyric
        let state = LyricsActivityAttributes.ContentState(
            songName: songName, artist: artist,
            currentLyric: displayLyric, nextLyric: "",
            fontSize: fontSize, isPlaying: true,
            scrollOffset: currentScrollOffset
        )
        NSLog("[LiveActivity] updateFontSize: \(fontSize)")
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
