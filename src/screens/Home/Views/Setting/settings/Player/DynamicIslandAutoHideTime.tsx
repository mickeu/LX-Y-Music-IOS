import { memo } from 'react'
import { View, Text } from 'react-native'
import { useI18n } from '@/lang'
import { useSettingValue } from '@/store/setting/hook'
import { updateSetting } from '@/core/common'
import { createStyle } from '@/utils/tools'
import Slider from '../../components/Slider'

export default memo(() => {
  const t = useI18n()
  const autoHideTime: number = useSettingValue('player.dynamicIslandAutoHideTime') ?? 30

  const onChange = (val: number) => {
    const rounded = Math.round(val)
    updateSetting({ 'player.dynamicIslandAutoHideTime': rounded })
  }

  const displayValue = autoHideTime === 0 ? '不隐藏' : `${autoHideTime}s`

  return (
    <View style={styles.content}>
      <View style={styles.header}>
        <Text style={styles.label}>{t('setting_play_dynamic_island_auto_hide')}</Text>
        <Text style={styles.value}>{displayValue}</Text>
      </View>
      <Slider
        minimumValue={0}
        maximumValue={120}
        step={5}
        value={autoHideTime}
        onValueChange={onChange}
        onSlidingComplete={onChange}
      />
    </View>
  )
})

const styles = createStyle({
  content: { marginTop: 8, paddingHorizontal: 16, paddingBottom: 12 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 },
  label: { color: '#333', fontSize: 15 },
  value: { fontSize: 13, color: '#07c556' },
})
