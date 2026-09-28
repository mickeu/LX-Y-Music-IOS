import { memo } from 'react'
import { View } from 'react-native'
import { useI18n } from '@/lang'
import { useSettingValue } from '@/store/setting/hook'
import { updateSetting } from '@/core/common'
import { createStyle } from '@/utils/tools'
import CheckBoxItem from '../../components/CheckBoxItem'
import { startDynamicIslandLyric, stopDynamicIslandLyric } from '@/core/lyric'

export default memo(() => {
  const t = useI18n()
  const enabled = useSettingValue('player.isDynamicIslandLyric')

  const onToggle = async (val: boolean) => {
    updateSetting({ 'player.isDynamicIslandLyric': val })
    if (val) {
      await startDynamicIslandLyric()
    } else {
      await stopDynamicIslandLyric()
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
