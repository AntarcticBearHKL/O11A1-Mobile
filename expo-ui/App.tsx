import React, { useState } from 'react';
import {
  Alert,
  Platform,
  Pressable,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Switch,
  Text,
  View,
} from 'react-native';

type Target = 'off' | '60' | '120';
type Enhance = 'off' | 'cas' | 'anime';

const PAPER = '#0b0d12';
const PANEL = '#141820';
const PANEL_2 = '#1a202a';
const LINE = '#252c38';
const INK = '#f2f5fa';
const MUTED = '#8d97a8';
const FAINT = '#5d6676';
const BLUE = '#54a7ff';
const CORAL = '#ff7468';

function Chip({ text, tone = 'muted' }: { text: string; tone?: 'muted' | 'blue' | 'coral' }) {
  const color = tone === 'blue' ? BLUE : tone === 'coral' ? CORAL : MUTED;
  return (
    <View style={[styles.chip, { borderColor: color + '55', backgroundColor: color + '12' }]}>
      <Text style={[styles.chipText, { color }]}>{text}</Text>
    </View>
  );
}

function Segmented<T extends string>({
  value,
  options,
  onChange,
}: {
  value: T;
  options: { label: string; value: T }[];
  onChange: (value: T) => void;
}) {
  return (
    <View style={styles.segmented}>
      {options.map((option) => {
        const active = option.value === value;
        return (
          <Pressable
            key={option.value}
            onPress={() => onChange(option.value)}
            style={[styles.segment, active && styles.segmentActive]}
          >
            <Text style={[styles.segmentText, active && styles.segmentTextActive]}>{option.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export default function App() {
  const [interpolation, setInterpolation] = useState<Target>('120');
  const [enhance, setEnhance] = useState<Enhance>('cas');
  const [running, setRunning] = useState(false);

  const start = () => {
    setRunning((value) => !value);
    if (!running) {
      Alert.alert(
        'UI 预览',
        'Expo Go 里只验证布局和交互。MediaCodec、SurfaceTexture、GLES 插帧与 CAS 需要 Development Build 或 Android Studio 原生测试包。',
      );
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <StatusBar barStyle="light-content" />
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.page}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.headerRow}>
          <View style={styles.headerCopy}>
            <View style={styles.brandRow}>
              <View style={styles.brandDot} />
              <Text style={styles.brand}>O11A1</Text>
              <Chip text="VIDEO LAB" tone="blue" />
            </View>
            <Text style={styles.title}>移动端解码实验室</Text>
          </View>
          <Text style={styles.platform}>{Platform.OS === 'ios' ? 'iOS' : 'Android'} · UI PREVIEW</Text>
        </View>

        <View style={styles.notice}>
          <View style={styles.noticeDot} />
          <Text style={styles.noticeText}>
            Expo Go 只预览 UI。硬解 / 插帧 / 增强请用 dev build 或 Android Studio 测试包。
          </Text>
        </View>

        <View style={styles.preview}>
          <View style={styles.previewTop}>
            <Chip text="H.264 · 1080p60" />
            <Chip text={running ? 'RUNNING' : 'STANDBY'} tone={running ? 'coral' : 'muted'} />
          </View>
          <View style={styles.previewStage}>
            <View style={styles.playButton}>
              <Text style={styles.playGlyph}>{running ? 'Ⅱ' : '▶'}</Text>
            </View>
            <Text style={styles.previewTitle}>test_1080p60.mp4</Text>
            <Text style={styles.previewHint}>原生画面在这里替换为 SurfaceView / GLES</Text>
          </View>
          <View style={styles.timeline}>
            <View style={[styles.timelineFill, { width: running ? '42%' : '0%' }]} />
          </View>
        </View>

        <View style={styles.statsRow}>
          <View style={styles.statCell}>
            <Text style={styles.statLabel}>DECODER</Text>
            <Text style={styles.statValue}>—</Text>
            <Text style={styles.statHint}>dev build 读取</Text>
          </View>
          <View style={styles.statCell}>
            <Text style={styles.statLabel}>RENDER</Text>
            <Text style={[styles.statValue, { color: running ? BLUE : INK }]}>{running ? '—' : 'idle'}</Text>
            <Text style={styles.statHint}>目标 120 fps</Text>
          </View>
          <View style={styles.statCell}>
            <Text style={styles.statLabel}>ENHANCE</Text>
            <Text style={[styles.statValue, { color: enhance === 'off' ? FAINT : BLUE }]}>
              {enhance === 'off' ? 'OFF' : enhance.toUpperCase()}
            </Text>
            <Text style={styles.statHint}>单 pass 起步</Text>
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.sectionEyebrow}>PIPELINE</Text>
          <View style={styles.row}>
            <View style={styles.rowCopy}>
              <Text style={styles.rowTitle}>硬件解码</Text>
              <Text style={styles.rowDesc}>MediaCodec · 不回落软解</Text>
            </View>
            <Switch value disabled thumbColor={BLUE} trackColor={{ true: BLUE + '55', false: LINE }} />
          </View>
          <View style={styles.divider} />
          <View style={styles.block}>
            <View style={styles.rowCopy}>
              <Text style={styles.rowTitle}>插帧</Text>
              <Text style={styles.rowDesc}>blend 过渡，参考桌面 blend_main</Text>
            </View>
            <Segmented
              value={interpolation}
              onChange={setInterpolation}
              options={[
                { label: '关', value: 'off' },
                { label: '60', value: '60' },
                { label: '120', value: '120' },
              ]}
            />
          </View>
          <View style={styles.divider} />
          <View style={styles.block}>
            <View style={styles.rowCopy}>
              <Text style={styles.rowTitle}>画质增强</Text>
              <Text style={styles.rowDesc}>CAS 先跑通；Anime4K 真机再压测</Text>
            </View>
            <Segmented
              value={enhance}
              onChange={setEnhance}
              options={[
                { label: '关', value: 'off' },
                { label: 'CAS', value: 'cas' },
                { label: 'Anime4K', value: 'anime' },
              ]}
            />
          </View>
        </View>

        <Pressable style={[styles.primary, running && styles.primaryStop]} onPress={start}>
          <Text style={styles.primaryText}>{running ? '停止测试' : '开始测试'}</Text>
        </Pressable>

        <Pressable
          style={styles.secondary}
          onPress={() =>
            Alert.alert(
              '解码器探测',
              '在 Android 原生测试包中会列出 MediaCodecList 的 H.264 / HEVC / AV1 / VP9 编码器、HW/SW 标记、支持分辨率和帧率。',
            )
          }
        >
          <Text style={styles.secondaryText}>查看解码器能力</Text>
        </Pressable>

        <Text style={styles.footer}>
          next: MediaCodec → SurfaceTexture → GLES → blend / CAS → RN Fabric View
        </Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, width: '100%', backgroundColor: PAPER },
  scroll: { flex: 1, width: '100%' },
  page: { alignSelf: 'stretch', paddingHorizontal: 18, paddingTop: 16, paddingBottom: 36 },
  headerRow: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'flex-start', gap: 10 },
  headerCopy: { flex: 1, minWidth: 0 },
  brandRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 10 },
  brandDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: BLUE },
  brand: { color: INK, fontSize: 13, fontWeight: '700', letterSpacing: 1.4 },
  title: { color: INK, fontSize: 27, fontWeight: '700', letterSpacing: -0.5 },
  platform: { color: FAINT, fontSize: 10, fontWeight: '600', letterSpacing: 1, marginTop: 4 },
  notice: {
    marginTop: 18,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    borderWidth: 1,
    borderColor: BLUE + '33',
    backgroundColor: BLUE + '0C',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  noticeDot: { width: 5, height: 5, borderRadius: 3, backgroundColor: BLUE },
  noticeText: { color: MUTED, fontSize: 11.5, lineHeight: 17, flex: 1, minWidth: 0 },
  preview: {
    marginTop: 16,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: LINE,
    backgroundColor: PANEL,
    overflow: 'hidden',
  },
  previewTop: { flexDirection: 'row', justifyContent: 'space-between', padding: 12 },
  previewStage: { height: 188, alignItems: 'center', justifyContent: 'center', backgroundColor: '#0e1117' },
  playButton: {
    width: 52,
    height: 52,
    borderRadius: 26,
    borderWidth: 1,
    borderColor: BLUE + '66',
    backgroundColor: BLUE + '18',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 14,
  },
  playGlyph: { color: BLUE, fontSize: 19, marginLeft: 2 },
  previewTitle: { color: INK, fontSize: 13, fontWeight: '600' },
  previewHint: { color: FAINT, fontSize: 10.5, marginTop: 5 },
  timeline: { height: 3, backgroundColor: LINE, marginHorizontal: 14, marginBottom: 14, borderRadius: 2 },
  timelineFill: { height: 3, borderRadius: 2, backgroundColor: BLUE },
  statsRow: { flexDirection: 'row', gap: 8, marginTop: 10 },
  statCell: {
    flex: 1,
    minWidth: 0,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: LINE,
    backgroundColor: PANEL,
    padding: 12,
  },
  statLabel: { color: FAINT, fontSize: 9, fontWeight: '700', letterSpacing: 1.1 },
  statValue: { color: INK, fontSize: 16, fontWeight: '700', marginTop: 7 },
  statHint: { color: FAINT, fontSize: 9, marginTop: 3 },
  card: {
    marginTop: 14,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: LINE,
    backgroundColor: PANEL,
    paddingHorizontal: 15,
    paddingVertical: 14,
  },
  sectionEyebrow: { color: FAINT, fontSize: 9, fontWeight: '700', letterSpacing: 1.4, marginBottom: 10 },
  row: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', minHeight: 44, gap: 12 },
  rowCopy: { flex: 1, minWidth: 0 },
  rowTitle: { color: INK, fontSize: 14, fontWeight: '600' },
  rowDesc: { color: MUTED, fontSize: 10.5, marginTop: 3, lineHeight: 15 },
  divider: { height: 1, backgroundColor: LINE, marginVertical: 9 },
  block: { gap: 10, paddingVertical: 2 },
  segmented: {
    flexDirection: 'row',
    backgroundColor: '#0e1117',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: LINE,
    padding: 3,
    alignSelf: 'flex-start',
  },
  segment: { paddingHorizontal: 11, paddingVertical: 6, borderRadius: 7 },
  segmentActive: { backgroundColor: BLUE + '20' },
  segmentText: { color: MUTED, fontSize: 11, fontWeight: '600' },
  segmentTextActive: { color: BLUE },
  chip: { borderWidth: 1, borderRadius: 6, paddingHorizontal: 6, paddingVertical: 3 },
  chipText: { fontSize: 8.5, fontWeight: '700', letterSpacing: 0.8 },
  primary: {
    marginTop: 14,
    height: 52,
    borderRadius: 14,
    backgroundColor: BLUE,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primaryStop: { backgroundColor: CORAL },
  primaryText: { color: '#07101c', fontSize: 15, fontWeight: '800', letterSpacing: 0.2 },
  secondary: {
    marginTop: 9,
    height: 46,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: LINE,
    backgroundColor: PANEL,
    alignItems: 'center',
    justifyContent: 'center',
  },
  secondaryText: { color: INK, fontSize: 12.5, fontWeight: '600' },
  footer: { color: FAINT, fontSize: 9.5, textAlign: 'center', marginTop: 18, letterSpacing: 0.2 },
});
