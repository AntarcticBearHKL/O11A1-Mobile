package com.o11a1.videotest;

import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.HapticFeedbackConstants;
import android.view.View;
import android.view.animation.OvershootInterpolator;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

final class GlassTabBarView extends FrameLayout {
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
    private final LinearLayout row;
    private final LinearLayout[] items = new LinearLayout[titles.length];
    private final ImageView[] images = new ImageView[titles.length];
    private final TextView[] labels = new TextView[titles.length];
    private final View pill;
    private OnSelect onSelect;
    private int selected = 0;
    private boolean hidden = false;
    private float pillLeft = -1;
    private float pillWidth = 0;
    private ValueAnimator pillAnimator;

    GlassTabBarView(Context context) {
        super(context);
        setClipChildren(false);
        setClipToPadding(false);
        GradientDrawable bar = NativeTheme.rounded(
            NativeTheme.isDark(context) ? 0xD60A0A0C : 0xB8FFFFFF,
            NativeTheme.dp(context, 18));
        bar.setStroke(Math.max(1, NativeTheme.dp(context, 0.5f)),
            NativeTheme.isDark(context) ? 0x1AFFFFFF : 0xCCFFFFFF);
        setBackground(bar);
        setElevation(NativeTheme.dp(context, 12));

        pill = new View(context);
        GradientDrawable pillBg = NativeTheme.rounded(NativeTheme.navPill(),
            NativeTheme.dp(context, 14));
        pill.setBackground(pillBg);
        LayoutParams pillParams = new LayoutParams(0, 0);
        pillParams.gravity = Gravity.TOP | Gravity.LEFT;
        addView(pill, pillParams);

        row = new LinearLayout(context);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER);
        row.setPadding(NativeTheme.dp(context, 6), 0, NativeTheme.dp(context, 6), 0);
        addView(row, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        for (int i = 0; i < titles.length; i++) {
            LinearLayout item = new LinearLayout(context);
            item.setOrientation(LinearLayout.VERTICAL);
            item.setGravity(Gravity.CENTER);
            item.setClickable(true);
            final int index = i;
            item.setOnClickListener(v -> {
                if (index == selected) {
                    bounce(images[index]);
                    return;
                }
                select(index, true);
            });
            ImageView icon = new ImageView(context);
            icon.setImageResource(icons[i]);
            icon.setColorFilter(NativeTheme.tertiary(context));
            item.addView(icon, new LinearLayout.LayoutParams(
                NativeTheme.dp(context, 19), NativeTheme.dp(context, 19)));
            TextView label = new TextView(context);
            label.setText(titles[i]);
            label.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10f);
            label.setTypeface(Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL));
            label.setTextColor(NativeTheme.tertiary(context));
            LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            labelParams.topMargin = NativeTheme.dp(context, 2);
            item.addView(label, labelParams);
            row.addView(item, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f));
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
        boolean changed = index != selected;
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
            items[i].setBackground(null);
            items[i].setAlpha(active ? 1f : 0.9f);
        }
        if (changed) {
            animatePillToSelected();
            bounce(images[index]);
            performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK);
        } else {
            positionPill();
        }
        if (notify && onSelect != null) onSelect.select(index);
    }

    int selected() {
        return selected;
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        super.onLayout(changed, l, t, r, b);
        if (!isPillAnimating()) {
            positionPill();
        }
    }

    private boolean isPillAnimating() {
        return pillAnimator != null && pillAnimator.isRunning();
    }

    private float[] pillTarget() {
        View item = items[selected];
        float inset = NativeTheme.dp(getContext(), 4);
        return new float[]{row.getLeft() + item.getLeft() + inset,
            Math.max(0, item.getWidth() - inset * 2)};
    }

    private void positionPill() {
        if (items[selected].getWidth() <= 0) return;
        float[] target = pillTarget();
        pillLeft = target[0];
        pillWidth = target[1];
        LayoutParams params = (LayoutParams) pill.getLayoutParams();
        params.width = Math.round(pillWidth);
        params.height = Math.max(0, getHeight() - NativeTheme.dp(getContext(), 8));
        params.leftMargin = Math.round(pillLeft);
        params.topMargin = NativeTheme.dp(getContext(), 4);
        pill.setLayoutParams(params);
        pill.setAlpha(1f);
    }

    private void animatePillToSelected() {
        if (items[selected].getWidth() <= 0) {
            positionPill();
            return;
        }
        float[] target = pillTarget();
        if (pillLeft < 0) {
            positionPill();
            return;
        }
        if (pillAnimator != null) pillAnimator.cancel();
        float startLeft = pillLeft;
        float startWidth = pillWidth;
        pillAnimator = ValueAnimator.ofFloat(0f, 1f);
        pillAnimator.setDuration(420);
        pillAnimator.setInterpolator(new OvershootInterpolator(0.9f));
        pillAnimator.addUpdateListener(animation -> {
            float f = (float) animation.getAnimatedValue();
            pillLeft = startLeft + (target[0] - startLeft) * f;
            pillWidth = startWidth + (target[1] - startWidth) * f;
            LayoutParams params = (LayoutParams) pill.getLayoutParams();
            params.width = Math.max(0, Math.round(pillWidth));
            params.leftMargin = Math.round(pillLeft);
            pill.setLayoutParams(params);
        });
        pillAnimator.start();
    }

    private void bounce(ImageView icon) {
        icon.animate().cancel();
        icon.setScaleX(0.82f);
        icon.setScaleY(0.82f);
        icon.animate()
            .scaleX(1f)
            .scaleY(1f)
            .setStartDelay(45)
            .setDuration(260)
            .setInterpolator(new OvershootInterpolator(1.6f))
            .start();
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
