package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class VideoListView extends FrameLayout {
    enum Mode { FOLLOWING, DYNAMIC, SPACE }

    interface OnOpen {
        void open(VideoItem item, View source);
    }

    private final BiliExtras extras;
    private final Mode mode;
    private final long mid;
    private final OnOpen onOpen;
    private final Runnable onLogin;
    private final VideoRowAdapter adapter;
    private final RecyclerView list;
    private final TextView status;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private int page = 1;
    private boolean loading = false;

    VideoListView(Context context, BiliExtras extras, Mode mode, long mid, OnOpen onOpen, Runnable onLogin) {
        super(context);
        this.extras = extras;
        this.mode = mode;
        this.mid = mid;
        this.onOpen = onOpen;
        this.onLogin = onLogin;
        setBackgroundColor(NativeTheme.background(context));

        LinearLayout top = new LinearLayout(context);
        top.setOrientation(LinearLayout.VERTICAL);
        top.setPadding(NativeTheme.dp(context, 20), statusBar(context) + NativeTheme.dp(context, 14),
            0, NativeTheme.dp(context, 8));
        addView(top, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        TextView title = new TextView(context);
        title.setText(mode == Mode.FOLLOWING ? "关注" : mode == Mode.DYNAMIC ? "动态" : "UP 主页");
        title.setTextColor(NativeTheme.foreground(context));
        title.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 24);
        title.setTypeface(NativeTheme.titleTypeface());
        top.addView(title);

        list = new RecyclerView(context);
        list.setLayoutManager(new LinearLayoutManager(context));
        list.setClipToPadding(false);
        adapter = new VideoRowAdapter(context, (item, source) -> {
            if (onOpen != null) onOpen.open(item, source);
        });
        list.setAdapter(adapter);
        list.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override public void onScrolled(RecyclerView recyclerView, int dx, int dy) {
                if (!recyclerView.canScrollVertically(1)) load();
            }
        });
        LayoutParams listParams = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        listParams.topMargin = NativeTheme.dp(context, 76) + statusBar(context);
        addView(list, listParams);

        status = new TextView(context);
        status.setTextColor(NativeTheme.secondary(context));
        status.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 14);
        status.setGravity(Gravity.CENTER);
        status.setVisibility(GONE);
        status.setOnClickListener(v -> {
            if (onLogin != null) onLogin.run();
        });
        LayoutParams statusParams = new LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        statusParams.gravity = Gravity.CENTER;
        addView(status, statusParams);

        load();
    }

    private static int statusBar(Context context) {
        int id = context.getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? context.getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }

    private void load() {
        if (loading) return;
        loading = true;
        if (adapter.getItemCount() == 0) {
            status.setText("正在加载…");
            status.setVisibility(VISIBLE);
        }
        final int request = page;
        pool.execute(() -> {
            JSONObject result;
            if (mode == Mode.DYNAMIC) {
                result = extras.dynamicFeed(request, "all");
            } else if (mode == Mode.SPACE) {
                result = extras.space(mid, request, "pubdate");
            } else {
                result = extras.following(request);
            }
            final JSONObject value = result;
            main.post(() -> {
                loading = false;
                if (value == null || !value.optBoolean("ok", false)) {
                    if (adapter.getItemCount() == 0) {
                        status.setText(value == null ? "加载失败" : value.optString("error", "加载失败"));
                        status.setVisibility(VISIBLE);
                    }
                    return;
                }
                List<VideoItem> rows = new ArrayList<>();
                JSONArray array = value.optJSONArray("items");
                if (array != null) {
                    for (int i = 0; i < array.length(); i++) {
                        JSONObject row = array.optJSONObject(i);
                        if (row != null) rows.add(VideoItem.from(row));
                    }
                }
                adapter.append(rows);
                page += 1;
                status.setVisibility(rows.isEmpty() && adapter.getItemCount() == 0 ? VISIBLE : GONE);
            });
        });
    }

    void reload() {
        adapter.setItems(new ArrayList<>());
        page = 1;
        load();
    }

    void destroy() {
        pool.shutdownNow();
    }
}
