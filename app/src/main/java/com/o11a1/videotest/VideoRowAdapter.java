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

import java.util.ArrayList;
import java.util.List;

final class VideoRowAdapter extends RecyclerView.Adapter<VideoRowAdapter.Holder> {
    interface OnClick {
        void onClick(VideoItem item, View source);
    }

    private final Context context;
    private final List<VideoItem> items = new ArrayList<>();
    private final OnClick onClick;

    VideoRowAdapter(Context context, OnClick onClick) {
        this.context = context;
        this.onClick = onClick;
    }

    void setItems(List<VideoItem> values) {
        items.clear();
        if (values != null) items.addAll(values);
        notifyDataSetChanged();
    }

    void append(List<VideoItem> values) {
        if (values == null || values.isEmpty()) return;
        int start = items.size();
        items.addAll(values);
        notifyItemRangeInserted(start, values.size());
    }

    @NonNull
    @Override
    public Holder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new Holder(new RowView(context));
    }

    @Override
    public void onBindViewHolder(@NonNull Holder holder, int position) {
        VideoItem item = items.get(position);
        holder.row.setItem(item);
        holder.row.setOnClickListener(v -> {
            if (onClick != null) onClick.onClick(item, holder.row.cover);
        });
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    static final class Holder extends RecyclerView.ViewHolder {
        final RowView row;
        Holder(RowView row) {
            super(row);
            this.row = row;
        }
    }

    static final class RowView extends LinearLayout {
        final ImageView cover = new ImageView(getContext());
        private final TextView title = new TextView(getContext());
        private final TextView meta = new TextView(getContext());
        private final TextView duration = new TextView(getContext());

        RowView(Context context) {
            super(context);
            setOrientation(HORIZONTAL);
            setGravity(Gravity.CENTER_VERTICAL);
            setPadding(NativeTheme.dp(context, 16), NativeTheme.dp(context, 8),
                NativeTheme.dp(context, 16), NativeTheme.dp(context, 8));
            setBackgroundColor(Color.TRANSPARENT);

            FrameLayout thumb = new FrameLayout(context);
            cover.setBackgroundColor(0xFF141414);
            cover.setScaleType(ImageView.ScaleType.CENTER_CROP);
            thumb.addView(cover, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
            duration.setTextColor(Color.WHITE);
            duration.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
            duration.setTypeface(NativeTheme.numberTypeface());
            duration.setGravity(Gravity.CENTER);
            duration.setBackground(NativeTheme.rounded(0x99000000, NativeTheme.dp(context, 18)));
            FrameLayout.LayoutParams dp = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, NativeTheme.dp(context, 17));
            dp.gravity = Gravity.END | Gravity.BOTTOM;
            dp.rightMargin = NativeTheme.dp(context, 4);
            dp.bottomMargin = NativeTheme.dp(context, 4);
            thumb.addView(duration, dp);
            LinearLayout.LayoutParams thumbParams = new LinearLayout.LayoutParams(
                NativeTheme.dp(context, 146), NativeTheme.dp(context, 86));
            addView(thumb, thumbParams);

            LinearLayout texts = new LinearLayout(context);
            texts.setOrientation(VERTICAL);
            LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, 1f);
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

        void setItem(VideoItem item) {
            title.setText(item.title);
            meta.setText(item.owner + " · " + item.playText + " 播放");
            duration.setText(item.duration);
            Glide.with(this).load(item.pic).centerCrop().into(cover);
        }
    }
}
