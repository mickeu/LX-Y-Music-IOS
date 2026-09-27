import {
  syncToTime as lrcSyncToTime,
  setLyric as lrcSetLyric,
  pause as lrcPause,
  setPlaybackRate as lrcSetPlaybackRate,
  toggleTranslation as lrcToggleTranslation,
  toggleRoma as lrcToggleRoma,
  init as lrcInit,
  addPlayHook,
  removePlayHook,
  getCurrentLyricText,
  getNextLyricText,
} from '@/plugins/lyric'
import {
  playDesktopLyric,
  setDesktopLyric,
  pauseDesktopLyric,
  setDesktopLyricPlaybackRate,
  toggleDesktopLyricTranslation,
  toggleDesktopLyricRoma,
} from '@/core/desktopLyric'
import { getPosition } from '@/plugins/player'
import playerState from '@/store/player/state'
import settingState from '@/store/setting/state'
import {
  startLyricsActivity,
  updateLiveActivityLyric,
  endLyricsActivity,
} from '@/utils/nativeModules/liveActivity'

/**
 * init lyric
 */
export const init = async () => {
  lrcInit()
  // 灵动岛歌词 hook：歌词逐行播放时同步到灵动岛
  addPlayHook(dynamicIslandLyricHook)
}

// 清理歌词文本：去除 LRC 时间标记、HTML 标签、多余空白
const cleanLyricText = (text: string): string => {
  if (!text) return ''
  // 去除 LRC 时间标记 [mm:ss.xxx]
  let cleaned = text.replace(/\[\d{2}:\d{2}\.\d{2,3}\]/g, '')
  // 去除 HTML 标签
  cleaned = cleaned.replace(/<[^>]+>/g, '')
  // 去除首尾空白
  return cleaned.trim()
}

// 灵动岛歌词状态
let dynamicIslandLyricHookActive = false
let lyricSyncTimer: ReturnType<typeof setInterval> | null = null
let scrollOffset = 0
let lastPushedLyric = ''
let lastPushAt = 0
const SCROLL_SPEED = 12       // 每秒滚动像素
const INITIAL_OFFSET = 40     // 起始偏移（文字从容器右侧进入）
const PUSH_INTERVAL = 300     // 推送间隔 ms（Live Activity 更新频率上限约 1s 内多次会被系统限流）

// 当前字号。pushLyricNow 用它估算文字宽度，必须先声明。
let fontSizeNow = 15

// hook 仅在"切到新行"时被 setPlayTime 调用，用于重置滚动起点。
// 注意：setPlayTime 对未换行的情况会直接 return，不回调 hook，
// 因此持续刷新必须靠 startLyricSyncTimer 轮询读取 getCurrentLyricText()。
const dynamicIslandLyricHook = (line: number, text: string) => {
  if (!settingState.setting['player.isDynamicIslandLyric']) return
  if (!dynamicIslandLyricHookActive) return
  const next = cleanLyricText(text)
  if (next !== lastPushedLyric) {
    lastPushedLyric = next
    scrollOffset = INITIAL_OFFSET // 新的一句从右侧重新开始
  }
}

// 把当前歌词 + 滚动偏移推送到实时活动
const pushLyricNow = () => {
  const raw = getCurrentLyricText()
  const lyric = cleanLyricText(raw) || playerState.musicInfo.name || ''
  const next = cleanLyricText(getNextLyricText())

  // 估算文字宽度决定是否需要滚动；短文本居中不动
  const textWidth = lyric.length * (fontSizeNow * 0.58)
  const needScroll = textWidth > INITIAL_OFFSET + 8
  if (needScroll) {
    scrollOffset -= SCROLL_SPEED
    if (scrollOffset < -(textWidth + 20)) scrollOffset = INITIAL_OFFSET
  } else {
    scrollOffset = 0
  }

  lastPushedLyric = lyric
  lastPushAt = Date.now()
  updateLiveActivityLyric(lyric, next, playerState.isPlay, scrollOffset).catch(() => {})
}

// 定时同步：主动读取播放进度 + 当前歌词行，驱动灵动岛持续刷新
const startLyricSyncTimer = () => {
  if (lyricSyncTimer) return
  lyricSyncTimer = setInterval(() => {
    if (!dynamicIslandLyricHookActive) return
    // 歌词位置按音频真实进度重算（未换行时内部会去重，不会重复回调 hook）
    void getPosition()
      .then((position) => {
        lrcSyncToTime(position * 1000, playerState.isPlay)
      })
      .catch(() => {})
      .then(() => {
        if (!playerState.isPlay) return
        setTimeout(pushLyricNow, 60) // 等 syncToTime 更新 currentLineData 后再读取
      })
  }, PUSH_INTERVAL)
}

const stopLyricSyncTimer = () => {
  if (lyricSyncTimer) {
    clearInterval(lyricSyncTimer)
    lyricSyncTimer = null
  }
}

// 启动/停止灵动岛 Live Activity
export const startDynamicIslandLyric = async () => {
  const enabled = settingState.setting['player.isDynamicIslandLyric']
  if (!enabled) return
  const info = playerState.musicInfo
  fontSizeNow = settingState.setting['player.dynamicIslandLyricFontSize'] ?? 15
  scrollOffset = INITIAL_OFFSET
  lastPushedLyric = ''
  // 等待 Activity 创建完成再激活（避免 currentActivity 为 nil 时更新丢失）
  await startLyricsActivity(info.name || '', info.singer || '', fontSizeNow)
  dynamicIslandLyricHookActive = true
  startLyricSyncTimer()
  setTimeout(pushLyricNow, 200)
}

export const stopDynamicIslandLyric = async () => {
  dynamicIslandLyricHookActive = false
  stopLyricSyncTimer()
  await endLyricsActivity()
}

/**
 * 更新灵动岛歌词字号。设置页调滑块时调用。
 * 必须同时更新模块级 fontSizeNow，否则滚动宽度估算与后续 push 仍用旧字号。
 */
export const setDynamicIslandFontSize = (size: number) => {
  fontSizeNow = size
}

/**
 * set lyric
 * @param lyric lyric str
 * @param translation lyric translation
 */
const handleSetLyric = async (lyric: string, translation = '', romalrc = '') => {
  lrcSetLyric(lyric, translation, romalrc)
  await setDesktopLyric(lyric, translation, romalrc)
}

/**
 * play lyric
 * @param time play time
 */
export const handlePlay = (time: number) => {
  lrcSyncToTime(time, true)
  void playDesktopLyric(time)
}

/**
 * pause lyric
 */
export const pause = () => {
  lrcPause()
  void pauseDesktopLyric()
}

/**
 * stop lyric
 */
export const stop = () => {
  void handleSetLyric('')
}

/**
 * set playback rate
 * @param playbackRate playback rate
 */
export const setPlaybackRate = async (playbackRate: number) => {
  lrcSetPlaybackRate(playbackRate)
  await setDesktopLyricPlaybackRate(playbackRate)
  if (playerState.isPlay) {
    setTimeout(() => {
      void getPosition().then((position) => {
        handlePlay(position * 1000)
      })
    })
  }
}

/**
 * toggle show translation
 * @param isShowTranslation is show translation
 */
export const toggleTranslation = async (isShowTranslation: boolean) => {
  lrcToggleTranslation(isShowTranslation)
  await toggleDesktopLyricTranslation(isShowTranslation)
  if (playerState.isPlay) play()
}

/**
 * toggle show roma lyric
 * @param isShowLyricRoma is show roma lyric
 */
export const toggleRoma = async (isShowLyricRoma: boolean) => {
  lrcToggleRoma(isShowLyricRoma)
  await toggleDesktopLyricRoma(isShowLyricRoma)
  if (playerState.isPlay) play()
}

export const play = () => {
  void getPosition().then((position) => {
    handlePlay(position * 1000)
  })
}

export const setLyric = async () => {
  if (!playerState.musicInfo.id) return
  if (playerState.musicInfo.lrc) {
    let tlrc = ''
    let rlrc = ''
    if (playerState.musicInfo.tlrc) tlrc = playerState.musicInfo.tlrc
    if (playerState.musicInfo.rlrc) rlrc = playerState.musicInfo.rlrc
    await handleSetLyric(playerState.musicInfo.lrc, tlrc, rlrc)
  }

  if (playerState.isPlay) play()
}
