import { NativeModules, Platform } from 'react-native'

type LiveActivityModuleType = {
  startLyricsActivity?: (songName: string, artist: string, fontSize: number) => Promise<boolean>
  updateLyric?: (lyric: string, nextLyric: string, isPlaying: boolean, scrollOffset: number) => Promise<void>
  updateFontSize?: (fontSize: number) => Promise<void>
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

export const startLyricsActivity = async (songName: string, artist: string, fontSize: number = 15): Promise<boolean> => {
  if (!hasMethod('startLyricsActivity')) return false
  return LiveActivity!.startLyricsActivity!(songName, artist, fontSize)
}

export const updateLiveActivityLyric = async (lyric: string, nextLyric: string = '', isPlaying: boolean = true, scrollOffset: number = 0) => {
  if (!hasMethod('updateLyric')) return
  return LiveActivity!.updateLyric!(lyric, nextLyric, isPlaying, scrollOffset)
}

export const updateLiveActivityFontSize = async (fontSize: number) => {
  if (!hasMethod('updateFontSize')) return
  return LiveActivity!.updateFontSize!(fontSize)
}

export const endLyricsActivity = async () => {
  if (!hasMethod('endLyricsActivity')) return
  return LiveActivity!.endLyricsActivity!()
}
