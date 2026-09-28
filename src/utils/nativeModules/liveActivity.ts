import { NativeModules, Platform } from 'react-native'

type LiveActivityModuleType = {
  startLyricsActivity?: (lrc: string, songName: string, artist: string, fontSize: number) => Promise<boolean>
  writeLyricData?: (lrc: string, songName: string, artist: string, currentTime: number, duration: number, isPlaying: boolean) => void
  writeFontSize?: (fontSize: number) => void
  updatePlaybackState?: (songName: string, currentTime: number, isPlaying: boolean) => void
  endLyricsActivity?: () => Promise<void>
  isAvailable?: () => Promise<boolean>
}

const LiveActivity = NativeModules.LiveActivityModule as LiveActivityModuleType | undefined

const hasMethod = <K extends keyof LiveActivityModuleType>(method: K) => {
  return Platform.OS === 'ios' && typeof LiveActivity?.[method] === 'function'
}

export const isLiveActivityAvailable = async (): Promise<boolean> => {
  if (!hasMethod('isAvailable')) return false
  return LiveActivity!.isAvailable!()
}

// 创建 Live Activity，同时把 LRC 写入 AppGroup
export const startLyricsActivity = async (
  lrc: string, songName: string, artist: string, fontSize: number = 15
): Promise<boolean> => {
  if (!hasMethod('startLyricsActivity')) return false
  return LiveActivity!.startLyricsActivity!(lrc, songName, artist, fontSize)
}

// 写歌词数据到 AppGroup（Widget 自读，不走 Activity.update 推送）
export const writeLyricData = (
  lrc: string, songName: string, artist: string,
  currentTime: number, duration: number, isPlaying: boolean
) => {
  if (!hasMethod('writeLyricData')) return
  LiveActivity!.writeLyricData!(lrc, songName, artist, currentTime, duration, isPlaying)
}

export const writeFontSize = (fontSize: number) => {
  if (!hasMethod('writeFontSize')) return
  LiveActivity!.writeFontSize!(fontSize)
}

// 暂停/恢复/切歌时更新状态
export const updatePlaybackState = (songName: string, currentTime: number, isPlaying: boolean) => {
  if (!hasMethod('updatePlaybackState')) return
  LiveActivity!.updatePlaybackState!(songName, currentTime, isPlaying)
}

export const endLyricsActivity = async () => {
  if (!hasMethod('endLyricsActivity')) return
  return LiveActivity!.endLyricsActivity!()
}
