import { NativeModules, Platform } from 'react-native'

type SpotifyProxyType = {
  start?: () => void
  stop?: () => void
  updateInfo?: (trackId: string, songName: string, artist: string, progressMs: number, durationMs: number, isPlaying: boolean) => void
}

const Proxy = NativeModules.SpotifyProxyModule as SpotifyProxyType | undefined

const hasMethod = <K extends keyof SpotifyProxyType>(method: K) => {
  return Platform.OS === 'ios' && typeof Proxy?.[method] === 'function'
}

export const startSpotifyProxy = () => {
  if (!hasMethod('start')) return
  Proxy!.start!()
}

export const stopSpotifyProxy = () => {
  if (!hasMethod('stop')) return
  Proxy!.stop!()
}

export const updateSpotifyProxyInfo = (
  trackId: string, songName: string, artist: string,
  progressMs: number, durationMs: number, isPlaying: boolean
) => {
  if (!hasMethod('updateInfo')) return
  Proxy!.updateInfo!(trackId, songName, artist, progressMs, durationMs, isPlaying)
}
