package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.view.MotionEvent;
import android.view.View;

final class ProgressWheelView extends View {
    interface OnScrub {
        void onScrub(double ratio, boolean finished);
    }

    private final Paint tick = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint needle = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint label = new Paint(Paint.ANTI_ALIAS_FLAG);
    private double progress = 0;
    private String current = "00:00";
    private String duration = "00:00";
    private OnScrub onScrub;

    ProgressWheelView(Context context) {
        super(context);
        tick.setStrokeCap(Paint.Cap.ROUND);
        needle.setColor(NativeTheme.ACCENT);
        needle.setStrokeWidth(NativeTheme.dp(context, 2));
        needle.setStrokeCap(Paint.Cap.ROUND);
        label.setColor(0xFFB3B3B3);
        label.setTextSize(NativeTheme.dp(context, 9));
        label.setTypeface(NativeTheme.numberTypeface());
        setBackgroundColor(Color.TRANSPARENT);
    }

    void setOnScrub(OnScrub value) {
        onScrub = value;
    }

    void setProgress(long positionMs, long durationMs) {
        progress = durationMs > 0 ? Math.max(0, Math.min(1, positionMs / (double) durationMs)) : 0;
        current = format(positionMs / 1000.0);
        duration = format(durationMs / 1000.0);
        invalidate();
    }

    @Override protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        int width = MeasureSpec.getSize(widthMeasureSpec);
        int height = NativeTheme.dp(getContext(), 48);
        setMeasuredDimension(width, height);
    }

    @Override protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float left = NativeTheme.dp(getContext(), 2);
        float right = getWidth() - NativeTheme.dp(getContext(), 2);
        float usable = Math.max(1, right - left);
        float bottom = NativeTheme.dp(getContext(), 28);
        int count = 48;
        for (int i = 0; i <= count; i++) {
            float ratio = i / (float) count;
            float x = left + usable * ratio;
            boolean major = i % 6 == 0;
            tick.setColor(Color.WHITE | (major ? 0x94000000 : 0x42000000));
            tick.setStrokeWidth(NativeTheme.dp(getContext(), major ? 1.2f : 0.8f));
            float h = NativeTheme.dp(getContext(), major ? 11 : 6);
            canvas.drawLine(x, bottom - h, x, bottom, tick);
        }
        float x = left + usable * (float) progress;
        canvas.drawLine(x, NativeTheme.dp(getContext(), 5), x, bottom + NativeTheme.dp(getContext(), 3), needle);
        float labelY = bottom + NativeTheme.dp(getContext(), 15);
        canvas.drawText(current, left, labelY, label);
        float width = label.measureText(duration);
        canvas.drawText(duration, right - width, labelY, label);
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_MOVE:
                update(event.getX());
                if (onScrub != null) onScrub.onScrub(progress, false);
                return true;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                if (onScrub != null) onScrub.onScrub(progress, true);
                return true;
            default:
                return super.onTouchEvent(event);
        }
    }

    private void update(float x) {
        float left = NativeTheme.dp(getContext(), 2);
        float right = getWidth() - NativeTheme.dp(getContext(), 2);
        progress = Math.max(0, Math.min(1, (x - left) / Math.max(1, right - left)));
        current = format(progress * parseDuration());
        invalidate();
    }

    private int parseDuration() {
        String[] parts = duration.split(":");
        try {
            if (parts.length == 3) {
                return Integer.parseInt(parts[0]) * 3600
                    + Integer.parseInt(parts[1]) * 60 + Integer.parseInt(parts[2]);
            }
            if (parts.length == 2) {
                return Integer.parseInt(parts[0]) * 60 + Integer.parseInt(parts[1]);
            }
        } catch (Throwable ignored) {}
        return 0;
    }

    private static String format(double seconds) {
        if (!Double.isFinite(seconds) || seconds < 0) return "00:00";
        int total = (int) Math.round(seconds);
        int h = total / 3600;
        int m = (total % 3600) / 60;
        int s = total % 60;
        if (h > 0) return String.format(java.util.Locale.CHINA, "%d:%02d:%02d", h, m, s);
        return String.format(java.util.Locale.CHINA, "%02d:%02d", m, s);
    }
}
