package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageButton;
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

final class ModuleView extends FrameLayout {
    enum Type { HOT, RANK, BANGUMI, MOVIE, LIVE, ZONE, FAVORITES, HISTORY, FOLLOWING, DYNAMIC, MESSAGES, SEASON, SPACE }

    interface Listener {
        void onItem(ModuleItem item);
        void onLogin();
        void onClose();
    }

    private final Context context;
    private final BiliApi api;
    private final BiliExtras extras;
    private final Type type;
    private final long targetId;
    private final String initialTitle;
    private final Listener listener;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ModuleAdapter adapter;
    private final RecyclerView list;
    private final TextView status;
    private final TextView titleView;
    private final LinearLayout filters;
    private final String[] filterLabels;
    private final int[] filterValues;
    private int filterIndex = 0;
    private int page = 1;
    private String cursor = "";
    private boolean loading = false;
    private boolean hasMore = true;

    ModuleView(Context context, BiliApi api, BiliExtras extras, Type type, long targetId,
               String title, Listener listener) {
        super(context);
        this.context = context;
        this.api = api;
        this.extras = extras;
        this.type = type;
        this.targetId = targetId;
        this.initialTitle = title;
        this.listener = listener;
        setBackgroundColor(NativeTheme.background(context));
        setClickable(true);

        LinearLayout top = new LinearLayout(context);
        top.setOrientation(LinearLayout.VERTICAL);
        top.setPadding(NativeTheme.dp(context, 8), statusBar() + NativeTheme.dp(context, 6),
            NativeTheme.dp(context, 8), 0);
        addView(top, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        LinearLayout titleRow = new LinearLayout(context);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);
        top.addView(titleRow, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 48)));

        ImageButton back = new ImageButton(context);
        back.setImageResource(R.drawable.ic_back);
        back.setBackgroundColor(Color.TRANSPARENT);
        back.setColorFilter(NativeTheme.foreground(context));
        back.setOnClickListener(v -> {
            if (listener != null) listener.onClose();
        });
        titleRow.addView(back, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 44), NativeTheme.dp(context, 44)));

        titleView = new TextView(context);
        titleView.setText(initialTitle);
        titleView.setTextColor(NativeTheme.foreground(context));
        titleView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 20);
        titleView.setTypeface(NativeTheme.titleTypeface());
        titleView.setSingleLine(true);
        titleView.setEllipsize(android.text.TextUtils.TruncateAt.END);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
            0, LayoutParams.WRAP_CONTENT, 1f);
        titleParams.leftMargin = NativeTheme.dp(context, 4);
        titleRow.addView(titleView, titleParams);

        if (type == Type.BANGUMI || type == Type.MOVIE) {
            filterLabels = type == Type.BANGUMI
                ? new String[]{"番剧", "国创", "电影"}
                : new String[]{"电影", "纪录片", "电视剧"};
            filterValues = type == Type.BANGUMI
                ? new int[]{1, 4, 2}
                : new int[]{2, 3, 5};
        } else if (type == Type.ZONE) {
            filterLabels = new String[]{"动画", "音乐", "游戏", "科技"};
            filterValues = new int[]{1, 3, 4, 36};
        } else if (type == Type.MESSAGES) {
            filterLabels = new String[]{"回复", "@我", "点赞"};
            filterValues = new int[]{0, 1, 2};
        } else {
            filterLabels = new String[0];
            filterValues = new int[0];
        }

        filters = new LinearLayout(context);
        filters.setOrientation(LinearLayout.HORIZONTAL);
        filters.setGravity(Gravity.CENTER_VERTICAL);
        filters.setPadding(0, 0, 0, NativeTheme.dp(context, 4));
        HorizontalScrollView filterScroll = new HorizontalScrollView(context);
        filterScroll.setHorizontalScrollBarEnabled(false);
        filterScroll.addView(filters, new HorizontalScrollView.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));
        top.addView(filterScroll, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));
        buildFilters();

        list = new RecyclerView(context);
        list.setLayoutManager(new LinearLayoutManager(context));
        list.setClipToPadding(false);
        adapter = new ModuleAdapter(context, (item, source) -> {
            if (listener != null) listener.onItem(item);
        });
        list.setAdapter(adapter);
        list.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override public void onScrolled(RecyclerView recyclerView, int dx, int dy) {
                if (!recyclerView.canScrollVertically(1)) load(false);
            }
        });
        LayoutParams listParams = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        listParams.topMargin = statusBar() + NativeTheme.dp(context, 58)
            + (filterLabels.length > 0 ? NativeTheme.dp(context, 40) : 0);
        addView(list, listParams);

        status = new TextView(context);
        status.setTextColor(NativeTheme.secondary(context));
        status.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        status.setGravity(Gravity.CENTER);
        status.setVisibility(GONE);
        LayoutParams statusParams = new LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        statusParams.gravity = Gravity.CENTER;
        addView(status, statusParams);

        load(true);
    }

    private int statusBar() {
        int id = getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }

    private void buildFilters() {
        filters.removeAllViews();
        for (int i = 0; i < filterLabels.length; i++) {
            final int index = i;
            TextView chip = new TextView(context);
            chip.setText(filterLabels[i]);
            chip.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            chip.setGravity(Gravity.CENTER);
            chip.setPadding(NativeTheme.dp(context, 14), NativeTheme.dp(context, 6),
                NativeTheme.dp(context, 14), NativeTheme.dp(context, 6));
            chip.setOnClickListener(v -> {
                if (filterIndex == index) return;
                filterIndex = index;
                page = 1;
                cursor = "";
                hasMore = true;
                adapter.setItems(new ArrayList<>());
                buildFilters();
                load(true);
            });
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
            params.rightMargin = NativeTheme.dp(context, 8);
            filters.addView(chip, params);
            styleChip(chip, i == filterIndex);
        }
    }

    private void styleChip(TextView chip, boolean active) {
        chip.setTextColor(active ? Color.WHITE : NativeTheme.secondary(context));
        chip.setBackground(NativeTheme.rounded(
            active ? NativeTheme.ACCENT : (NativeTheme.isDark(context) ? 0x22FFFFFF : 0x0D000000),
            NativeTheme.dp(context, 14)));
    }

    private void load(boolean reset) {
        if (loading || (!hasMore && !reset)) return;
        if (reset) {
            page = 1;
            cursor = "";
            hasMore = true;
        }
        loading = true;
        if (adapter.itemCount() == 0) {
            status.setText("正在加载…");
            status.setVisibility(VISIBLE);
        }
        final int requestPage = page;
        final String requestCursor = cursor;
        final int seasonType = filterValues.length > 0 ? filterValues[filterIndex] : 0;
        final String messageFilter = type == Type.MESSAGES
            ? (filterIndex == 1 ? "at" : (filterIndex == 2 ? "like" : "reply")) : "all";
        pool.execute(() -> {
            JSONObject result;
            switch (type) {
                case HOT: result = api.popular(requestPage, 20); break;
                case RANK: result = extras.ranking(requestPage); break;
                case BANGUMI:
                case MOVIE: result = extras.bangumi(requestPage, seasonType); break;
                case LIVE: result = extras.live(requestPage); break;
                case ZONE: result = extras.zone(seasonType, requestPage); break;
                case FAVORITES: result = extras.favorites(requestPage); break;
                case HISTORY: result = extras.history(requestPage, requestCursor); break;
                case FOLLOWING: result = extras.following(requestPage); break;
                case DYNAMIC: result = extras.dynamicFeed(requestPage, "all"); break;
                case MESSAGES: result = extras.messages(requestPage, messageFilter); break;
                case SEASON: result = extras.season(targetId); break;
                case SPACE:
                default: result = extras.space(targetId, requestPage, "pubdate"); break;
            }
            final JSONObject value = result;
            main.post(() -> apply(value, reset));
        });
    }

    private void apply(JSONObject value, boolean reset) {
        loading = false;
        if (value == null || !value.optBoolean("ok", false)) {
            String error = value == null ? "加载失败" : value.optString("error", "加载失败");
            if (adapter.itemCount() == 0) {
                status.setText(error);
                status.setVisibility(VISIBLE);
                if (error.contains("登录") && listener != null) {
                    status.setOnClickListener(v -> listener.onLogin());
                }
            }
            return;
        }
        List<ModuleItem> rows = new ArrayList<>();
        if (type == Type.SEASON) {
            JSONArray episodes = value.optJSONArray("episodes");
            titleView.setText(value.optString("title", initialTitle));
            if (episodes != null) {
                for (int i = 0; i < episodes.length(); i++) {
                    JSONObject row = episodes.optJSONObject(i);
                    if (row != null) rows.add(ModuleItem.fromEpisode(row));
                }
            }
            hasMore = false;
        } else {
            JSONArray array = value.optJSONArray("items");
            if (array != null) {
                for (int i = 0; i < array.length(); i++) {
                    JSONObject row = array.optJSONObject(i);
                    if (row == null) continue;
                    switch (type) {
                        case BANGUMI:
                        case MOVIE: rows.add(ModuleItem.fromSeason(row)); break;
                        case LIVE: rows.add(ModuleItem.fromLive(row)); break;
                        case MESSAGES: rows.add(ModuleItem.fromMessage(row)); break;
                        default: rows.add(ModuleItem.fromVideo(row)); break;
                    }
                }
            }
            hasMore = value.optBoolean("hasMore", !rows.isEmpty());
            if (type == Type.HISTORY) {
                String next = value.optString("next", "");
                cursor = next;
                hasMore = !next.isEmpty();
            }
        }
        adapter.append(rows);
        page += 1;
        status.setVisibility(rows.isEmpty() && adapter.itemCount() == 0 ? VISIBLE : GONE);
        if (rows.isEmpty() && adapter.itemCount() == 0) {
            status.setText(type == Type.MESSAGES ? "暂无消息" : "暂无内容");
        }
    }

    void destroy() {
        pool.shutdownNow();
        main.removeCallbacksAndMessages(null);
    }

    void reload() {
        adapter.setItems(new ArrayList<>());
        page = 1;
        cursor = "";
        hasMore = true;
        load(true);
    }
}
