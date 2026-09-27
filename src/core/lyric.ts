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
const dynamicIslandLyricHook = (line: number, text: string) => {
  if (!settingState.setting['player.isDynamicIslandLyric']) return
  if (!dynamicIslandLyricHookActive) return
  const lyricText = cleanLyricText(text) || playerState.musicInfo.name || ''
  updateLiveActivityLyric(lyricText, '', playerState.isPlay).catch(() => {})
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
}

export const stopDynamicIslandLyric = async () => {
  dynamicIslandLyricHookActive = false
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
