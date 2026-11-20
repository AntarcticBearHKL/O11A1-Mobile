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
import { requireNativeViewManager, requireOptionalNativeModule } from 'expo-modules-core';

type Target = 'off' | '60' | '120';
type Enhance = 'off' | 'cas';

type PlayerStats = {
  text?: string;
  renderFps?: number;
  decodeFps?: number;
  decoder?: string;
  hardware?: boolean;
  width?: number;
  height?: number;
  queue?: number;
  error?: string;
};

const PAPER = '#0b0d12';
const PANEL = '#141820';
const PANEL_2 = '#1a202a';
const LINE = '#252c38';
const INK = '#f2f5fa';
const MUTED = '#8d97a8';
const FAINT = '#5d6676';
const BLUE = '#54a7ff';
const CORAL = '#ff7468';

let NativePlayer: React.ComponentType<any> | null = null;
if (Platform.OS === 'ios' && requireOptionalNativeModule('O11A1Video')) {
  try {
    NativePlayer = requireNativeViewManager('O11A1Video');
  } catch {
    NativePlayer = null;
  }
}

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
  const [stats, setStats] = useState<PlayerStats | null>(null);
  const [playerError, setPlayerError] = useState('');

  const start = () => {
    if (running) {
      setRunning(false);
      return;
    }
    if (!NativePlayer) {
      Alert.alert(
        'UI 预览',
        'Expo Go 里只验证布局和交互。VideoToolbox 硬解、Metal blend 插帧和 CAS 需要 iOS 原生构建（CI 的 unsigned 包或本地 dev build）。',
      );
      return;
    }
    setStats(null);
    setPlayerError('');
    setRunning(true);
  };

  const onPlayerStats = (event: { nativeEvent: PlayerStats }) => {
    const next = event.nativeEvent;
    setStats(next);
    setPlayerError(next.error || '');
  };

  const nativeLabel = NativePlayer ? 'NATIVE' : 'UI PREVIEW';

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
          <Text style={styles.platform}>
            {Platform.OS === 'ios' ? 'iOS' : 'Android'} · {nativeLabel}
          </Text>
        </View>

        <View style={styles.notice}>
          <View style={styles.noticeDot} />
          <Text style={styles.noticeText}>
            iOS 原生链路：VideoToolbox 硬解 → Metal blend 插帧 → CAS 锐化。Expo Go 仍只预览 UI。
          </Text>
        </View>

        <View style={styles.preview}>
          <View style={styles.previewTop}>
            <Chip text="BV1NS4t6oEXQ · 1080p30" />
            <Chip text={running ? 'RUNNING' : 'STANDBY'} tone={running ? 'coral' : 'muted'} />
          </View>
          <View style={styles.previewStage}>
            {running && NativePlayer ? (
              <NativePlayer
                style={styles.player}
                interpolation={interpolation !== 'off'}
                targetFps={interpolation === '120' ? 120 : 60}
                enhance={enhance !== 'off'}
                onStats={onPlayerStats}
              />
            ) : (
              <>
                <View style={styles.playButton}>
                  <Text style={styles.playGlyph}>{running ? 'Ⅱ' : '▶'}</Text>
                </View>
                <Text style={styles.previewTitle}>BV1NS4t6oEXQ</Text>
                <Text style={styles.previewHint}>
                  {Platform.OS === 'ios'
                    ? 'VideoToolbox → Metal → blend / CAS'
                    : 'iOS 原生测试视图'}
                </Text>
              </>
            )}
          </View>
          {playerError ? <Text style={styles.playerError}>{playerError}</Text> : null}
          <View style={styles.timeline}>
            <View style={[styles.timelineFill, { width: running ? '42%' : '0%' }]} />
          </View>
        </View>

        <View style={styles.statsRow}>
          <View style={styles.statCell}>
            <Text style={styles.statLabel}>DECODER</Text>
            <Text style={styles.statValue}>{stats?.decoder ?? '—'}</Text>
            <Text style={styles.statHint}>
              {stats ? (stats.hardware ? 'HARDWARE' : 'SOFTWARE') : '等待原生视图'}
            </Text>
          </View>
          <View style={styles.statCell}>
            <Text style={styles.statLabel}>RENDER</Text>
            <Text style={[styles.statValue, { color: running ? BLUE : INK }]}>
              {stats ? `${(stats.renderFps ?? 0).toFixed(1)} fps` : running ? '—' : 'idle'}
            </Text>
            <Text style={styles.statHint}>
              {stats ? `decode ${(stats.decodeFps ?? 0).toFixed(1)} fps` : '目标 120 fps'}
            </Text>
          </View>
          <View style={styles.statCell}>
            <Text style={styles.statLabel}>ENHANCE</Text>
            <Text style={[styles.statValue, { color: enhance === 'off' ? FAINT : BLUE }]}>
              {enhance === 'off' ? 'OFF' : 'CAS'}
            </Text>
            <Text style={styles.statHint}>单 pass 锐化</Text>
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.sectionEyebrow}>PIPELINE</Text>
          <View style={styles.row}>
            <View style={styles.rowCopy}>
              <Text style={styles.rowTitle}>硬件解码</Text>
              <Text style={styles.rowDesc}>VideoToolbox 强制硬件优先，失败才回退软解</Text>
            </View>
            <Switch value disabled thumbColor={BLUE} trackColor={{ true: BLUE + '55', false: LINE }} />
          </View>
          <View style={styles.divider} />
          <View style={styles.block}>
            <View style={styles.rowCopy}>
              <Text style={styles.rowTitle}>插帧</Text>
              <Text style={styles.rowDesc}>blend 过渡 · 60 / 120 目标</Text>
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
              <Text style={styles.rowDesc}>CAS-like 自适应锐化，单 pass</Text>
            </View>
            <Segmented
              value={enhance}
              onChange={setEnhance}
              options={[
                { label: '关', value: 'off' },
                { label: 'CAS', value: 'cas' },
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
              '解码器能力',
              Platform.OS === 'ios'
                ? 'iOS 端通过 VTIsHardwareDecodeSupported 检查 H.264 / HEVC，运行时优先创建强制硬件加速的 VTDecompressionSession。'
                : 'Android 端会列出 MediaCodecList 的 H.264 / HEVC / AV1 / VP9 编码器、HW/SW 标记、支持分辨率和帧率。',
            )
          }
        >
          <Text style={styles.secondaryText}>查看解码器能力</Text>
        </Pressable>

        <Text style={styles.footer}>
          next: Bilibili DASH 播放 · 音频 · Anime4K 真机压测
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
  previewStage: { height: 210, alignItems: 'center', justifyContent: 'center', backgroundColor: '#0e1117' },
  player: { flex: 1, alignSelf: 'stretch' },
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
  playerError: { color: CORAL, fontSize: 10.5, paddingHorizontal: 14, paddingBottom: 8 },
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
