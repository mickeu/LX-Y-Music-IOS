import { getPosition } from '@/plugins/player'
import playerState from '@/store/player/state'
import { startSpotifyProxy, updateSpotifyProxyInfo } from '@/utils/nativeModules/spotifyProxy'

let proxyTimer: ReturnType<typeof setInterval> | null = null

const updateProxy = () => {
  void getPosition()
    .then((position) => {
      const info = playerState.musicInfo
      updateSpotifyProxyInfo(
        info.id || '',
        info.name || '',
        info.singer || '',
        Math.round(position * 1000),
        Math.round((info.interval || 0) * 1000),
        playerState.isPlay
      )
    })
    .catch(() => {})
}

export default async () => {
  startSpotifyProxy()
  // 立即更新一次
  updateProxy()
  // 每秒更新播放进度（Spotify API 轮询频率约 1-3s）
  proxyTimer = setInterval(updateProxy, 1000)
}
