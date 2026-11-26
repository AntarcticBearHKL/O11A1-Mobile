package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.bitmap.CircleCrop;

/**
 * Home feed card matching the original web layout:
 * full-width 16:9 cover, glass info row below it, 14dp bottom corners.
 */
final class HomeCardView extends LinearLayout {
    final FrameLayout mediaHost;
    final ImageView cover;
    private final ImageView avatar;
    private final TextView title;
    private final TextView owner;
    private final TextView play;
    private final TextView time;
    private final TextView duration;
    private final TextView live;
    private final View progress;
    private final View progressFill;
    private VideoItem item;
    private Runnable onAvatar;
    private Runnable onOpen;

    HomeCardView(Context context) {
        super(context);
        setOrientation(VERTICAL);
        setBackgroundColor(Color.TRANSPARENT);
        setClipChildren(false);

        FrameLayout media = new FrameLayout(context) {
            @Override protected void onMeasure(int widthSpec, int heightSpec) {
                int width = MeasureSpec.getSize(widthSpec);
                int height = Math.round(width * 9f / 16f);
                super.onMeasure(widthSpec,
                    MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY));
            }
        };
        media.setClipChildren(true);
        addView(media, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        cover = new ImageView(context);
        cover.setScaleType(ImageView.ScaleType.CENTER_CROP);
        cover.setBackgroundColor(0xFFE4E7EC);
        media.addView(cover, new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        mediaHost = new FrameLayout(context);
        mediaHost.setBackgroundColor(Color.TRANSPARENT);
        mediaHost.setClickable(false);
        media.addView(mediaHost, new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        duration = new TextView(context);
        duration.setTextColor(Color.WHITE);
        duration.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
        duration.setTypeface(NativeTheme.numberTypeface());
        duration.setGravity(Gravity.CENTER);
        duration.setPadding(NativeTheme.dp(context, 6), NativeTheme.dp(context, 2),
            NativeTheme.dp(context, 6), NativeTheme.dp(context, 2));
        duration.setBackground(NativeTheme.rounded(0xC7000000, NativeTheme.dp(context, 18)));
        FrameLayout.LayoutParams durationParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        durationParams.gravity = Gravity.END | Gravity.BOTTOM;
        durationParams.rightMargin = NativeTheme.dp(context, 8);
        durationParams.bottomMargin = NativeTheme.dp(context, 8);
        media.addView(duration, durationParams);

        live = new TextView(context);
        live.setText("LIVE");
        live.setTextColor(Color.WHITE);
        live.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
        live.setTypeface(NativeTheme.titleTypeface());
        live.setGravity(Gravity.CENTER);
        live.setPadding(NativeTheme.dp(context, 7), NativeTheme.dp(context, 2),
            NativeTheme.dp(context, 7), NativeTheme.dp(context, 2));
        live.setBackground(NativeTheme.rounded(0xFFE53E3E, NativeTheme.dp(context, 18)));
        FrameLayout.LayoutParams liveParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        liveParams.gravity = Gravity.START | Gravity.TOP;
        liveParams.leftMargin = NativeTheme.dp(context, 8);
        liveParams.topMargin = NativeTheme.dp(context, 8);
        media.addView(live, liveParams);

        FrameLayout progressTrack = new FrameLayout(context);
        progressTrack.setBackgroundColor(0x47FFFFFF);
        progress = progressTrack;
        FrameLayout.LayoutParams progressParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 3));
        progressParams.gravity = Gravity.BOTTOM;
        media.addView(progress, progressParams);
        progressFill = new View(context);
        progressFill.setBackgroundColor(0xFFFF2D2D);
        progressTrack.addView(progressFill, new FrameLayout.LayoutParams(0,
            FrameLayout.LayoutParams.MATCH_PARENT));

        LinearLayout copy = new LinearLayout(context);
        copy.setOrientation(HORIZONTAL);
        copy.setGravity(Gravity.CENTER_VERTICAL);
        copy.setPadding(NativeTheme.dp(context, 16), NativeTheme.dp(context, 13),
            NativeTheme.dp(context, 16), NativeTheme.dp(context, 16));
        GradientDrawable copyBg = new GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            NativeTheme.isDark(context)
                ? new int[]{0xDB1C1E25, 0xC2111217}
                : new int[]{0xCCFFFFFF, 0x94FFFFFF});
        float r = NativeTheme.dp(context, 18);
        copyBg.setCornerRadii(new float[]{0, 0, 0, 0, r, r, r, r});
        copyBg.setStroke(Math.max(1, NativeTheme.dp(context, 0.5f)),
            NativeTheme.isDark(context) ? 0x12FFFFFF : 0x75FFFFFF);
        copy.setBackground(copyBg);
        copy.setElevation(NativeTheme.dp(context, 3));
        addView(copy, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        avatar = new ImageView(context);
        avatar.setBackgroundColor(0xFFF0F0F2);
        avatar.setClipToOutline(true);
        copy.addView(avatar, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 50), NativeTheme.dp(context, 50)));

        LinearLayout text = new LinearLayout(context);
        text.setOrientation(VERTICAL);
        LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(
            0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        textParams.leftMargin = NativeTheme.dp(context, 12);
        copy.addView(text, textParams);

        title = new TextView(context);
        title.setTextColor(NativeTheme.foreground(context));
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16);
        title.setTypeface(NativeTheme.titleTypeface(), android.graphics.Typeface.BOLD);
        title.setMaxLines(2);
        title.setEllipsize(TextUtils.TruncateAt.END);
        title.setLineSpacing(0, 1.2f);
        text.addView(title, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        LinearLayout meta = new LinearLayout(context);
        meta.setOrientation(HORIZONTAL);
        meta.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams metaParams = new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        metaParams.topMargin = NativeTheme.dp(context, 5);
        text.addView(meta, metaParams);

        owner = new TextView(context);
        owner.setTextColor(NativeTheme.secondary(context));
        owner.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        owner.setSingleLine(true);
        owner.setEllipsize(TextUtils.TruncateAt.END);
        meta.addView(owner, new LinearLayout.LayoutParams(0,
            LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        play = new TextView(context);
        play.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        play.setTypeface(NativeTheme.numberTypeface());
        play.setGravity(Gravity.CENTER);
        play.setSingleLine(true);
        meta.addView(play, new LinearLayout.LayoutParams(0,
            LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        time = new TextView(context);
        time.setTextColor(NativeTheme.tertiary(context));
        time.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        time.setTypeface(NativeTheme.numberTypeface());
        time.setGravity(Gravity.END);
        time.setSingleLine(true);
        meta.addView(time, new LinearLayout.LayoutParams(0,
            LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        setOnClickListener(v -> {
            if (onOpen != null) onOpen.run();
        });
        avatar.setOnClickListener(v -> {
            if (onAvatar != null) onAvatar.run();
        });
    }

    void setItem(VideoItem value, Runnable avatarAction, Runnable openAction) {
        item = value;
        onAvatar = avatarAction;
        onOpen = openAction;
        title.setText(value.title);
        owner.setText(value.owner);
        play.setText(value.playText.isEmpty() ? "" : value.playText + "播放");
        play.setTextColor(NativeTheme.playColor(value.play));
        time.setText(NativeTheme.freshness(value.pubdate));
        time.setTextColor(NativeTheme.freshnessColor(value.pubdate));
        duration.setText(value.live ? "" : value.duration);
        duration.setVisibility(value.live ? GONE : VISIBLE);
        live.setVisibility(value.live ? VISIBLE : GONE);
        if (value.progressSec > 0 && value.durationSec > 0) {
            float ratio = Math.min(1f, value.progressSec / (float) value.durationSec);
            progress.setVisibility(VISIBLE);
            progress.post(() -> {
                ViewGroup.LayoutParams lp = progressFill.getLayoutParams();
                lp.width = Math.round(progress.getWidth() * ratio);
                progressFill.setLayoutParams(lp);
            });
        } else {
            progress.setVisibility(GONE);
        }
        Glide.with(this).load(value.pic).centerCrop().into(cover);
        if (value.ownerFace == null || value.ownerFace.isEmpty()) {
            avatar.setImageResource(android.R.drawable.sym_def_app_icon);
        } else {
            Glide.with(this).load(value.ownerFace).transform(new CircleCrop()).into(avatar);
        }
    }

    FrameLayout mediaHost() {
        return mediaHost;
    }

    VideoItem item() {
        return item;
    }
}
