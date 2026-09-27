import { memo } from 'react'
import { View } from 'react-native'
import { useI18n } from '@/lang'
import { useSettingValue } from '@/store/setting/hook'
import { updateSetting } from '@/core/common'
import { createStyle } from '@/utils/tools'
import CheckBoxItem from '../../components/CheckBoxItem'
import { isLiveActivityAvailable } from '@/utils/nativeModules/liveActivity'

export default memo(() => {
  const t = useI18n()
  const enabled = useSettingValue('player.isLiveActivityEnabled')

  const onToggle = async (val: boolean) => {
    if (val) {
      const ok = await isLiveActivityAvailable()
      if (!ok) return
    }
    updateSetting({ 'player.isLiveActivityEnabled': val })
  }

  return (
    <View style={styles.content}>
      <CheckBoxItem
        check={!!enabled}
        onChange={onToggle}
        label={t('setting_play_live_activity')}
      />
    </View>
  )
})

const styles = createStyle({
  content: { marginTop: 5 },
})
