package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager2.widget.ViewPager2;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class FeedView extends FrameLayout {
    interface Host {
        void onOpenPlayer(VideoItem item, View source);
        void onOpenProfile(long mid);
        void onToolbarHidden(boolean hidden);
        void onSearchVisibility(boolean visible);
    }

    private final Context context;
    private final BiliApi api;
    private final BiliExtras extras;
    private final CookieStore cookies;
    private final Host host;
    private final ViewPager2 pager;
    private final PageAdapter adapter;
    private final ExecutorService pool = Executors.newFixedThreadPool(2);
    private final Handler main = new Handler(Looper.getMainLooper());
    private VideoEngine previewEngine;
    private String previewKey = "";
    private int previewToken = 0;
    private int focused = 0;
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

    FeedView(Context context, BiliApi api, BiliExtras extras, CookieStore cookies, Host host) {
        super(context);
        this.context = context;
        this.api = api;
        this.extras = extras;
        this.cookies = cookies;
        this.host = host;
        setBackgroundColor(NativeTheme.background(context));
        setClipChildren(true);

        pager = new ViewPager2(context);
        pager.setOrientation(ViewPager2.ORIENTATION_VERTICAL);
        pager.setOffscreenPageLimit(1);
        pager.setBackgroundColor(Color.BLACK);
        adapter = new PageAdapter();
        pager.setAdapter(adapter);
        addView(pager, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        pager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override public void onPageSelected(int position) {
                if (position > focused) {
                    host.onToolbarHidden(true);
                } else if (position < focused || position == 0) {
                    host.onToolbarHidden(false);
                }
                focused = position;
                previewViewHidden(true);
                schedulePreview();
                if (position >= adapter.getItemCount() - 3) load(false);
            }

            @Override public void onPageScrollStateChanged(int state) {
                if (state == ViewPager2.SCROLL_STATE_DRAGGING) {
                    previewViewHidden(true);
                    if (previewEngine != null) previewEngine.pause();
                } else if (state == ViewPager2.SCROLL_STATE_IDLE) {
                    schedulePreview();
                }
            }
        });

        post(this::loadInitial);
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
                } else {
                    adapter.append(rows);
                }
                if (reset && rows.isEmpty()) {
                    // Keep the feed empty but usable; a retry happens on the
                    // next pull or tab visit.
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
        main.postDelayed(previewRunnable, 140);
    }

    private final Runnable previewRunnable = this::startPreview;

    private void startPreview() {
        if (searchOpen || adapter.getItemCount() == 0) return;
        VideoPageView page = pageAt(focused);
        if (page == null || page.item() == null) return;
        VideoItem item = page.item();
        String key = item.bvid + ":" + item.cid;
        if (previewEngine != null && key.equals(previewKey) && previewEngine.isPlaying()) {
            previewViewHidden(false);
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
                    if (previewEngine != null) previewEngine.view().setAlpha(1f);
                }
                @Override public void onError(String message) {
                    if (previewEngine != null) previewEngine.view().setAlpha(0f);
                }
            });
        }
        previewViewHidden(false);
        if (previewEngine.view().getParent() instanceof ViewGroup) {
            ((ViewGroup) previewEngine.view().getParent()).removeView(previewEngine.view());
        }
        page.mediaHost.addView(previewEngine.view(), new LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        previewEngine.view().setAlpha(0f);
        previewEngine.view().setVisibility(View.VISIBLE);
        final VideoPageView target = page;
        pool.execute(() -> {
            JSONObject result = api.playLow(item.bvid, item.cid);
            final JSONObject value = result;
            main.post(() -> {
                if (token != previewToken || value == null || !value.optBoolean("ok", false)) return;
                if (pageAt(focused) != target) return;
                String url = value.optString("url", value.optString("remote", ""));
                String backup = value.optString("backup", value.optString("backupRemote", ""));
                if (url.isEmpty()) return;
                previewEngine.view().setVisibility(View.VISIBLE);
                previewEngine.load(url, backup, true, true, true, 0);
            });
        });
    }

    private void previewViewHidden(boolean hidden) {
        if (previewEngine == null) return;
        previewEngine.view().setVisibility(hidden ? View.INVISIBLE : View.VISIBLE);
    }

    private VideoPageView pageAt(int index) {
        if (index < 0 || index >= adapter.getItemCount()) return null;
        RecyclerView recycler = (RecyclerView) pager.getChildAt(0);
        if (recycler == null) return null;
        View child = recycler.getLayoutManager() == null ? null
            : recycler.getLayoutManager().findViewByPosition(index);
        return child instanceof VideoPageView ? (VideoPageView) child : null;
    }

    @Override public boolean onInterceptTouchEvent(MotionEvent event) {
        if (searchOpen) return false;
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                gestureDownX = event.getX();
                gestureDownY = event.getY();
                gestureStartAt = System.currentTimeMillis();
                searchDragging = false;
                return false;
            case MotionEvent.ACTION_MOVE:
                float dx = event.getX() - gestureDownX;
                float dy = event.getY() - gestureDownY;
                if (!searchDragging && -dx > NativeTheme.dp(context, 28)
                    && Math.abs(dx) > Math.abs(dy) * 1.3f) {
                    beginSearchDrag();
                    searchDragging = true;
                    return true;
                }
                return false;
            default:
                return false;
        }
    }

    @Override public boolean onTouchEvent(MotionEvent event) {
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
        pager.setTranslationX(0);
        pager.setUserInputEnabled(false);
        previewViewHidden(true);
        if (previewEngine != null) previewEngine.pause();
    }

    private void updateSearchDrag(float translation) {
        if (searchView == null) return;
        searchView.setTranslationX(Math.max(0, getWidth() - translation));
        pager.setTranslationX(-translation * 0.18f);
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

    private void openSearch() {
        searchOpen = true;
        searchView.setVisibility(View.VISIBLE);
        searchView.setTranslationX(0);
        pager.setUserInputEnabled(false);
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
        pager.setUserInputEnabled(true);
        if (animate) {
            searchView.animate().translationX(getWidth()).setDuration(220).withEndAction(() -> {
                searchView.setVisibility(View.GONE);
                pager.setTranslationX(0);
                schedulePreview();
            }).start();
        } else {
            searchView.setVisibility(View.GONE);
            searchView.setTranslationX(getWidth());
            pager.setTranslationX(0);
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

    private final class PageAdapter extends RecyclerView.Adapter<PageHolder> {
        private final List<VideoItem> items = new ArrayList<>();

        void setItems(List<VideoItem> values) {
            items.clear();
            if (values != null) items.addAll(values);
            notifyDataSetChanged();
            if (!items.isEmpty()) pager.setCurrentItem(0, false);
        }

        void append(List<VideoItem> values) {
            if (values == null || values.isEmpty()) return;
            int start = items.size();
            items.addAll(values);
            notifyItemRangeInserted(start, values.size());
        }

        @NonNull
        @Override
        public PageHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            VideoPageView page = new VideoPageView(context);
            page.setLayoutParams(new RecyclerView.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
            return new PageHolder(page);
        }

        @Override
        public void onBindViewHolder(@NonNull PageHolder holder, int position) {
            VideoItem item = items.get(position);
            holder.page.setItem(item,
                () -> host.onOpenProfile(item.mid),
                () -> host.onOpenPlayer(item, holder.page.mediaHost));
        }

        @Override
        public int getItemCount() {
            return items.size();
        }
    }

    static final class PageHolder extends RecyclerView.ViewHolder {
        final VideoPageView page;
        PageHolder(VideoPageView page) {
            super(page);
            this.page = page;
        }
    }
}
