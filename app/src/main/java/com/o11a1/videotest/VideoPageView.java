package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.bitmap.CircleCrop;

final class VideoPageView extends FrameLayout {
    final FrameLayout mediaHost;
    private final ImageView cover;
    private final ImageView avatar;
    private final TextView title;
    private final TextView owner;
    private final TextView play;
    private final TextView time;
    private VideoItem item;
    private Runnable onAvatar;
    private Runnable onOpen;

    VideoPageView(Context context) {
        super(context);
        setBackgroundColor(Color.BLACK);
        setClipChildren(true);

        cover = new ImageView(context);
        cover.setScaleType(ImageView.ScaleType.CENTER_CROP);
        cover.setBackgroundColor(0xFF141414);
        addView(cover, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        mediaHost = new FrameLayout(context);
        mediaHost.setBackgroundColor(Color.TRANSPARENT);
        addView(mediaHost, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        View gradient = new View(context);
        GradientDrawable shade = new GradientDrawable(
            GradientDrawable.Orientation.BOTTOM_TOP,
            new int[]{0xDD000000, 0x66000000, 0x00000000}
        );
        gradient.setBackground(shade);
        addView(gradient, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        LinearLayout panel = new LinearLayout(context);
        panel.setOrientation(LinearLayout.VERTICAL);
        GradientDrawable panelBg = new GradientDrawable();
        panelBg.setColor(0xB3000000);
        float radius = NativeTheme.dp(context, 18);
        panelBg.setCornerRadii(new float[]{0, 0, 0, 0, radius, radius, radius, radius});
        panelBg.setStroke(Math.max(1, NativeTheme.dp(context, 0.5f)), 0x22FFFFFF);
        panel.setBackground(panelBg);
        panel.setPadding(NativeTheme.dp(context, 16), NativeTheme.dp(context, 14),
            NativeTheme.dp(context, 16), NativeTheme.dp(context, 14));
        FrameLayout.LayoutParams panelParams = new FrameLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        panelParams.gravity = Gravity.BOTTOM;
        panelParams.bottomMargin = NativeTheme.dp(context, 76);
        addView(panel, panelParams);

        LinearLayout header = new LinearLayout(context);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        panel.addView(header, new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT));

        avatar = new ImageView(context);
        avatar.setBackgroundColor(0x22FFFFFF);
        avatar.setClipToOutline(true);
        header.addView(avatar, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 50), NativeTheme.dp(context, 50)));
        avatar.setOnClickListener(v -> {
            if (onAvatar != null) onAvatar.run();
        });

        title = new TextView(context);
        title.setTextColor(Color.WHITE);
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17);
        title.setTypeface(NativeTheme.titleTypeface());
        title.setMaxLines(2);
        title.setEllipsize(TextUtils.TruncateAt.END);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
            0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        titleParams.leftMargin = NativeTheme.dp(context, 12);
        header.addView(title, titleParams);

        LinearLayout footer = new LinearLayout(context);
        footer.setOrientation(LinearLayout.HORIZONTAL);
        footer.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams footerParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        footerParams.topMargin = NativeTheme.dp(context, 12);
        panel.addView(footer, footerParams);

        owner = new TextView(context);
        owner.setTextColor(0xB3FFFFFF);
        owner.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        owner.setSingleLine(true);
        owner.setEllipsize(TextUtils.TruncateAt.END);
        footer.addView(owner, new LinearLayout.LayoutParams(
            0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        play = new TextView(context);
        play.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        play.setTypeface(NativeTheme.numberTypeface());
        play.setGravity(Gravity.CENTER);
        footer.addView(play, new LinearLayout.LayoutParams(
            0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        time = new TextView(context);
        time.setTextColor(0xB3FFFFFF);
        time.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        time.setTypeface(NativeTheme.numberTypeface());
        time.setGravity(Gravity.END);
        footer.addView(time, new LinearLayout.LayoutParams(
            0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        setOnClickListener(v -> {
            if (onOpen != null) onOpen.run();
        });
    }

    void setItem(VideoItem value, Runnable avatarAction, Runnable openAction) {
        item = value;
        onAvatar = avatarAction;
        onOpen = openAction;
        title.setText(value.title);
        owner.setText(value.owner);
        play.setText(value.playText);
        play.setTextColor(NativeTheme.playColor(value.play));
        time.setText(value.duration);
        Glide.with(this).load(value.pic).centerCrop().into(cover);
        if (value.ownerFace == null || value.ownerFace.isEmpty()) {
            avatar.setImageResource(android.R.drawable.sym_def_app_icon);
        } else {
            Glide.with(this).load(value.ownerFace).transform(new CircleCrop()).into(avatar);
        }
    }

    VideoItem item() {
        return item;
    }
}
