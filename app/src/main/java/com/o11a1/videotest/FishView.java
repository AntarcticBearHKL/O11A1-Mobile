package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.view.Gravity;
import android.widget.FrameLayout;
import android.widget.TextView;

final class FishView extends FrameLayout {
    FishView(Context context) {
        super(context);
        setBackgroundColor(NativeTheme.background(context));
        TextView title = new TextView(context);
        title.setText("养鱼");
        title.setTextColor(NativeTheme.foreground(context));
        title.setTextSize(24);
        title.setTypeface(NativeTheme.titleTypeface());
        title.setPadding(NativeTheme.dp(context, 24),
            statusBar(context) + NativeTheme.dp(context, 18), 0, 0);
        addView(title);

        TextView body = new TextView(context);
        body.setText("🐟\n\n鱼缸还在搭建中\n这里是原生占位页，不再使用网页");
        body.setTextColor(NativeTheme.secondary(context));
        body.setTextSize(14);
        body.setGravity(Gravity.CENTER);
        addView(body, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
    }

    private static int statusBar(Context context) {
        int id = context.getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? context.getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }
}
