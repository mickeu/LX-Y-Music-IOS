import { memo } from 'react'
import { View } from 'react-native'
import { useI18n } from '@/lang'
import { useSettingValue } from '@/store/setting/hook'
import { updateSetting } from '@/core/common'
import { createStyle } from '@/utils/tools'
import CheckBoxItem from '../../components/CheckBoxItem'
import {
  startLyricsActivity,
  endLyricsActivity,
  updateLiveActivityFontSize,
  isLiveActivityAvailable,
} from '@/utils/nativeModules/liveActivity'
import playerState from '@/store/player/state'

export default memo(() => {
  const t = useI18n()
  const enabled = useSettingValue('player.isDynamicIslandLyric')

  const onToggle = async (val: boolean) => {
    updateSetting({ 'player.isDynamicIslandLyric': val })
    if (val) {
      const ok = await isLiveActivityAvailable()
      if (!ok) return
      const info = playerState.musicInfo
      const fontSize = playerState.setting?.['player.dynamicIslandLyricFontSize'] ?? 15
      await startLyricsActivity(info.name || '', info.singer || '', fontSize)
    } else {
      await endLyricsActivity()
    }
  }

  return (
    <View style={styles.content}>
      <CheckBoxItem
        check={!!enabled}
        onChange={onToggle}
        label={t('setting_play_dynamic_island_lyric')}
      />
    </View>
  )
})

const styles = createStyle({
  content: { marginTop: 5 },
})
