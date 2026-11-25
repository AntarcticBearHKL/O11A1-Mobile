package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;

import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.PlaybackParameters;
import androidx.media3.common.Player;
import androidx.media3.datasource.okhttp.OkHttpDataSource;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.MediaSource;
import androidx.media3.exoplayer.source.ProgressiveMediaSource;
import androidx.media3.ui.AspectRatioFrameLayout;
import androidx.media3.ui.PlayerView;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;

final class VideoEngine {
    interface Listener {
        void onProgress(long positionMs, long durationMs, boolean playing);
        void onReady();
        void onError(String message);
    }

    private final Context context;
    private final CookieStore cookies;
    private final boolean preview;
    private final ExoPlayer player;
    private final PlayerView playerView;
    private final Handler main = new Handler(Looper.getMainLooper());
    private Listener listener;
    private String currentUrl = "";
    private String backupUrl = "";
    private boolean retriedBackup = false;
    private boolean released = false;

    private final Runnable ticker = new Runnable() {
        @Override public void run() {
            if (released) return;
            if (listener != null) {
                listener.onProgress(
                    Math.max(0, player.getCurrentPosition()),
                    Math.max(0, player.getDuration()),
                    player.isPlaying()
                );
            }
            main.postDelayed(this, 250);
        }
    };

    VideoEngine(Context context, CookieStore cookies, boolean preview) {
        this.context = context.getApplicationContext();
        this.cookies = cookies;
        this.preview = preview;
        OkHttpClient http = new OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(25, TimeUnit.SECONDS)
            .writeTimeout(20, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .build();
        Map<String, String> headers = new HashMap<>();
        headers.put("User-Agent", "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36");
        headers.put("Referer", "https://www.bilibili.com/");
        headers.put("Origin", "https://www.bilibili.com");
        headers.put("Accept", "*/*");
        String cookie = cookies.header();
        if (cookie != null && !cookie.isEmpty()) headers.put("Cookie", cookie);

        OkHttpDataSource.Factory sourceFactory = new OkHttpDataSource.Factory(http)
            .setDefaultRequestProperties(headers);
        player = new ExoPlayer.Builder(context)
            .setLoadControl(new DefaultLoadControl.Builder()
                .setBufferDurationsMs(preview ? 8000 : 30000,
                    preview ? 30000 : 120000,
                    preview ? 700 : 1500,
                    preview ? 1200 : 3000)
                .build())
            .build();
        player.setHandleAudioBecomingNoisy(true);
        player.setVolume(preview ? 0f : 1f);
        player.addListener(new Player.Listener() {
            @Override public void onPlaybackStateChanged(int state) {
                if (state == Player.STATE_READY && listener != null) {
                    listener.onReady();
                }
            }

            @Override public void onPlayerError(PlaybackException error) {
                if (!retriedBackup && backupUrl != null && !backupUrl.isEmpty()
                    && !backupUrl.equals(currentUrl)) {
                    retriedBackup = true;
                    loadInternal(backupUrl, currentUrl, true);
                } else if (listener != null) {
                    listener.onError(error == null ? "播放失败" : String.valueOf(error.getMessage()));
                }
            }
        });
        playerView = new PlayerView(context);
        playerView.setUseController(false);
        playerView.setPlayer(player);
        playerView.setShutterBackgroundColor(Color.TRANSPARENT);
        playerView.setResizeMode(preview
            ? AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            : AspectRatioFrameLayout.RESIZE_MODE_FIT);
    }

    PlayerView view() {
        return playerView;
    }

    ExoPlayer player() {
        return player;
    }

    boolean isPlaying() {
        return player.isPlaying() || player.getPlayWhenReady();
    }

    void setListener(Listener value) {
        listener = value;
    }

    void load(String url, String backup, boolean autoplay, boolean muted, boolean loop, long startMs) {
        currentUrl = url == null ? "" : url;
        backupUrl = backup == null ? "" : backup;
        retriedBackup = false;
        loadInternal(currentUrl, backupUrl, autoplay);
        player.setRepeatMode(loop ? Player.REPEAT_MODE_ONE : Player.REPEAT_MODE_OFF);
        player.setVolume(muted ? 0f : 1f);
        if (startMs > 0) player.seekTo(startMs);
        player.setPlayWhenReady(autoplay);
        main.removeCallbacks(ticker);
        main.postDelayed(ticker, 250);
    }

    private void loadInternal(String url, String backup, boolean autoplay) {
        if (url == null || url.isEmpty()) {
            if (listener != null) listener.onError("播放地址为空");
            return;
        }
        currentUrl = url;
        backupUrl = backup == null ? "" : backup;
        player.stop();
        player.clearMediaItems();
        OkHttpClient http = new OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(25, TimeUnit.SECONDS)
            .build();
        Map<String, String> headers = new HashMap<>();
        headers.put("User-Agent", "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36");
        headers.put("Referer", "https://www.bilibili.com/");
        headers.put("Origin", "https://www.bilibili.com");
        String cookie = cookies.header();
        if (cookie != null && !cookie.isEmpty()) headers.put("Cookie", cookie);
        OkHttpDataSource.Factory factory = new OkHttpDataSource.Factory(http)
            .setDefaultRequestProperties(headers);
        MediaSource source = new ProgressiveMediaSource.Factory(factory)
            .createMediaSource(MediaItem.fromUri(url));
        player.setMediaSource(source);
        player.prepare();
        player.setPlayWhenReady(autoplay);
    }

    void play() {
        player.setPlayWhenReady(true);
    }

    void pause() {
        player.setPlayWhenReady(false);
    }

    void toggle() {
        if (isPlaying()) pause(); else play();
    }

    void seekTo(long positionMs) {
        player.seekTo(Math.max(0, positionMs));
    }

    void setSpeed(float speed) {
        player.setPlaybackParameters(new PlaybackParameters(Math.max(0.1f, Math.min(4f, speed)), 1f));
    }

    void stop() {
        player.setPlayWhenReady(false);
        player.stop();
        player.clearMediaItems();
        main.removeCallbacks(ticker);
    }

    void release() {
        released = true;
        main.removeCallbacks(ticker);
        player.setPlayWhenReady(false);
        player.release();
    }
}
