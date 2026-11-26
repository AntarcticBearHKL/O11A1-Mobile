package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.bitmap.CircleCrop;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

final class ModuleAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    interface OnClick {
        void onClick(ModuleItem item, View source);
    }

    private static final int TYPE_MEDIA = 1;
    private static final int TYPE_MESSAGE = 2;

    private final Context context;
    private final List<ModuleItem> items = new ArrayList<>();
    private final OnClick onClick;

    ModuleAdapter(Context context, OnClick onClick) {
        this.context = context;
        this.onClick = onClick;
    }

    void setItems(List<ModuleItem> values) {
        items.clear();
        if (values != null) items.addAll(values);
        notifyDataSetChanged();
    }

    void append(List<ModuleItem> values) {
        if (values == null || values.isEmpty()) return;
        int start = items.size();
        items.addAll(values);
        notifyItemRangeInserted(start, values.size());
    }

    int itemCount() {
        return items.size();
    }

    @Override public int getItemViewType(int position) {
        return items.get(position).kind == ModuleItem.Kind.MESSAGE ? TYPE_MESSAGE : TYPE_MEDIA;
    }

    @NonNull
    @Override public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        if (viewType == TYPE_MESSAGE) {
            MessageRow row = new MessageRow(context);
            row.setLayoutParams(new RecyclerView.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
            return new MessageHolder(row);
        }
        MediaRow row = new MediaRow(context);
        row.setLayoutParams(new RecyclerView.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        return new MediaHolder(row);
    }

    @Override public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        ModuleItem item = items.get(position);
        if (holder instanceof MessageHolder) {
            ((MessageHolder) holder).row.setItem(item);
            holder.itemView.setOnClickListener(v -> {
                if (onClick != null) onClick.onClick(item, holder.itemView);
            });
        } else {
            MediaHolder media = (MediaHolder) holder;
            media.row.setItem(item);
            media.row.setOnClickListener(v -> {
                if (onClick != null) onClick.onClick(item, media.row.cover);
            });
        }
    }

    @Override public int getItemCount() {
        return items.size();
    }

    static final class MediaHolder extends RecyclerView.ViewHolder {
        final MediaRow row;
        MediaHolder(MediaRow row) {
            super(row);
            this.row = row;
        }
    }

    static final class MessageHolder extends RecyclerView.ViewHolder {
        final MessageRow row;
        MessageHolder(MessageRow row) {
            super(row);
            this.row = row;
        }
    }

    static final class MediaRow extends LinearLayout {
        final ImageView cover = new ImageView(getContext());
        private final TextView title = new TextView(getContext());
        private final TextView meta = new TextView(getContext());
        private final TextView duration = new TextView(getContext());
        private final TextView badge = new TextView(getContext());

        MediaRow(Context context) {
            super(context);
            setOrientation(HORIZONTAL);
            setGravity(Gravity.CENTER_VERTICAL);
            setPadding(NativeTheme.dp(context, 16), NativeTheme.dp(context, 8),
                NativeTheme.dp(context, 16), NativeTheme.dp(context, 8));

            FrameLayout thumb = new FrameLayout(context);
            cover.setScaleType(ImageView.ScaleType.CENTER_CROP);
            cover.setBackgroundColor(0xFF141414);
            thumb.addView(cover, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

            duration.setTextColor(Color.WHITE);
            duration.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
            duration.setTypeface(NativeTheme.numberTypeface());
            duration.setGravity(Gravity.CENTER);
            duration.setBackground(NativeTheme.rounded(0x99000000, NativeTheme.dp(context, 18)));
            duration.setPadding(NativeTheme.dp(context, 4), 0, NativeTheme.dp(context, 4), 0);
            FrameLayout.LayoutParams durationParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, NativeTheme.dp(context, 17));
            durationParams.gravity = Gravity.END | Gravity.BOTTOM;
            durationParams.rightMargin = NativeTheme.dp(context, 4);
            durationParams.bottomMargin = NativeTheme.dp(context, 4);
            thumb.addView(duration, durationParams);

            badge.setTextColor(Color.WHITE);
            badge.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
            badge.setGravity(Gravity.CENTER);
            badge.setBackground(NativeTheme.rounded(0xCCFF5C75, NativeTheme.dp(context, 18)));
            badge.setPadding(NativeTheme.dp(context, 4), 0, NativeTheme.dp(context, 4), 0);
            FrameLayout.LayoutParams badgeParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, NativeTheme.dp(context, 18));
            badgeParams.gravity = Gravity.START | Gravity.TOP;
            badgeParams.leftMargin = NativeTheme.dp(context, 4);
            badgeParams.topMargin = NativeTheme.dp(context, 4);
            thumb.addView(badge, badgeParams);

            addView(thumb, new LinearLayout.LayoutParams(
                NativeTheme.dp(context, 142), NativeTheme.dp(context, 86)));

            LinearLayout texts = new LinearLayout(context);
            texts.setOrientation(VERTICAL);
            LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
            textParams.leftMargin = NativeTheme.dp(context, 12);
            addView(texts, textParams);

            title.setTextColor(NativeTheme.foreground(context));
            title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
            title.setTypeface(NativeTheme.titleTypeface());
            title.setMaxLines(2);
            title.setEllipsize(TextUtils.TruncateAt.END);
            texts.addView(title, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

            meta.setTextColor(NativeTheme.secondary(context));
            meta.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            LinearLayout.LayoutParams metaParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            metaParams.topMargin = NativeTheme.dp(context, 8);
            texts.addView(meta, metaParams);

            setMinimumHeight(NativeTheme.dp(context, 102));
        }

        void setItem(ModuleItem item) {
            title.setText(item.title);
            meta.setText(item.meta == null || item.meta.isEmpty() ? item.owner : item.meta);
            duration.setText(item.duration == null || item.duration.isEmpty() ? "" : item.duration);
            duration.setVisibility(item.duration == null || item.duration.isEmpty() ? GONE : VISIBLE);
            badge.setText(item.badge);
            badge.setVisibility(item.badge == null || item.badge.isEmpty() ? GONE : VISIBLE);
            if (item.kind == ModuleItem.Kind.SEASON) {
                View thumb = (View) cover.getParent();
                ViewGroup.LayoutParams lp = thumb.getLayoutParams();
                lp.width = NativeTheme.dp(getContext(), 100);
                lp.height = NativeTheme.dp(getContext(), 136);
                thumb.setLayoutParams(lp);
            } else {
                View thumb = (View) cover.getParent();
                ViewGroup.LayoutParams lp = thumb.getLayoutParams();
                lp.width = NativeTheme.dp(getContext(), 142);
                lp.height = NativeTheme.dp(getContext(), 86);
                thumb.setLayoutParams(lp);
            }
            Glide.with(this).load(item.pic).centerCrop().into(cover);
        }
    }

    static final class MessageRow extends LinearLayout {
        private final ImageView avatar = new ImageView(getContext());
        private final TextView name = new TextView(getContext());
        private final TextView text = new TextView(getContext());
        private final TextView time = new TextView(getContext());

        MessageRow(Context context) {
            super(context);
            setOrientation(HORIZONTAL);
            setPadding(NativeTheme.dp(context, 18), NativeTheme.dp(context, 12),
                NativeTheme.dp(context, 18), NativeTheme.dp(context, 12));

            avatar.setBackgroundColor(0xFF141414);
            addView(avatar, new LinearLayout.LayoutParams(
                NativeTheme.dp(context, 42), NativeTheme.dp(context, 42)));

            LinearLayout body = new LinearLayout(context);
            body.setOrientation(VERTICAL);
            LinearLayout.LayoutParams bodyParams = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
            bodyParams.leftMargin = NativeTheme.dp(context, 12);
            addView(body, bodyParams);

            name.setTextColor(NativeTheme.secondary(context));
            name.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            body.addView(name);

            text.setTextColor(NativeTheme.foreground(context));
            text.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
            text.setMaxLines(3);
            text.setEllipsize(TextUtils.TruncateAt.END);
            LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            textParams.topMargin = NativeTheme.dp(context, 4);
            body.addView(text, textParams);

            time.setTextColor(NativeTheme.tertiary(context));
            time.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
            LinearLayout.LayoutParams timeParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            timeParams.topMargin = NativeTheme.dp(context, 6);
            body.addView(time, timeParams);
        }

        void setItem(ModuleItem item) {
            name.setText(item.user);
            text.setText(item.text);
            if (item.time > 0) {
                long seconds = item.time > 100000000000L ? item.time / 1000 : item.time;
                time.setText(new SimpleDateFormat("MM-dd HH:mm", Locale.CHINA)
                    .format(new Date(seconds * 1000)));
            } else {
                time.setText("");
            }
            if (item.avatar == null || item.avatar.isEmpty()) {
                avatar.setImageResource(android.R.drawable.sym_def_app_icon);
            } else {
                Glide.with(this).load(item.avatar).transform(new CircleCrop()).into(avatar);
            }
        }
    }
}
