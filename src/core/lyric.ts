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
  writeLyricData,
  writeFontSize,
  updatePlaybackState,
  endLyricsActivity,
} from '@/utils/nativeModules/liveActivity'

let dynamicIslandActive = false
let fontSizeNow = 15
let lyricSyncTimer: ReturnType<typeof setInterval> | null = null

// 定时写 AppGroup：Widget 自读数据算换行 + 做动画，不走 Activity.update 推送
const startLyricSyncTimer = () => {
  if (lyricSyncTimer) return
  // 首次立即写入
  writeCurrentData()
  lyricSyncTimer = setInterval(() => {
    if (!dynamicIslandActive) return
    writeCurrentData()
  }, 1000)
}

const writeCurrentData = () => {
  const info = playerState.musicInfo
  void getPosition()
    .then((position) => {
      writeLyricData(
        info.lrc || '',
        info.name || '',
        info.singer || '',
        position,
        info.interval || 0,
        playerState.isPlay
      )
    })
    .catch(() => {})
}

const stopLyricSyncTimer = () => {
  if (lyricSyncTimer) {
    clearInterval(lyricSyncTimer)
    lyricSyncTimer = null
  }
}

export const init = async () => {
  lrcInit()
}

export const startDynamicIslandLyric = async () => {
  const enabled = settingState.setting['player.isDynamicIslandLyric']
  if (!enabled) return
  const info = playerState.musicInfo
  fontSizeNow = settingState.setting['player.dynamicIslandLyricFontSize'] ?? 15
  // 创建 Activity + 写 LRC 到 AppGroup
  await startLyricsActivity(
    info.lrc || '',
    info.name || '',
    info.singer || '',
    fontSizeNow
  )
  dynamicIslandActive = true
  startLyricSyncTimer()
}

export const stopDynamicIslandLyric = async () => {
  dynamicIslandActive = false
  stopLyricSyncTimer()
  await endLyricsActivity()
}

export const setDynamicIslandFontSize = (size: number) => {
  fontSizeNow = size
  writeFontSize(size)
}

const handleSetLyric = async (lyric: string, translation = '', romalrc = '') => {
  lrcSetLyric(lyric, translation, romalrc)
  await setDesktopLyric(lyric, translation, romalrc)
}

export const handlePlay = (time: number) => {
  lrcSyncToTime(time, true)
  void playDesktopLyric(time)
}

export const pause = () => {
  lrcPause()
  void pauseDesktopLyric()
  if (dynamicIslandActive) {
    void getPosition().then((pos) => {
      updatePlaybackState(playerState.musicInfo.name || '', pos, false)
    })
  }
}

export const stop = () => {
  void handleSetLyric('')
}

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

export const toggleTranslation = async (isShowTranslation: boolean) => {
  lrcToggleTranslation(isShowTranslation)
  await toggleDesktopLyricTranslation(isShowTranslation)
  if (playerState.isPlay) play()
}

export const toggleRoma = async (isShowLyricRoma: boolean) => {
  lrcToggleRoma(isShowLyricRoma)
  await toggleDesktopLyricRoma(isShowLyricRoma)
  if (playerState.isPlay) play()
}

export const play = () => {
  void getPosition().then((position) => {
    handlePlay(position * 1000)
  })
  if (dynamicIslandActive) {
    void getPosition().then((pos) => {
      updatePlaybackState(playerState.musicInfo.name || '', pos, true)
    })
  }
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
