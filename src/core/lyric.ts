import {
  syncToTime as lrcSyncToTime,
  setLyric as lrcSetLyric,
  pause as lrcPause,
  setPlaybackRate as lrcSetPlaybackRate,
  toggleTranslation as lrcToggleTranslation,
  toggleRoma as lrcToggleRoma,
  init as lrcInit,
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
  updateLiveActivityFontSize,
  endLyricsActivity,
} from '@/utils/nativeModules/liveActivity'

// 灵动岛 Live Activity 是否已启动
let dynamicIslandActive = false
let fontSizeNow = 15
// 定时同步播放进度到歌词引擎，驱动 addPlayHook 检测换行 → onLyricLinePlay
// → updateLiveActivityLyric 推送新歌词。滚动动画由 Widget 内 TimelineView 自己做。
let lyricSyncTimer: ReturnType<typeof setInterval> | null = null

const startLyricSyncTimer = () => {
  if (lyricSyncTimer) return
  lyricSyncTimer = setInterval(() => {
    if (!dynamicIslandActive) return
    void getPosition()
      .then((position) => {
        lrcSyncToTime(position * 1000, playerState.isPlay)
      })
      .catch(() => {})
  }, 1000)
}

const stopLyricSyncTimer = () => {
  if (lyricSyncTimer) {
    clearInterval(lyricSyncTimer)
    lyricSyncTimer = null
  }
}

/**
 * init lyric
 */
export const init = async () => {
  lrcInit()
}

// 启动灵动岛 Live Activity
export const startDynamicIslandLyric = async () => {
  const enabled = settingState.setting['player.isDynamicIslandLyric']
  if (!enabled) return
  const info = playerState.musicInfo
  fontSizeNow = settingState.setting['player.dynamicIslandLyricFontSize'] ?? 15
  await startLyricsActivity(info.name || '', info.singer || '', fontSizeNow)
  dynamicIslandActive = true
  startLyricSyncTimer()
}

export const stopDynamicIslandLyric = async () => {
  dynamicIslandActive = false
  stopLyricSyncTimer()
  await endLyricsActivity()
}

/**
 * 更新灵动岛歌词字号。设置页调滑块时调用。
 */
export const setDynamicIslandFontSize = (size: number) => {
  fontSizeNow = size
  if (dynamicIslandActive) {
    void updateLiveActivityFontSize(size)
  }
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
