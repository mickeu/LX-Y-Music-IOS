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

// 灵动岛歌词 hook 函数
let dynamicIslandLyricHookActive = false
let lyricSyncTimer: ReturnType<typeof setInterval> | null = null
// 滚动状态
let scrollOffset = 0
let currentLyricText = ''
const SCROLL_SPEED = 15  // 每秒移动像素
const INITIAL_OFFSET = 36 // 初始偏移量（从右边开始）

const dynamicIslandLyricHook = (line: number, text: string) => {
  if (!settingState.setting['player.isDynamicIslandLyric']) return
  if (!dynamicIslandLyricHookActive) return
  currentLyricText = cleanLyricText(text) || playerState.musicInfo.name || ''
  // 歌词行变化时重置滚动偏移量（从右边开始）
  scrollOffset = INITIAL_OFFSET
  updateLiveActivityLyric(currentLyricText, '', playerState.isPlay, scrollOffset).catch(() => {})
}

// 定时同步歌词位置 + 滚动更新
const startLyricSyncTimer = () => {
  if (lyricSyncTimer) return
  lyricSyncTimer = setInterval(() => {
    if (!playerState.isPlay) return
    if (!dynamicIslandLyricHookActive) return
    // 同步歌词位置（触发 addPlayHook）
    void getPosition().then((position) => {
      lrcSyncToTime(position * 1000, true)
    })
    // 更新滚动偏移量（从右往左滚动）
    if (currentLyricText) {
      const textWidth = currentLyricText.length * 6 // 估算文字宽度
      if (textWidth > INITIAL_OFFSET) {
        scrollOffset -= SCROLL_SPEED
        if (scrollOffset < -(textWidth + INITIAL_OFFSET)) {
          scrollOffset = INITIAL_OFFSET // 循环
        }
      } else {
        scrollOffset = 0 // 短文本不需要滚动
      }
      updateLiveActivityLyric(currentLyricText, '', playerState.isPlay, scrollOffset).catch(() => {})
    }
  }, 1000)
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
  const fontSize = settingState.setting['player.dynamicIslandLyricFontSize'] ?? 15
  // 等待 Activity 创建完成再激活 hook（避免 currentActivity 为 nil 时更新丢失）
  await startLyricsActivity(info.name || '', info.singer || '', fontSize)
  dynamicIslandLyricHookActive = true
  // 启动定时同步：每秒获取播放位置，同步歌词，触发 hook 更新灵动岛
  startLyricSyncTimer()
}

export const stopDynamicIslandLyric = async () => {
  dynamicIslandLyricHookActive = false
  stopLyricSyncTimer()
  await endLyricsActivity()
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
