package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class DanmakuView extends FrameLayout {
    private static final int MAX_ACTIVE = 36;

    private static final class Item {
        double time;
        String text;
        int color;
        boolean spawned;
    }

    private static final class Active {
        TextView view;
        long startedAt;
        float laneY;
        float speed;
    }

    private final Context context;
    private final BiliApi api;
    private final BiliExtras extras;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final List<Item> items = new ArrayList<>();
    private final List<Active> active = new ArrayList<>();
    private long cid = 0;
    private long positionMs = 0;
    private long lastPositionMs = 0;
    private int spawnIndex = 0;
    private int lane = 0;
    private boolean enabled = true;
    private boolean loaded = false;
    private final Runnable ticker = this::tick;

    DanmakuView(Context context, BiliApi api, BiliExtras extras) {
        super(context);
        this.context = context;
        this.api = api;
        this.extras = extras;
        setClipChildren(true);
        setClickable(false);
    }

    @Override protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        if (loaded && enabled) postOnAnimation(ticker);
    }

    @Override protected void onDetachedFromWindow() {
        removeCallbacks(ticker);
        super.onDetachedFromWindow();
    }

    void load(long cid) {
        this.cid = cid;
        if (cid <= 0) return;
        pool.execute(() -> {
            JSONObject result = api.danmaku(cid);
            post(() -> {
                if (result == null || !result.optBoolean("ok", false)) return;
                JSONArray array = result.optJSONArray("items");
                if (array == null) return;
                items.clear();
                for (int i = 0; i < array.length(); i++) {
                    JSONObject row = array.optJSONObject(i);
                    if (row == null) continue;
                    Item item = new Item();
                    item.time = row.optDouble("t", 0);
                    item.text = row.optString("text", "");
                    item.color = row.optInt("color", 0xFFFFFF);
                    if (item.text.isEmpty()) continue;
                    items.add(item);
                }
                items.sort((a, b) -> Double.compare(a.time, b.time));
                loaded = true;
                reset();
                postOnAnimation(ticker);
            });
        });
    }

    void setPosition(long ms) {
        if (ms < 0) ms = 0;
        if (ms + 1500 < lastPositionMs) reset();
        positionMs = ms;
        lastPositionMs = ms;
    }

    void setDanmakuEnabled(boolean value) {
        enabled = value;
        setVisibility(value ? View.VISIBLE : View.GONE);
        if (!value) clearActive();
        else if (loaded && isAttachedToWindow()) postOnAnimation(ticker);
    }

    boolean isDanmakuEnabled() {
        return enabled;
    }

    private void reset() {
        spawnIndex = 0;
        for (Item item : items) item.spawned = false;
        clearActive();
    }

    private void clearActive() {
        for (Active item : active) removeView(item.view);
        active.clear();
    }

    private void tick() {
        if (!enabled || !isAttachedToWindow()) return;
        long now = System.currentTimeMillis();
        while (spawnIndex < items.size()) {
            Item item = items.get(spawnIndex);
            if (item.time * 1000.0 > positionMs + 40) break;
            if (item.time * 1000.0 < positionMs - 900) {
                spawnIndex += 1;
                continue;
            }
            spawn(item, now);
            spawnIndex += 1;
        }
        float width = getWidth();
        for (int i = active.size() - 1; i >= 0; i--) {
            Active item = active.get(i);
            float elapsed = (now - item.startedAt) / 1000f;
            float x = width - item.speed * elapsed;
            item.view.setTranslationX(x);
            if (x < -item.view.getWidth() - 20) {
                removeView(item.view);
                active.remove(i);
            }
        }
        postOnAnimation(ticker);
    }

    private void spawn(Item item, long now) {
        if (active.size() >= MAX_ACTIVE) {
            Active oldest = active.remove(0);
            removeView(oldest.view);
        }
        TextView view = new TextView(context);
        view.setText(item.text);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        view.setTextColor(item.color == 0 ? Color.WHITE : (0xFF000000 | item.color));
        view.setShadowLayer(2, 1, 1, 0xCC000000);
        view.setSingleLine(true);
        view.setEllipsize(TextUtils.TruncateAt.END);
        view.setGravity(Gravity.CENTER_VERTICAL);
        int maxWidth = Math.max(NativeTheme.dp(context, 120), getWidth() - NativeTheme.dp(context, 32));
        view.setMaxWidth(maxWidth);
        addView(view, new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));
        float laneHeight = NativeTheme.dp(context, 26);
        int lanes = Math.max(1, (int) ((getHeight() * 0.55f) / laneHeight));
        float y = NativeTheme.dp(context, 54) + (lane % lanes) * laneHeight;
        lane += 1;
        view.setY(y);
        view.measure(MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
            MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED));
        float speed = Math.max(NativeTheme.dp(context, 80), getWidth() * 0.18f);
        view.setTranslationX(getWidth());
        Active entry = new Active();
        entry.view = view;
        entry.startedAt = now;
        entry.laneY = y;
        entry.speed = speed;
        active.add(entry);
    }

    void send(String text, long progressMs) {
        if (cid <= 0 || text == null || text.trim().isEmpty()) return;
        String value = text.trim();
        Item item = new Item();
        item.time = progressMs / 1000.0;
        item.text = value;
        item.color = 0xFFFFFF;
        item.spawned = true;
        items.add(item);
        spawn(item, System.currentTimeMillis());
        pool.execute(() -> {
            // Sending is best-effort; failure is reported by the caller if needed.
            try {
                extras.sendDanmaku(cid, value, progressMs);
            } catch (Throwable ignored) {}
        });
    }

    void destroy() {
        pool.shutdownNow();
        removeCallbacks(ticker);
        clearActive();
    }
}
