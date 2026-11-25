package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

final class GlassTabBarView extends LinearLayout {
    interface OnSelect {
        void select(int index);
    }

    private final String[] titles = {"推荐", "关注", "动态", "养鱼"};
    private final int[] icons = {
        android.R.drawable.ic_media_play,
        android.R.drawable.ic_menu_myplaces,
        android.R.drawable.ic_menu_sort_by_size,
        android.R.drawable.ic_menu_compass
    };
    private final LinearLayout[] items = new LinearLayout[titles.length];
    private final ImageView[] images = new ImageView[titles.length];
    private final TextView[] labels = new TextView[titles.length];
    private OnSelect onSelect;
    private int selected = 0;
    private boolean hidden = false;

    GlassTabBarView(Context context) {
        super(context);
        setOrientation(HORIZONTAL);
        setGravity(Gravity.CENTER);
        setBackground(NativeTheme.glassPanel(context, NativeTheme.dp(context, 26)));
        setElevation(NativeTheme.dp(context, 12));
        setPadding(NativeTheme.dp(context, 6), 0, NativeTheme.dp(context, 6), 0);
        for (int i = 0; i < titles.length; i++) {
            LinearLayout item = new LinearLayout(context);
            item.setOrientation(VERTICAL);
            item.setGravity(Gravity.CENTER);
            item.setClickable(true);
            final int index = i;
            item.setOnClickListener(v -> {
                if (onSelect != null) onSelect.select(index);
            });
            ImageView icon = new ImageView(context);
            icon.setImageResource(icons[i]);
            icon.setColorFilter(NativeTheme.secondary(context));
            item.addView(icon, new LinearLayout.LayoutParams(
                NativeTheme.dp(context, 21), NativeTheme.dp(context, 21)));
            TextView label = new TextView(context);
            label.setText(titles[i]);
            label.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
            label.setTypeface(Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL));
            label.setTextColor(NativeTheme.secondary(context));
            LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            labelParams.topMargin = NativeTheme.dp(context, 3);
            item.addView(label, labelParams);
            addView(item, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f));
            items[i] = item;
            images[i] = icon;
            labels[i] = label;
        }
        select(0, false);
    }

    void setOnSelect(OnSelect value) {
        onSelect = value;
    }

    void select(int index, boolean notify) {
        if (index < 0 || index >= items.length) return;
        selected = index;
        for (int i = 0; i < items.length; i++) {
            boolean active = i == index;
            int color = active ? NativeTheme.ACCENT : NativeTheme.secondary(getContext());
            images[i].setColorFilter(color);
            labels[i].setTextColor(color);
        }
        if (notify && onSelect != null) onSelect.select(index);
    }

    int selected() {
        return selected;
    }

    void setHidden(boolean shouldHide, boolean animate) {
        if (shouldHide == hidden) return;
        hidden = shouldHide;
        float distance = getHeight() + NativeTheme.dp(getContext(), 28);
        if (animate) {
            animate()
                .translationY(shouldHide ? distance : 0)
                .alpha(shouldHide ? 0 : 1)
                .setDuration(750)
                .start();
        } else {
            setTranslationY(shouldHide ? distance : 0);
            setAlpha(shouldHide ? 0 : 1);
        }
    }
}
