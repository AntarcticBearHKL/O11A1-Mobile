package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.view.View;

/** The original player's 36-block grid progress, blue for played blocks. */
final class GridProgressView extends View {
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private double progress = 0;
    private final int blocks = 36;

    GridProgressView(Context context) {
        super(context);
    }

    void setProgress(long positionMs, long durationMs) {
        progress = durationMs > 0
            ? Math.max(0, Math.min(1, positionMs / (double) durationMs))
            : 0;
        invalidate();
    }

    @Override protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        setMeasuredDimension(MeasureSpec.getSize(widthMeasureSpec),
            NativeTheme.dp(getContext(), 6));
    }

    @Override protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float gap = NativeTheme.dp(getContext(), 2);
        float width = (getWidth() - gap * (blocks - 1)) / blocks;
        float radius = NativeTheme.dp(getContext(), 1.5f);
        int played = (int) Math.round(progress * blocks);
        RectF rect = new RectF();
        for (int i = 0; i < blocks; i++) {
            float left = i * (width + gap);
            rect.set(left, 0, left + width, getHeight());
            paint.setColor(i < played
                ? NativeTheme.navBlue(getContext())
                : Color.WHITE);
            paint.setAlpha(i < played ? 255 : 58);
            canvas.drawRoundRect(rect, radius, radius, paint);
        }
    }
}
