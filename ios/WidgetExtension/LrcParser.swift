import Foundation

/// LRC 歌词行
struct LrcLine: Hashable {
    let time: TimeInterval   // 该行开始时间（秒）
    let text: String         // 歌词文本
}

/// LRC 解析器：解析标准 LRC 格式，提取时间戳和歌词文本。
/// 支持多时间标签行（如 `[00:01.00][00:15.00]歌词`）和翻译行 `[tr:...]`（忽略）。
struct LrcParser {
    /// 时间标签正则：[mm:ss.xx] 或 [mm:ss.xxx]
    private static let timePattern = #"\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]"#

    /// 解析 LRC 文本，返回按时间排序的歌词行数组
    static func parse(_ lrc: String) -> [LrcLine] {
        guard !lrc.isEmpty else { return [] }
        let regex = try? NSRegularExpression(pattern: timePattern)
        var lines: [LrcLine] = []

        for rawLine in lrc.components(separatedBy: .newlines) {
            // 跳过翻译/罗马音/逐字标签行
            if rawLine.contains("[tr:") || rawLine.contains("[tt]") || rawLine.hasPrefix("[al:")
                || rawLine.hasPrefix("[ar:") || rawLine.hasPrefix("[ti:") || rawLine.hasPrefix("[by:")
                || rawLine.hasPrefix("[offset:") || rawLine.hasPrefix("[length:") {
                continue
            }

            guard let regex = regex else { continue }
            let nsLine = rawLine as NSString
            let matches = regex.matches(in: rawLine, range: NSRange(location: 0, length: nsLine.length))
            if matches.isEmpty { continue }

            // 提取所有时间标签
            var times: [TimeInterval] = []
            for m in matches {
                let minStr = nsLine.substring(with: m.range(at: 1))
                let secStr = nsLine.substring(with: m.range(at: 2))
                let fracStr = m.range(at: 3).location == NSNotFound ? "" : nsLine.substring(with: m.range(at: 3))
                let mins = Double(minStr) ?? 0
                let secs = Double(secStr) ?? 0
                var frac = 0.0
                if !fracStr.isEmpty {
                    frac = Double("0." + fracStr) ?? 0
                }
                times.append(mins * 60 + secs + frac)
            }

            // 提取歌词文本（最后一个时间标签之后的内容）
            let lastMatchEnd = matches.last!.range.location + matches.last!.range.length
            let text = nsLine.substring(from: lastMatchEnd).trimmingCharacters(in: .whitespaces)

            guard !text.isEmpty else { continue }

            for t in times {
                lines.append(LrcLine(time: t, text: text))
            }
        }

        lines.sort { $0.time < $1.time }
        return lines
    }
}

/// 歌词数据共享：通过 AppGroup UserDefaults 在 App 和 Widget 间传递
struct LyricsSharedData {
    static let suiteName = "group.com.LX-YMusic.shuhao"
    static let lrcKey = "lyric"
    static let songNameKey = "songName"
    static let artistKey = "artist"
    static let currentTimeKey = "currentTime"
    static let durationKey = "duration"
    static let fontSizeKey = "fontSize"
    static let isPlayingKey = "isPlaying"
    static let lastUpdateKey = "lastUpdate"

    struct Snapshot {
        let lrcText: String
        let songName: String
        let artist: String
        let currentTime: TimeInterval
        let duration: TimeInterval
        let fontSize: Int
        let isPlaying: Bool
        let lastUpdate: Date
    }

    static func load() -> Snapshot? {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
        let lrcText = defaults.string(forKey: lrcKey) ?? ""
        let songName = defaults.string(forKey: songNameKey) ?? ""
        let artist = defaults.string(forKey: artistKey) ?? ""
        let currentTime = defaults.double(forKey: currentTimeKey)
        let duration = defaults.double(forKey: durationKey)
        let fontSize = defaults.integer(forKey: fontSizeKey)
        let isPlaying = defaults.bool(forKey: isPlayingKey)
        let lastUpdate = defaults.object(forKey: lastUpdateKey) as? Date ?? Date.distantPast
        return Snapshot(
            lrcText: lrcText, songName: songName, artist: artist,
            currentTime: currentTime, duration: duration,
            fontSize: fontSize == 0 ? 15 : fontSize, isPlaying: isPlaying,
            lastUpdate: lastUpdate
        )
    }

    /// 根据播放进度估算当前时间（考虑 App 最后更新到现在的流逝时间）
    static func estimatedCurrentTime(snapshot: Snapshot) -> TimeInterval {
        let elapsed = Date().timeIntervalSince(snapshot.lastUpdate)
        return snapshot.isPlaying ? snapshot.currentTime + elapsed : snapshot.currentTime
    }

    /// 二分查找：给定时间对应的歌词行索引
    static func currentLineIndex(at time: TimeInterval, in lines: [LrcLine]) -> Int {
        guard !lines.isEmpty else { return -1 }
        if time < lines[0].time { return -1 }
        var lo = 0, hi = lines.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if lines[mid].time <= time { lo = mid } else { hi = mid - 1 }
        }
        return lo
    }
}
