package com.o11a1.videotest;

import android.media.MediaCodecInfo;
import android.media.MediaCodecList;
import android.os.Build;

import java.util.Locale;

/// Small, dependency-free codec probe. The test UI can dump this to a dialog
/// and the decoder uses `bestDecoder` to prefer a vendor hardware codec.
public final class CodecProbe {
    private static final String[] CODECS = {
        "video/avc", "video/hevc", "video/av01", "video/x-vnd.on2.vp9"
    };

    private CodecProbe() {}

    public static String report() {
        StringBuilder out = new StringBuilder();
        out.append("Build: ").append(Build.MANUFACTURER).append(' ')
            .append(Build.MODEL).append(" · Android ").append(Build.VERSION.RELEASE)
            .append(" (API ").append(Build.VERSION.SDK_INT).append(")\n\n");

        MediaCodecList list = new MediaCodecList(MediaCodecList.ALL_CODECS);
        for (MediaCodecInfo info : list.getCodecInfos()) {
            if (info.isEncoder()) continue;
            boolean printed = false;
            for (String type : info.getSupportedTypes()) {
                if (!interesting(type)) continue;
                if (!printed) {
                    out.append(info.getName())
                        .append(hardware(info) ? "  [HARDWARE]" : "  [SOFTWARE]")
                        .append('\n');
                    printed = true;
                }
                out.append("  ").append(type);
                try {
                    MediaCodecInfo.CodecCapabilities caps = info.getCapabilitiesForType(type);
                    MediaCodecInfo.VideoCapabilities video = caps.getVideoCapabilities();
                    if (video != null) {
                        out.append("  ")
                            .append(video.getSupportedWidths().getLower()).append('-')
                            .append(video.getSupportedWidths().getUpper()).append(" x ")
                            .append(video.getSupportedHeights().getLower()).append('-')
                            .append(video.getSupportedHeights().getUpper())
                            .append("  fps ")
                            .append(Math.round(video.getSupportedFrameRates().getLower())).append('-')
                            .append(Math.round(video.getSupportedFrameRates().getUpper()));
                    }
                    if (caps.isFormatSupported(android.media.MediaFormat.createVideoFormat(type, 1920, 1080))) {
                        out.append("  [1080p]");
                    }
                } catch (RuntimeException error) {
                    out.append("  (caps unavailable: ").append(error.getMessage()).append(')');
                }
                out.append('\n');
            }
        }
        return out.toString();
    }

    /// Prefer a vendor hardware decoder on real devices. On the emulator the
    /// goldfish "hardware" decoder rejects many High-profile H.264 streams, so
    /// prefer the platform software decoder there.
    public static String bestDecoder(String mime) {
        MediaCodecList list = new MediaCodecList(MediaCodecList.ALL_CODECS);
        String hardwareName = null;
        String softwareName = null;
        boolean emulator = isEmulator();
        for (MediaCodecInfo info : list.getCodecInfos()) {
            if (info.isEncoder()) continue;
            boolean supports = false;
            for (String type : info.getSupportedTypes()) {
                if (mime.equalsIgnoreCase(type)) {
                    supports = true;
                    break;
                }
            }
            if (!supports) continue;
            if (hardware(info)) {
                if (hardwareName == null) hardwareName = info.getName();
            } else if (softwareName == null) {
                softwareName = info.getName();
            }
        }
        if (emulator && softwareName != null) return softwareName;
        if (hardwareName != null) return hardwareName;
        return softwareName;
    }

    public static boolean isEmulator() {
        return Build.FINGERPRINT.contains("generic")
            || Build.FINGERPRINT.contains("emulator")
            || Build.HARDWARE.contains("ranchu")
            || Build.HARDWARE.contains("goldfish")
            || Build.PRODUCT.contains("sdk")
            || Build.MODEL.contains("sdk_gphone");
    }

    public static boolean hardware(MediaCodecInfo info) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return info.isHardwareAccelerated();
        }
        String name = info.getName().toLowerCase(Locale.ROOT);
        return !(name.startsWith("omx.google.")
            || name.startsWith("c2.android.")
            || name.contains("software")
            || name.contains("sw."));
    }

    public static boolean hardware(String codecName) {
        MediaCodecList list = new MediaCodecList(MediaCodecList.ALL_CODECS);
        for (MediaCodecInfo info : list.getCodecInfos()) {
            if (info.getName().equals(codecName)) return hardware(info);
        }
        return false;
    }

    private static boolean interesting(String type) {
        for (String codec : CODECS) {
            if (codec.equalsIgnoreCase(type)) return true;
        }
        return false;
    }
}
