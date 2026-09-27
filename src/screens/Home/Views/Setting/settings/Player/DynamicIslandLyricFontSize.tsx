import { memo } from 'react'
import { View, Text } from 'react-native'
import { useI18n } from '@/lang'
import { useSettingValue } from '@/store/setting/hook'
import { updateSetting } from '@/core/common'
import { createStyle } from '@/utils/tools'
import { updateLiveActivityFontSize } from '@/utils/nativeModules/liveActivity'
import { setDynamicIslandFontSize } from '@/core/lyric'
import Slider from '../../components/Slider'

export default memo(() => {
  const t = useI18n()
  const fontSize: number = useSettingValue('player.dynamicIslandLyricFontSize') ?? 15

  const onChange = (val: number) => {
    const rounded = Math.round(val)
    updateSetting({ 'player.dynamicIslandLyricFontSize': rounded })
    // 同步到歌词模块（滚动宽度估算依赖它）与原生 Live Activity
    setDynamicIslandFontSize(rounded)
    void updateLiveActivityFontSize(rounded)
  }

  return (
    <View style={styles.content}>
      <View style={styles.header}>
        <Text style={styles.label}>{t('setting_play_dynamic_island_lyric_font_size')}</Text>
        <Text style={styles.value}>{fontSize}px</Text>
      </View>
      <Slider
        minimumValue={10}
        maximumValue={22}
        step={1}
        value={fontSize}
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
