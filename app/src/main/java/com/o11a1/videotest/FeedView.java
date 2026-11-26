package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Home feed matching the original web layout: a vertical list of 16:9 cards
 * with a glass information row below each cover, followed by pagination.
 */
final class FeedView extends FrameLayout {
    interface Host {
        void onOpenPlayer(VideoItem item, View source);
        void onOpenProfile(long mid);
        void onToolbarHidden(boolean hidden);
        void onSearchVisibility(boolean visible);
        void onOpenSidebar();
    }

    private final Context context;
    private final BiliApi api;
    private final BiliExtras extras;
    private final CookieStore cookies;
    private final Host host;
    private final RecyclerView list;
    private final LinearLayoutManager layoutManager;
    private final CardAdapter adapter;
    private final ExecutorService pool = Executors.newFixedThreadPool(2);
    private final Handler main = new Handler(Looper.getMainLooper());
    private VideoEngine previewEngine;
    private String previewKey = "";
    private int previewToken = 0;
    private int nextPage = 1;
    private int fresh = 1;
    private boolean loading = false;
    private boolean hasMore = true;
    private SearchView searchView;
    private boolean searchOpen = false;
    private float gestureDownX;
    private float gestureDownY;
    private long gestureStartAt;
    private boolean searchDragging = false;
    private boolean sidebarGesture = false;
    private boolean toolbarHidden = false;

    FeedView(Context context, BiliApi api, BiliExtras extras, CookieStore cookies, Host host) {
        super(context);
        this.context = context;
        this.api = api;
        this.extras = extras;
        this.cookies = cookies;
        this.host = host;
        setBackgroundColor(NativeTheme.background(context));
        setClipChildren(true);

        list = new RecyclerView(context);
        layoutManager = new LinearLayoutManager(context);
        list.setLayoutManager(layoutManager);
        list.setBackgroundColor(NativeTheme.background(context));
        list.setClipToPadding(false);
        list.setPadding(0, statusBar(), 0, NativeTheme.dp(context, 104) + bottomInset());
        adapter = new CardAdapter();
        list.setAdapter(adapter);
        addView(list, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        View fade = new View(context);
        android.graphics.drawable.GradientDrawable fadeDrawable =
            new android.graphics.drawable.GradientDrawable(
                android.graphics.drawable.GradientDrawable.Orientation.TOP_BOTTOM,
                new int[]{NativeTheme.background(context), 0x00FFFFFF & NativeTheme.background(context)});
        fade.setBackground(fadeDrawable);
        fade.setClickable(false);
        addView(fade, new LayoutParams(LayoutParams.MATCH_PARENT,
            statusBar() + NativeTheme.dp(context, 18)));

        list.addOnScrollListener(new RecyclerView.OnScrollListener() {
            private int lastDy = 0;

            @Override public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                if (dy > 4 && !toolbarHidden && layoutManager.findFirstVisibleItemPosition() > 0) {
                    toolbarHidden = true;
                    host.onToolbarHidden(true);
                } else if (dy < -4 && toolbarHidden) {
                    toolbarHidden = false;
                    host.onToolbarHidden(false);
                }
                if (layoutManager.findLastVisibleItemPosition()
                    >= adapter.getItemCount() - 3) {
                    load(false);
                }
            }

            @Override public void onScrollStateChanged(@NonNull RecyclerView recyclerView, int state) {
                if (state == RecyclerView.SCROLL_STATE_DRAGGING) {
                    previewHidden(true);
                    if (previewEngine != null) previewEngine.pause();
                } else if (state == RecyclerView.SCROLL_STATE_IDLE) {
                    schedulePreview();
                }
            }
        });

        post(this::loadInitial);
    }

    private int bottomInset() {
        int id = getResources().getIdentifier("navigation_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }

    private int statusBar() {
        int id = getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }

    private void loadInitial() {
        load(true);
    }

    private void load(boolean reset) {
        if (loading || (!hasMore && !reset)) return;
        if (reset) {
            nextPage = 1;
            fresh = 1;
            hasMore = true;
        }
        loading = true;
        final int page = nextPage;
        final int freshIndex = fresh;
        pool.execute(() -> {
            JSONObject result = api.recommend(page, 20, freshIndex);
            if (result == null || !result.optBoolean("ok", false)) {
                result = api.popular(page, 20);
            }
            final JSONObject value = result;
            main.post(() -> {
                loading = false;
                if (value == null || !value.optBoolean("ok", false)) return;
                List<VideoItem> rows = parseItems(value);
                hasMore = !rows.isEmpty();
                nextPage += 1;
                fresh += 1;
                if (reset) {
                    adapter.setItems(rows);
                    list.scrollToPosition(0);
                } else {
                    adapter.append(rows);
                }
                schedulePreview();
            });
        });
    }

    private List<VideoItem> parseItems(JSONObject json) {
        List<VideoItem> rows = new ArrayList<>();
        JSONArray array = json.optJSONArray("items");
        if (array == null) return rows;
        for (int i = 0; i < array.length(); i++) {
            JSONObject row = array.optJSONObject(i);
            if (row != null) rows.add(VideoItem.from(row));
        }
        return rows;
    }

    private void schedulePreview() {
        main.removeCallbacks(previewRunnable);
        main.postDelayed(previewRunnable, 180);
    }

    private final Runnable previewRunnable = this::startPreview;

    private void startPreview() {
        if (searchOpen || adapter.getItemCount() == 0) return;
        int first = layoutManager.findFirstVisibleItemPosition();
        int last = layoutManager.findLastVisibleItemPosition();
        if (first < 0) return;
        int viewportCenter = getHeight() / 2 + list.getPaddingTop() - list.getPaddingBottom();
        int best = -1;
        int bestDistance = Integer.MAX_VALUE;
        for (int index = first; index <= last; index++) {
            View child = layoutManager.findViewByPosition(index);
            if (child == null) continue;
            int center = child.getTop() + child.getHeight() / 2;
            int distance = Math.abs(center - viewportCenter);
            if (distance < bestDistance) {
                bestDistance = distance;
                best = index;
            }
        }
        if (best < 0) return;
        final int previewIndex = best;
        View child = layoutManager.findViewByPosition(previewIndex);
        if (!(child instanceof HomeCardView)) return;
        HomeCardView card = (HomeCardView) child;
        VideoItem item = card.item();
        if (item == null || item.bvid.isEmpty()) return;
        String key = item.bvid + ":" + item.cid;
        if (previewEngine != null && key.equals(previewKey) && previewEngine.isPlaying()) {
            previewHidden(false);
            previewEngine.play();
            return;
        }
        previewKey = key;
        previewToken += 1;
        final int token = previewToken;
        if (previewEngine == null) {
            previewEngine = new VideoEngine(context, cookies, true);
            previewEngine.setListener(new VideoEngine.Listener() {
                @Override public void onProgress(long positionMs, long durationMs, boolean playing) {}
                @Override public void onReady() {}
                @Override public void onFirstFrame() {
                    if (previewEngine != null) {
                        previewEngine.view().setAlpha(1f);
                        previewEngine.view().setVisibility(View.VISIBLE);
                    }
                }
                @Override public void onError(String message) {
                    if (previewEngine != null) {
                        previewEngine.view().setAlpha(0f);
                        previewEngine.view().setVisibility(View.INVISIBLE);
                    }
                }
            });
        }
        previewHidden(true);
        if (previewEngine.view().getParent() instanceof ViewGroup) {
            ((ViewGroup) previewEngine.view().getParent()).removeView(previewEngine.view());
        }
        card.mediaHost().addView(previewEngine.view(), new LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        previewEngine.view().setAlpha(0f);
        previewEngine.view().setVisibility(View.INVISIBLE);
        pool.execute(() -> {
            JSONObject result = api.playLow(item.bvid, item.cid);
            final JSONObject value = result;
            main.post(() -> {
                if (token != previewToken || value == null || !value.optBoolean("ok", false)) return;
                View current = layoutManager.findViewByPosition(previewIndex);
                if (current != card) return;
                String url = value.optString("url", value.optString("remote", ""));
                String backup = value.optString("backup", value.optString("backupRemote", ""));
                if (url.isEmpty()) return;
                previewEngine.load(url, backup, true, true, true, 0);
            });
        });
    }

    private void previewHidden(boolean hidden) {
        if (previewEngine == null) return;
        previewEngine.view().setVisibility(hidden ? View.INVISIBLE : View.VISIBLE);
    }

    @Override public boolean onInterceptTouchEvent(MotionEvent event) {
        if (searchOpen) return false;
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                gestureDownX = event.getX();
                gestureDownY = event.getY();
                gestureStartAt = System.currentTimeMillis();
                searchDragging = false;
                sidebarGesture = false;
                return false;
            case MotionEvent.ACTION_MOVE:
                float dx = event.getX() - gestureDownX;
                float dy = event.getY() - gestureDownY;
                if (!searchDragging && !sidebarGesture
                    && Math.abs(dx) > NativeTheme.dp(context, 28)
                    && Math.abs(dx) > Math.abs(dy) * 1.3f) {
                    if (dx < 0) {
                        beginSearchDrag();
                        searchDragging = true;
                    } else {
                        sidebarGesture = true;
                    }
                    return true;
                }
                return false;
            default:
                return false;
        }
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
        if (sidebarGesture) {
            if (event.getActionMasked() == MotionEvent.ACTION_UP
                || event.getActionMasked() == MotionEvent.ACTION_CANCEL) {
                float dx = event.getX() - gestureDownX;
                if (dx > getWidth() * 0.12f) host.onOpenSidebar();
                sidebarGesture = false;
            }
            return true;
        }
        if (!searchDragging) return super.onTouchEvent(event);
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_MOVE:
                updateSearchDrag(Math.max(0, gestureDownX - event.getX()));
                return true;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                float translation = Math.max(0, gestureDownX - event.getX());
                long elapsed = Math.max(1, System.currentTimeMillis() - gestureStartAt);
                float velocity = translation / (elapsed / 1000f);
                searchDragging = false;
                if (translation > getWidth() * 0.26f || velocity > 350f) {
                    openSearch();
                } else {
                    closeSearch(true);
                }
                return true;
            default:
                return true;
        }
    }

    private void beginSearchDrag() {
        ensureSearch();
        searchOpen = false;
        searchView.setVisibility(View.VISIBLE);
        searchView.setTranslationX(getWidth());
        list.setTranslationX(0);
        previewHidden(true);
        if (previewEngine != null) previewEngine.pause();
    }

    private void updateSearchDrag(float translation) {
        if (searchView == null) return;
        searchView.setTranslationX(Math.max(0, getWidth() - translation));
        list.setTranslationX(-translation * 0.18f);
    }

    private void ensureSearch() {
        if (searchView != null) return;
        searchView = new SearchView(context, api, item -> {
            if (searchOpen) closeSearch(false);
            host.onOpenPlayer(item, null);
        }, this::closeSearchFromButton);
        addView(searchView, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        searchView.setVisibility(View.GONE);
    }

    void openSearchFromHost() {
        ensureSearch();
        openSearch();
    }

    private void openSearch() {
        searchOpen = true;
        searchView.setVisibility(View.VISIBLE);
        searchView.setTranslationX(0);
        list.setTranslationX(0);
        host.onSearchVisibility(true);
        searchView.focus();
    }

    private void closeSearchFromButton() {
        closeSearch(true);
    }

    private void closeSearch(boolean animate) {
        if (searchView == null) return;
        searchOpen = false;
        host.onSearchVisibility(false);
        if (animate) {
            searchView.animate().translationX(getWidth()).setDuration(220).withEndAction(() -> {
                searchView.setVisibility(View.GONE);
                list.setTranslationX(0);
                schedulePreview();
            }).start();
        } else {
            searchView.setVisibility(View.GONE);
            searchView.setTranslationX(getWidth());
            list.setTranslationX(0);
            schedulePreview();
        }
    }

    void onResumeFeed() {
        schedulePreview();
    }

    void onPauseFeed() {
        if (previewEngine != null) previewEngine.pause();
    }

    void destroy() {
        previewToken += 1;
        main.removeCallbacks(previewRunnable);
        pool.shutdownNow();
        if (previewEngine != null) {
            previewEngine.release();
            previewEngine = null;
        }
        if (searchView != null) {
            searchView.destroy();
        }
    }

    boolean isSearchOpen() {
        return searchOpen;
    }

    void closeSearchFromHost() {
        closeSearch(true);
    }

    private final class CardAdapter extends RecyclerView.Adapter<CardHolder> {
        private final List<VideoItem> items = new ArrayList<>();

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
        public CardHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            HomeCardView card = new HomeCardView(context);
            RecyclerView.LayoutParams params = new RecyclerView.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);
            params.bottomMargin = NativeTheme.dp(context, 14);
            card.setLayoutParams(params);
            return new CardHolder(card);
        }

        @Override
        public void onBindViewHolder(@NonNull CardHolder holder, int position) {
            VideoItem item = items.get(position);
            holder.card.setItem(item,
                () -> host.onOpenProfile(item.mid),
                () -> host.onOpenPlayer(item, holder.card.mediaHost()));
        }

        @Override
        public int getItemCount() {
            return items.size();
        }
    }

    static final class CardHolder extends RecyclerView.ViewHolder {
        final HomeCardView card;

        CardHolder(HomeCardView card) {
            super(card);
            this.card = card;
        }
    }
}
