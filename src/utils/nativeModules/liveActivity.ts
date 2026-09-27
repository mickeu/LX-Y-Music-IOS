import { NativeModules, Platform } from 'react-native'

type LiveActivityModuleType = {
  startLyricsActivity?: (songName: string, artist: string, fontSize: number) => Promise<void>
  updateLyric?: (lyric: string, nextLyric: string, isPlaying: boolean) => Promise<void>
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

export const startLyricsActivity = async (songName: string, artist: string, fontSize: number = 15) => {
  if (!hasMethod('startLyricsActivity')) return
  return LiveActivity!.startLyricsActivity!(songName, artist, fontSize)
}

export const updateLiveActivityLyric = async (lyric: string, nextLyric: string = '', isPlaying: boolean = true) => {
  if (!hasMethod('updateLyric')) return
  return LiveActivity!.updateLyric!(lyric, nextLyric, isPlaying)
}

export const updateLiveActivityFontSize = async (fontSize: number) => {
  if (!hasMethod('updateFontSize')) return
  return LiveActivity!.updateFontSize!(fontSize)
}

export const endLyricsActivity = async () => {
  if (!hasMethod('endLyricsActivity')) return
  return LiveActivity!.endLyricsActivity!()
}
