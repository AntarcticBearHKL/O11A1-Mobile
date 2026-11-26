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
        R.drawable.ic_nav_home,
        R.drawable.ic_nav_follow,
        R.drawable.ic_nav_dynamic,
        R.drawable.ic_nav_fish
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
        android.graphics.drawable.GradientDrawable bar =
            NativeTheme.rounded(NativeTheme.isDark(context) ? 0xD60A0A0C : 0xB8FFFFFF,
                NativeTheme.dp(context, 29));
        bar.setStroke(Math.max(1, NativeTheme.dp(context, 0.5f)),
            NativeTheme.isDark(context) ? 0x1AFFFFFF : 0xCCFFFFFF);
        setBackground(bar);
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
            icon.setColorFilter(NativeTheme.tertiary(context));
            item.addView(icon, new LinearLayout.LayoutParams(
                NativeTheme.dp(context, 18), NativeTheme.dp(context, 18)));
            TextView label = new TextView(context);
            label.setText(titles[i]);
            label.setTextSize(TypedValue.COMPLEX_UNIT_SP, 9.5f);
            label.setTypeface(Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL));
            label.setTextColor(NativeTheme.tertiary(context));
            LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            labelParams.topMargin = NativeTheme.dp(context, 2);
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
            int color = active
                ? NativeTheme.navBlue(getContext())
                : NativeTheme.tertiary(getContext());
            images[i].setColorFilter(color);
            labels[i].setTextColor(color);
            labels[i].setTypeface(Typeface.create(
                Typeface.SANS_SERIF, active ? Typeface.BOLD : Typeface.NORMAL));
            if (active) {
                android.graphics.drawable.InsetDrawable pill =
                    new android.graphics.drawable.InsetDrawable(
                        NativeTheme.rounded(NativeTheme.navPill(),
                            NativeTheme.dp(getContext(), 24)),
                        NativeTheme.dp(getContext(), 4), NativeTheme.dp(getContext(), 4),
                        NativeTheme.dp(getContext(), 4), NativeTheme.dp(getContext(), 4));
                items[i].setBackground(pill);
            } else {
                items[i].setBackground(null);
            }
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
