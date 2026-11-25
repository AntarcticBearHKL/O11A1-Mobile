package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.TextureView;
import android.view.View;
import android.widget.FrameLayout;

import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.PlaybackParameters;
import androidx.media3.common.Player;
import androidx.media3.common.VideoSize;
import androidx.media3.datasource.okhttp.OkHttpDataSource;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.hls.HlsMediaSource;
import androidx.media3.exoplayer.source.MediaSource;
import androidx.media3.exoplayer.source.MergingMediaSource;
import androidx.media3.exoplayer.source.ProgressiveMediaSource;
import androidx.media3.ui.AspectRatioFrameLayout;
import androidx.media3.ui.PlayerView;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

import okhttp3.ConnectionPool;
import okhttp3.OkHttpClient;
import okhttp3.Protocol;

/**
 * Native ExoPlayer layer. Media bytes go straight to Bilibili's CDN with the
 * required UA/Referer/Cookie headers; there is no local HTTP proxy in the path.
 */
final class NativePlayerHost {
    private static final String TAG = "O11A1Player";
    private static final String UA =
        "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) "
            + "Chrome/120.0 Mobile Safari/537.36";

    interface Emitter {
        void emit(String javascript);
    }

    private final Context context;
    private final CookieStore cookies;
    private final Emitter emitter;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final FrameLayout backgroundLayer;
    private final FrameLayout overlayLayer;
    private final OkHttpClient http;
    private final Map<String, Slot> slots = new ConcurrentHashMap<>();
    private final Runnable ticker = this::tick;
    private volatile boolean pipMode;

    static final class PipInfo {
        final int width;
        final int height;
        final Rect rect;
        final boolean playing;

        PipInfo(int width, int height, Rect rect, boolean playing) {
            this.width = width;
            this.height = height;
            this.rect = rect;
            this.playing = playing;
        }
    }

    NativePlayerHost(Context context, CookieStore cookies, Emitter emitter) {
        this.context = context.getApplicationContext();
        this.cookies = cookies;
        this.emitter = emitter;
        backgroundLayer = new FrameLayout(context);
        backgroundLayer.setBackgroundColor(Color.TRANSPARENT);
        backgroundLayer.setClipChildren(false);
        overlayLayer = new FrameLayout(context);
        overlayLayer.setBackgroundColor(Color.TRANSPARENT);
        overlayLayer.setClipChildren(false);
        overlayLayer.setClickable(false);
        overlayLayer.setFocusable(false);
        http = new OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(25, TimeUnit.SECONDS)
            .writeTimeout(20, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .connectionPool(new ConnectionPool(24, 5, TimeUnit.MINUTES))
            .protocols(java.util.Arrays.asList(Protocol.HTTP_2, Protocol.HTTP_1_1))
            .build();
    }

    View backgroundView() {
        return backgroundLayer;
    }

    View overlayView() {
        return overlayLayer;
    }

    boolean isMainPlaying() {
        Slot slot = slots.get("main");
        if (slot == null || slot.view == null || !slot.view.isShown()) return false;
        if (slot.player == null) return false;
        return slot.player.isPlaying() || slot.player.getPlayWhenReady();
    }

    PipInfo pipInfo(String slotId) {
        Slot slot = slots.get(slotId);
        if (slot == null || slot.view == null) {
            Log.i(TAG, "pipInfo " + slotId + " slot missing");
            return null;
        }
        if (!slot.view.isShown() || slot.view.getVisibility() != View.VISIBLE || slot.player == null) {
            Log.i(TAG, "pipInfo " + slotId + " hidden shown=" + slot.view.isShown()
                + " vis=" + slot.view.getVisibility()
                + " player=" + (slot.player != null)
                + " size=" + slot.view.getWidth() + "x" + slot.view.getHeight()
                + " parent=" + (slot.view.getParent() != null));
            return null;
        }
        if (!slot.player.isPlaying() && !slot.player.getPlayWhenReady()) {
            Log.i(TAG, "pipInfo " + slotId + " player not playing");
            return null;
        }
        Rect viewRect = new Rect();
        if (!slot.view.getGlobalVisibleRect(viewRect)) {
            Log.i(TAG, "pipInfo " + slotId + " no visible rect");
            return null;
        }
        if (viewRect.width() < 2 || viewRect.height() < 2) {
            Log.i(TAG, "pipInfo " + slotId + " tiny rect " + viewRect);
            return null;
        }
        int width = slot.videoWidth > 0 ? slot.videoWidth : viewRect.width();
        int height = slot.videoHeight > 0 ? slot.videoHeight : viewRect.height();
        Rect displayRect = fitVideoRect(viewRect, slot.videoWidth, slot.videoHeight);
        Log.i(TAG, "pipInfo " + slotId + " ok view=" + viewRect + " videoRect=" + displayRect
            + " video=" + slot.videoWidth + "x" + slot.videoHeight);
        return new PipInfo(width, height, displayRect, true);
    }

    private static Rect fitVideoRect(Rect viewRect, int videoWidth, int videoHeight) {
        Rect out = new Rect(viewRect);
        if (videoWidth <= 0 || videoHeight <= 0) return out;
        float ratio = (float) videoWidth / (float) videoHeight;
        int width = viewRect.width();
        int height = Math.round(width / ratio);
        if (height > viewRect.height()) {
            height = viewRect.height();
            width = Math.round(height * ratio);
        }
        int left = viewRect.left + (viewRect.width() - width) / 2;
        int top = viewRect.top + (viewRect.height() - height) / 2;
        out.set(left, top, left + width, top + height);
        return out;
    }

    void setPipMode(boolean on) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            applyPipMode(on);
        } else {
            main.post(() -> applyPipMode(on));
        }
    }

    void stopMain() {
        main.post(() -> {
            Slot slot = slots.get("main");
            if (slot == null) return;
            try {
                slot.player.setPlayWhenReady(false);
                slot.player.stop();
            } catch (Throwable ignored) {}
        });
    }

    private void applyPipMode(boolean on) {
        if (pipMode == on) return;
        pipMode = on;
        Slot mainSlot = slots.get("main");
        for (Slot slot : slots.values()) {
            if (slot != mainSlot) {
                slot.view.setVisibility(on ? View.GONE
                    : (slot.visible ? View.VISIBLE : View.GONE));
                continue;
            }
            if (on) {
                slot.pipSavedX = slot.view.getX();
                slot.pipSavedY = slot.view.getY();
                slot.pipSavedW = slot.view.getWidth();
                slot.pipSavedH = slot.view.getHeight();
                FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT);
                slot.view.setLayoutParams(lp);
                slot.view.setX(0f);
                slot.view.setY(0f);
                slot.view.setBackgroundColor(Color.BLACK);
                slot.view.setVisibility(View.VISIBLE);
                overlayLayer.bringChildToFront(slot.view);
            } else {
                FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                    Math.max(2, slot.pipSavedW), Math.max(2, slot.pipSavedH));
                slot.view.setLayoutParams(lp);
                slot.view.setX(slot.pipSavedX);
                slot.view.setY(slot.pipSavedY);
                if (slot.visible) slot.view.setVisibility(View.VISIBLE);
            }
        }
    }

    void releaseAll() {
        main.post(() -> {
            for (Slot slot : slots.values()) slot.release();
            slots.clear();
            main.removeCallbacks(ticker);
        });
    }

    void load(String slotId, JSONObject json) {
        if (slotId == null || slotId.isEmpty()) return;
        final JSONObject copy = json == null ? new JSONObject() : json;
        main.post(() -> {
            Slot slot = ensure(slotId);
            if (slot == null) return;
            applyLoad(slot, copy);
        });
    }

    void control(String slotId, String action, double value) {
        main.post(() -> {
            Slot slot = slots.get(slotId);
            if (slot == null || slot.player == null || action == null) return;
            switch (action) {
                case "play":
                    slot.player.setPlayWhenReady(true);
                    break;
                case "pause":
                    slot.player.setPlayWhenReady(false);
                    break;
                case "seek":
                    slot.player.seekTo(Math.max(0L, (long) value));
                    emit(slot, "seeking", null);
                    break;
                case "rate":
                    slot.rate = (float) Math.max(0.1, Math.min(4.0, value));
                    slot.player.setPlaybackParameters(new PlaybackParameters(slot.rate, 1f));
                    emit(slot, "ratechange", null);
                    break;
                case "mute":
                    slot.muted = value > 0.5;
                    slot.player.setVolume(slot.muted ? 0f : slot.volume);
                    emit(slot, "volumechange", null);
                    break;
                case "volume":
                    slot.volume = (float) Math.max(0.0, Math.min(1.0, value));
                    slot.muted = slot.volume <= 0.001;
                    slot.player.setVolume(slot.muted ? 0f : slot.volume);
                    emit(slot, "volumechange", null);
                    break;
                case "stop":
                    slot.player.stop();
                    slot.player.clearMediaItems();
                    emit(slot, "pause", null);
                    break;
                default:
                    break;
            }
        });
    }

    void rect(String slotId, float x, float y, float width, float height, boolean visible,
              float rotation) {
        main.post(() -> {
            Slot slot = slots.get(slotId);
            if (slot == null || slot.view == null) return;
            /* While PiP owns the screen the native slot is full-bleed; web rect
               updates from the hidden player must not shrink or hide it. */
            if (pipMode) return;
            if (!visible || width < 2f || height < 2f) {
                if (slot.visible) {
                    slot.visible = false;
                    slot.view.setVisibility(View.GONE);
                }
                return;
            }
            slot.view.setRotation(rotation);
            int w = Math.max(1, Math.round(width));
            int h = Math.max(1, Math.round(height));
            FrameLayout.LayoutParams lp = (FrameLayout.LayoutParams) slot.view.getLayoutParams();
            if (lp == null) lp = new FrameLayout.LayoutParams(w, h);
            boolean changed = lp.width != w || lp.height != h;
            if (changed) {
                lp.width = w;
                lp.height = h;
                slot.view.setLayoutParams(lp);
            }
            slot.view.setX(x);
            slot.view.setY(y);
            if (!slot.visible || slot.view.getVisibility() != View.VISIBLE) {
                slot.visible = true;
                slot.view.setVisibility(View.VISIBLE);
            }
        });
    }

    String snapshot(String slotId) {
        Slot slot = slots.get(slotId);
        JSONObject out = new JSONObject();
        try {
            out.put("ok", slot != null);
            if (slot != null) {
                out.put("position", slot.lastPosition);
                out.put("duration", slot.duration);
                out.put("buffered", slot.buffered);
                out.put("playing", slot.lastPlaying);
                out.put("videoWidth", slot.videoWidth);
                out.put("videoHeight", slot.videoHeight);
            }
        } catch (Throwable ignored) {}
        return out.toString();
    }

    void release(String slotId) {
        main.post(() -> {
            Slot slot = slots.remove(slotId);
            if (slot != null) slot.release();
        });
    }

    void layer(String slotId, boolean background) {
        main.post(() -> {
            Slot slot = slots.get(slotId);
            if (slot == null) return;
            FrameLayout parent = background ? backgroundLayer : overlayLayer;
            if (slot.view.getParent() == parent) return;
            try {
                int x = Math.round(slot.view.getX());
                int y = Math.round(slot.view.getY());
                FrameLayout.LayoutParams lp = (FrameLayout.LayoutParams) slot.view.getLayoutParams();
                if (slot.view.getParent() instanceof FrameLayout) {
                    ((FrameLayout) slot.view.getParent()).removeView(slot.view);
                }
                parent.addView(slot.view, lp);
                slot.view.setX(x);
                slot.view.setY(y);
                if (background) backgroundLayer.bringToFront();
            } catch (Throwable error) {
                Log.w(TAG, "layer move failed " + slotId, error);
            }
        });
    }

    private Slot ensure(String slotId) {
        Slot existing = slots.get(slotId);
        if (existing != null) return existing;
        try {
            Slot slot = new Slot(slotId);
            FrameLayout parent = "main".equals(slotId) ? backgroundLayer : overlayLayer;
            FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(1, 1);
            slot.view.setLayoutParams(lp);
            slot.view.setVisibility(View.GONE);
            parent.addView(slot.view);
            slots.put(slotId, slot);
            main.removeCallbacks(ticker);
            main.postDelayed(ticker, 250);
            return slot;
        } catch (Throwable error) {
            Log.e(TAG, "slot create failed " + slotId, error);
            return null;
        }
    }

    private void applyLoad(Slot slot, JSONObject json) {
        String video = json.optString("videoUrl", "");
        String audio = json.optString("audioUrl", "");
        String backup = json.optString("backupUrl", "");
        String backupAudio = json.optString("backupAudioUrl", "");
        String kind = json.optString("kind", "file");
        long seq = json.optLong("seq", System.currentTimeMillis());
        long startMs = Math.max(0L, json.optLong("startMs", 0L));
        boolean autoplay = json.optBoolean("autoplay", false);
        boolean loop = json.optBoolean("loop", false);
        boolean muted = json.optBoolean("muted", false);
        float rate = (float) json.optDouble("rate", 1.0);
        if (video.isEmpty()) {
            slot.player.stop();
            slot.player.clearMediaItems();
            emit(slot, "pause", null);
            return;
        }
        slot.seq = seq;
        slot.videoUrl = video;
        slot.audioUrl = audio;
        slot.backupVideoUrl = backup;
        slot.backupAudioUrl = backupAudio;
        slot.kind = kind;
        slot.startMs = startMs;
        slot.autoplay = autoplay;
        slot.loop = loop;
        slot.muted = muted;
        slot.rate = Math.max(0.1f, Math.min(4.0f, rate));
        slot.retried = false;
        slot.firstFrameSent = false;
        slot.view.setAlpha("main".equals(slot.id) ? 1f : 0f);
        slot.duration = 0;
        slot.buffered = 0;
        slot.videoWidth = 0;
        slot.videoHeight = 0;
        start(slot, video, audio, kind, startMs, autoplay);
        emit(slot, "loadstart", null);
    }

    private void start(Slot slot, String video, String audio, String kind,
                       long startMs, boolean autoplay) {
        ExoPlayer player = slot.player;
        player.stop();
        player.clearMediaItems();
        MediaSource source = buildSource(video, audio, kind);
        if (source == null) {
            emitError(slot, "无法创建播放源");
            return;
        }
        player.setMediaSource(source);
        player.setRepeatMode(slot.loop ? Player.REPEAT_MODE_ONE : Player.REPEAT_MODE_OFF);
        player.setVolume(slot.muted ? 0f : slot.volume);
        player.setPlaybackParameters(new PlaybackParameters(slot.rate, 1f));
        player.prepare();
        if (startMs > 0) player.seekTo(startMs);
        player.setPlayWhenReady(autoplay);
        main.removeCallbacks(ticker);
        main.postDelayed(ticker, 250);
    }

    private MediaSource buildSource(String video, String audio, String kind) {
        try {
            if ("hls".equals(kind) || video.contains(".m3u8")) {
                return new HlsMediaSource.Factory(factory(false))
                    .createMediaSource(MediaItem.fromUri(video));
            }
            MediaSource videoSource = new ProgressiveMediaSource.Factory(factory(false))
                .createMediaSource(MediaItem.fromUri(video));
            if (audio != null && !audio.isEmpty()) {
                MediaSource audioSource = new ProgressiveMediaSource.Factory(factory(false))
                    .createMediaSource(MediaItem.fromUri(audio));
                return new MergingMediaSource(videoSource, audioSource);
            }
            return videoSource;
        } catch (Throwable error) {
            Log.e(TAG, "source build failed", error);
            return null;
        }
    }

    private OkHttpDataSource.Factory factory(boolean preview) {
        Map<String, String> headers = new HashMap<>();
        headers.put("User-Agent", UA);
        headers.put("Referer", "https://www.bilibili.com/");
        headers.put("Origin", "https://www.bilibili.com");
        headers.put("Accept", "*/*");
        headers.put("Accept-Language", "zh-CN,zh;q=0.9");
        String cookie = cookies.header();
        if (cookie != null && !cookie.isEmpty()) headers.put("Cookie", cookie);
        return new OkHttpDataSource.Factory(http)
            .setUserAgent(UA)
            .setDefaultRequestProperties(headers);
    }

    private DefaultLoadControl loadControl(String slotId) {
        boolean preview = !"main".equals(slotId);
        return new DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                preview ? 4000 : 30000,
                preview ? 30000 : 180000,
                preview ? 700 : 1500,
                preview ? 1200 : 3000)
            .build();
    }

    private void tick() {
        boolean any = false;
        for (Slot slot : slots.values()) {
            if (slot.player == null) continue;
            any = true;
            try {
                long position = slot.player.getCurrentPosition();
                long duration = slot.player.getDuration();
                if (duration == C.TIME_UNSET) duration = 0;
                long buffered = slot.player.getBufferedPosition();
                slot.duration = duration;
                slot.buffered = buffered;
                slot.lastPosition = position;
                slot.lastPlaying = slot.player.isPlaying();
                JSONObject payload = new JSONObject();
                payload.put("seq", slot.seq);
                payload.put("position", position);
                payload.put("duration", duration);
                payload.put("buffered", buffered);
                payload.put("playing", slot.player.isPlaying());
                payload.put("videoWidth", slot.videoWidth);
                payload.put("videoHeight", slot.videoHeight);
                emit(slot, "timeupdate", payload);
            } catch (Throwable ignored) {}
        }
        main.removeCallbacks(ticker);
        if (any) main.postDelayed(ticker, 200);
    }

    private void emitError(Slot slot, String message) {
        JSONObject payload = new JSONObject();
        try {
            payload.put("seq", slot.seq);
            payload.put("error", message == null ? "" : message);
        } catch (Throwable ignored) {}
        emit(slot, "error", payload);
    }

    private void emit(Slot slot, String type, JSONObject data) {        JSONObject payload = data == null ? new JSONObject() : data;
        try {
            payload.put("seq", slot.seq);
        } catch (Throwable ignored) {}
        String js = "window.O11A1NativeMedia&&window.O11A1NativeMedia.onEvent("
            + JSONObject.quote(slot.id) + ","
            + JSONObject.quote(type) + ","
            + JSONObject.quote(payload.toString()) + ");";
        emitter.emit(js);
    }

    private static FrameLayout.LayoutParams match() {
        return new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT);
    }

    private final class Slot implements Player.Listener {
        final String id;
        final FrameLayout view;
        final TextureView texture;
        final ExoPlayer player;
        long seq;
        String videoUrl = "";
        String audioUrl = "";
        String backupVideoUrl = "";
        String backupAudioUrl = "";
        String kind = "file";
        long startMs;
        boolean autoplay;
        boolean loop;
        boolean muted;
        boolean visible;
        boolean retried;
        boolean firstFrameSent;
        float volume = 1f;
        float rate = 1f;
        long duration;
        long buffered;
        long lastPosition;
        boolean lastPlaying;
        int videoWidth;
        int videoHeight;
        float pipSavedX;
        float pipSavedY;
        int pipSavedW;
        int pipSavedH;

        Slot(String id) {
            this.id = id;
            view = new FrameLayout(context);
            view.setBackgroundColor(Color.BLACK);
            view.setClickable(false);
            view.setFocusable(false);
            view.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
            view.addOnLayoutChangeListener((v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom) ->
                updateTextureLayout(this));
            texture = new TextureView(context);
            texture.setOpaque(false);
            texture.setClickable(false);
            texture.setFocusable(false);
            view.addView(texture, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));
            player = new ExoPlayer.Builder(context)
                .setLoadControl(loadControl(id))
                .build();
            player.addListener(this);
            player.setVideoTextureView(texture);
        }

        void release() {
            try {
                player.removeListener(this);
                player.release();
            } catch (Throwable ignored) {}
            try {
                player.clearVideoTextureView(texture);
                if (view.getParent() instanceof FrameLayout) {
                    ((FrameLayout) view.getParent()).removeView(view);
                }
            } catch (Throwable ignored) {}
        }

        @Override
        public void onRenderedFirstFrame() {
            if (firstFrameSent) return;
            firstFrameSent = true;
            view.setAlpha(1f);
            JSONObject payload = new JSONObject();
            try {
                payload.put("videoWidth", videoWidth);
                payload.put("videoHeight", videoHeight);
                payload.put("duration", duration);
            } catch (Throwable ignored) {}
            emit(this, "firstframe", payload);
            emit(this, "canplay", payload);
        }

        @Override
        public void onPlaybackStateChanged(int state) {
            if (state == Player.STATE_READY) {
                long value = player.getDuration();
                if (value != C.TIME_UNSET) duration = value;
                JSONObject payload = new JSONObject();
                try {
                    payload.put("duration", duration);
                    payload.put("videoWidth", videoWidth);
                    payload.put("videoHeight", videoHeight);
                } catch (Throwable ignored) {}
                emit(this, "loadedmetadata", payload);
                emit(this, "canplay", payload);
            } else if (state == Player.STATE_BUFFERING) {
                emit(this, "waiting", null);
            } else if (state == Player.STATE_ENDED) {
                emit(this, "ended", null);
            }
        }

        @Override
        public void onIsPlayingChanged(boolean isPlaying) {
            emit(this, isPlaying ? "playing" : "pause", null);
        }

        @Override
        public void onPlayerError(PlaybackException error) {
            Log.w(TAG, "player error " + id + " " + error.getErrorCodeName(), error);
            if (!retried && backupVideoUrl != null && !backupVideoUrl.isEmpty()) {
                retried = true;
                start(this, backupVideoUrl, backupAudioUrl, kind, startMs, autoplay);
                return;
            }
            emitError(this, error.getErrorCodeName() + " " + error.getMessage());
        }

        @Override
        public void onVideoSizeChanged(VideoSize size) {
            videoWidth = size.width;
            videoHeight = size.height;
            updateTextureLayout(this);
            JSONObject payload = new JSONObject();
            try {
                payload.put("videoWidth", videoWidth);
                payload.put("videoHeight", videoHeight);
            } catch (Throwable ignored) {}
            emit(this, "resize", payload);
        }

        void updateTextureLayout(Slot slot) {
            try {
                int w = slot.view.getWidth();
                int h = slot.view.getHeight();
                if (w <= 0 || h <= 0 || slot.videoWidth <= 0 || slot.videoHeight <= 0) {
                    slot.texture.setLayoutParams(new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT));
                    return;
                }
                float aspect = (float) slot.videoWidth / (float) slot.videoHeight;
                int tw;
                int th;
                if ((float) w / (float) h > aspect) {
                    th = h;
                    tw = Math.round(h * aspect);
                } else {
                    tw = w;
                    th = Math.round(w / aspect);
                }
                FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                    Math.max(1, tw), Math.max(1, th), android.view.Gravity.CENTER);
                FrameLayout.LayoutParams current =
                    slot.texture.getLayoutParams() instanceof FrameLayout.LayoutParams
                        ? (FrameLayout.LayoutParams) slot.texture.getLayoutParams() : null;
                if (current != null && current.width == lp.width && current.height == lp.height
                    && current.gravity == lp.gravity) {
                    return;
                }
                slot.texture.setLayoutParams(lp);
                Log.i(TAG, "texture " + slot.id + " wrapper=" + w + "x" + h
                    + " video=" + slot.videoWidth + "x" + slot.videoHeight
                    + " texture=" + tw + "x" + th);
            } catch (Throwable ignored) {}
        }
    }
}
