package com.o11a1.videotest;

import android.app.Activity;
import android.app.AlertDialog;
import android.graphics.Color;
import android.graphics.Typeface;
import android.media.MediaMetadataRetriever;
import android.opengl.GLSurfaceView;
import android.os.Bundle;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Switch;
import android.widget.TextView;

import java.util.Locale;

public final class MainActivity extends Activity {
    private static final String ASSET = "test_1080p60.mp4";

    private GLSurfaceView glView;
    private VideoRenderer renderer;
    private TextView stats;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);

        int videoW = 1920;
        int videoH = 1080;
        try (android.content.res.AssetFileDescriptor afd = getAssets().openFd(ASSET)) {
            MediaMetadataRetriever retriever = new MediaMetadataRetriever();
            retriever.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            videoW = parseInt(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH), videoW);
            videoH = parseInt(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT), videoH);
            retriever.release();
        } catch (Throwable ignored) {
            // The decoder will report the real format if metadata is absent.
        }

        FrameLayout root = new FrameLayout(this);

        stats = new TextView(this);
        glView = new GLSurfaceView(this);
        glView.setEGLContextClientVersion(3);
        glView.setPreserveEGLContextOnPause(true);
        renderer = new VideoRenderer(this, ASSET, videoW, videoH,
            text -> runOnUiThread(() -> stats.setText(text)));
        glView.setRenderer(renderer);
        glView.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
        root.addView(glView, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        stats.setTextColor(Color.WHITE);
        stats.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
        stats.setTypeface(Typeface.MONOSPACE);
        stats.setLineSpacing(0f, 1.18f);
        stats.setBackgroundColor(0xAA000000);
        stats.setPadding(dp(14), dp(10), dp(14), dp(10));
        stats.setText("decoder…\n\n" + videoW + " x " + videoH);
        FrameLayout.LayoutParams statsParams = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.TOP | Gravity.START);
        statsParams.setMargins(dp(14), dp(14), dp(14), 0);
        root.addView(stats, statsParams);

        LinearLayout bar = new LinearLayout(this);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setPadding(dp(14), dp(8), dp(14), dp(8));
        bar.setBackgroundColor(0xAA000000);

        Switch interp = new Switch(this);
        interp.setText("插帧 blend");
        interp.setTextColor(Color.WHITE);
        interp.setChecked(true);
        interp.setOnCheckedChangeListener((button, checked) -> renderer.setInterpolation(checked));
        bar.addView(interp, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        Switch cas = new Switch(this);
        cas.setText("CAS 锐化");
        cas.setTextColor(Color.WHITE);
        cas.setChecked(true);
        cas.setOnCheckedChangeListener((button, checked) -> renderer.setEnhance(checked));
        LinearLayout.LayoutParams casParams = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        casParams.leftMargin = dp(18);
        bar.addView(cas, casParams);

        Button probe = new Button(this);
        probe.setText("解码器探测");
        probe.setOnClickListener(view -> showProbe());
        LinearLayout.LayoutParams probeParams = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        probeParams.leftMargin = dp(18);
        bar.addView(probe, probeParams);

        TextView hint = new TextView(this);
        hint.setText("  真机看 HW/SW 和帧率；模拟器不能代表硬解性能");
        hint.setTextColor(0xFFB8C0CC);
        hint.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
        bar.addView(hint);

        FrameLayout.LayoutParams barParams = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM);
        root.addView(bar, barParams);
        setContentView(root);
    }

    private void showProbe() {
        String report;
        try {
            report = CodecProbe.report();
        } catch (Throwable error) {
            report = "probe failed: " + error;
        }
        TextView text = new TextView(this);
        text.setText(report);
        text.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
        text.setTypeface(Typeface.MONOSPACE);
        text.setTextIsSelectable(true);
        text.setPadding(dp(18), dp(12), dp(18), dp(12));
        ScrollView scroll = new ScrollView(this);
        scroll.addView(text);
        new AlertDialog.Builder(this)
            .setTitle("MediaCodec 探测")
            .setView(scroll)
            .setPositiveButton("关闭", null)
            .show();
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private static int parseInt(String value, int fallback) {
        try {
            return value == null ? fallback : Integer.parseInt(value);
        } catch (NumberFormatException ignored) {
            return fallback;
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        glView.onResume();
    }

    @Override
    protected void onPause() {
        glView.onPause();
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        if (renderer != null) renderer.release();
        super.onDestroy();
    }
}
