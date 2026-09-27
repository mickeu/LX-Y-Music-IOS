import { memo } from 'react'
import { View, Text } from 'react-native'
import { useI18n } from '@/lang'
import { useSettingValue } from '@/store/setting/hook'
import { updateSetting } from '@/core/common'
import { createStyle } from '@/utils/tools'
import { updateLiveActivityFontSize } from '@/utils/nativeModules/liveActivity'
import Slider, { type SliderProps } from '../../components/Slider'

export default memo(() => {
  const t = useI18n()
  const fontSize: number = useSettingValue('player.dynamicIslandLyricFontSize') ?? 15

  const onSlidingComplete = async (val: number) => {
    const rounded = Math.round(val)
    updateSetting({ 'player.dynamicIslandLyricFontSize': rounded })
    await updateLiveActivityFontSize(rounded)
  }

  return (
    <View style={styles.content}>
      <Text style={styles.label}>{t('setting_play_dynamic_island_lyric_font_size')}</Text>
      <View style={styles.row}>
        <Text style={styles.value}>{fontSize}px</Text>
        <Slider
          minimumValue={10}
          maximumValue={22}
          step={1}
          value={fontSize}
          onSlidingComplete={onSlidingComplete}
        />
      </View>
    </View>
  )
})

const styles = createStyle({
  content: { marginTop: 8, paddingHorizontal: 16, paddingBottom: 12 },
  label: { color: '#333', fontSize: 15, marginBottom: 6 },
  row: { flexDirection: 'row', alignItems: 'center' },
  value: { width: 50, fontSize: 13, color: '#07c556' },
  slider: { flex: 1, marginLeft: 8, maxWidth: 300 },
})
