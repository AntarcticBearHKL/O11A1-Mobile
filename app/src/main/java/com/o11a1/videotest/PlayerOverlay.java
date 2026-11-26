package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.bumptech.glide.Glide;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.LongConsumer;

final class PlayerOverlay extends FrameLayout {
    private final BiliApi api;
    private final CookieStore cookies;
    private final BiliExtras extras;
    private final VideoItem item;
    private final Runnable onClose;
    private final LongConsumer onProfile;
    private final VideoEngine engine;
    private final FrameLayout videoHost;
    private final ImageView poster;
    private final View dim;
    private final LinearLayout topBar;
    private final LinearLayout bottomPanel;
    private final TextView title;
    private final TextView owner;
    private final TextView quality;
    private final ProgressWheelView wheel;
    private final GridProgressView grid;
    private final DanmakuView danmaku;
    private final ImageButton playButton;
    private final TextView error;
    private final TextView dmToggle;
    private final TextView dmSend;
    private final TextView speed;
    private final LinearLayout liveChat;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private final Runnable longPressRunnable;
    private final java.util.List<String[]> liveMessages = new java.util.ArrayList<>();
    private LiveChatClient liveChatClient;
    private final int statusInset;
    private final long createdAt = System.currentTimeMillis();
    private int qualityQn;
    private int loadToken = 0;
    private boolean scrubbing = false;
    private boolean wasPlayingBeforeScrub = false;
    private boolean longPressed = false;
    private boolean pulling = false;
    private boolean swipeComments = false;
    private boolean closing = false;
    private boolean started = false;
    private boolean destroyed = false;
    private float touchStartY = 0;
    private float touchStartX = 0;
    private long touchStartAt = 0;
    private float pullProgress = 0;

    PlayerOverlay(Context context, BiliApi api, CookieStore cookies, VideoItem item,
                  View sourceView, Runnable onClose, LongConsumer onProfile) {
        super(context);
        this.api = api;
        this.cookies = cookies;
        this.extras = new BiliExtras(cookies, api);
        this.item = item;
        this.onClose = onClose;
        this.onProfile = onProfile;
        setBackgroundColor(Color.TRANSPARENT);
        setClickable(true);

        statusInset = statusBarHeight(context);
        engine = new VideoEngine(context, cookies, false);

        videoHost = new FrameLayout(context);
        videoHost.setBackgroundColor(Color.BLACK);
        videoHost.setClipChildren(true);
        addView(videoHost, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        poster = new ImageView(context);
        poster.setScaleType(ImageView.ScaleType.CENTER_CROP);
        poster.setBackgroundColor(Color.BLACK);
        Glide.with(this).load(item.pic).centerCrop().into(poster);
        videoHost.addView(poster, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        engine.view().setClickable(false);
        engine.view().setFocusable(false);
        videoHost.addView(engine.view(), new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        liveChat = new LinearLayout(context);
        liveChat.setOrientation(LinearLayout.VERTICAL);
        liveChat.setGravity(Gravity.BOTTOM);
        liveChat.setVisibility(View.GONE);
        FrameLayout.LayoutParams chatParams = new FrameLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        chatParams.gravity = Gravity.BOTTOM;
        chatParams.leftMargin = NativeTheme.dp(context, 14);
        chatParams.rightMargin = NativeTheme.dp(context, 14);
        chatParams.bottomMargin = NativeTheme.dp(context, 190);
        videoHost.addView(liveChat, chatParams);

        danmaku = new DanmakuView(context, api, extras);
        addView(danmaku, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        dim = new View(context);
        dim.setBackgroundColor(0x33000000);
        dim.setClickable(false);
        addView(dim, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        topBar = new LinearLayout(context);
        topBar.setOrientation(LinearLayout.HORIZONTAL);
        topBar.setGravity(Gravity.CENTER_VERTICAL);
        topBar.setPadding(NativeTheme.dp(context, 8), statusInset + NativeTheme.dp(context, 4),
            NativeTheme.dp(context, 12), NativeTheme.dp(context, 4));
        addView(topBar, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        ImageButton back = new ImageButton(context);
        back.setImageResource(R.drawable.ic_back);
        back.setBackgroundColor(Color.TRANSPARENT);
        back.setColorFilter(Color.WHITE);
        back.setOnClickListener(v -> close());
        topBar.addView(back, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 44), NativeTheme.dp(context, 44)));

        title = new TextView(context);
        title.setText(item.title);
        title.setTextColor(Color.WHITE);
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        title.setTypeface(NativeTheme.titleTypeface());
        title.setMaxLines(1);
        title.setEllipsize(android.text.TextUtils.TruncateAt.END);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
            0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
        titleParams.leftMargin = NativeTheme.dp(context, 4);
        topBar.addView(title, titleParams);

        TextView followButton = new TextView(context);
        followButton.setText("关注");
        followButton.setTextColor(0xFFFFFFFF);
        followButton.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        followButton.setGravity(android.view.Gravity.CENTER);
        followButton.setPadding(NativeTheme.dp(context, 10), NativeTheme.dp(context, 4),
            NativeTheme.dp(context, 10), NativeTheme.dp(context, 4));
        followButton.setBackground(NativeTheme.rounded(0x33FFFFFF, NativeTheme.dp(context, 18)));
        followButton.setOnClickListener(v -> pool.execute(() -> {
            JSONObject result = extras.follow(item.mid, true);
            final boolean ok = result != null && result.optBoolean("ok", false);
            main.post(() -> {
                followButton.setText(ok ? "已关注" : "关注失败");
                followButton.setAlpha(ok ? 0.6f : 1f);
            });
        }));
        topBar.addView(followButton, new LinearLayout.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));
        topBar.setVisibility(GONE);

        playButton = new ImageButton(context);
        playButton.setImageResource(android.R.drawable.ic_media_pause);
        playButton.setBackgroundColor(0x4D000000);
        playButton.setColorFilter(Color.WHITE);
        playButton.setPadding(NativeTheme.dp(context, 14), NativeTheme.dp(context, 14),
            NativeTheme.dp(context, 14), NativeTheme.dp(context, 14));
        playButton.setOnClickListener(v -> togglePlay());
        LayoutParams playParams = new LayoutParams(NativeTheme.dp(context, 64), NativeTheme.dp(context, 64));
        playParams.gravity = Gravity.CENTER;
        addView(playButton, playParams);

        bottomPanel = new LinearLayout(context);
        bottomPanel.setOrientation(LinearLayout.VERTICAL);
        bottomPanel.setBackgroundColor(Color.TRANSPARENT);
        bottomPanel.setPadding(NativeTheme.dp(context, 14), 0,
            NativeTheme.dp(context, 14), 0);
        LayoutParams panelParams = new LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        panelParams.gravity = Gravity.BOTTOM;
        panelParams.bottomMargin = NativeTheme.dp(context, 10);
        addView(bottomPanel, panelParams);

        owner = new TextView(context);
        owner.setText(item.owner + " · UP 主页");
        owner.setTextColor(Color.WHITE);
        owner.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13);
        owner.setOnClickListener(v -> {
            if (onProfile != null) onProfile.accept(item.mid);
        });
        bottomPanel.addView(owner, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));
        owner.setVisibility(GONE);

        grid = new GridProgressView(context);
        LinearLayout.LayoutParams gridParams = new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        gridParams.topMargin = NativeTheme.dp(context, 8);
        bottomPanel.addView(grid, gridParams);

        wheel = new ProgressWheelView(context);
        LinearLayout.LayoutParams wheelParams = new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 48));
        wheelParams.topMargin = NativeTheme.dp(context, 2);
        bottomPanel.addView(wheel, wheelParams);
        wheel.setOnScrub(this::scrub);

        LinearLayout actions = new LinearLayout(context);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        actions.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams actionParams = new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 38));
        actionParams.topMargin = NativeTheme.dp(context, 2);
        bottomPanel.addView(actions, actionParams);
        actions.setVisibility(GONE);

        ImageButton comments = iconButton(context, android.R.drawable.ic_menu_info_details);
        comments.setOnClickListener(v -> CommentsView.show(getContext(), api, extras, item.aid));
        actions.addView(comments, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 38), NativeTheme.dp(context, 38)));

        ImageButton like = iconButton(context, android.R.drawable.ic_menu_myplaces);
        like.setOnClickListener(v -> pool.execute(() -> extras.like(item.aid, true)));
        actions.addView(like, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 38), NativeTheme.dp(context, 38)));

        ImageButton coin = iconButton(context, android.R.drawable.ic_menu_add);
        coin.setOnClickListener(v -> pool.execute(() -> extras.coin(item.aid, 1, true)));
        actions.addView(coin, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 38), NativeTheme.dp(context, 38)));

        ImageButton fav = iconButton(context, android.R.drawable.btn_star_big_off);
        fav.setOnClickListener(v -> pool.execute(() -> extras.favorite(item.aid, true)));
        actions.addView(fav, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 38), NativeTheme.dp(context, 38)));

        dmToggle = new TextView(context);
        dmToggle.setText("弹");
        dmToggle.setTextColor(0xCCFFFFFF);
        dmToggle.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        dmToggle.setGravity(android.view.Gravity.CENTER);
        dmToggle.setOnClickListener(v -> {
            boolean next = !danmaku.isDanmakuEnabled();
            danmaku.setDanmakuEnabled(next);
            dmToggle.setTextColor(next ? 0xFFFFFFFF : 0x66FFFFFF);
        });
        actions.addView(dmToggle, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 32), NativeTheme.dp(context, 34)));

        dmSend = new TextView(context);
        dmSend.setText("＋弹");
        dmSend.setTextColor(0xCCFFFFFF);
        dmSend.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
        dmSend.setGravity(android.view.Gravity.CENTER);
        dmSend.setOnClickListener(v -> showDanmakuInput());
        actions.addView(dmSend, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 38), NativeTheme.dp(context, 34)));

        View spacer = new View(context);
        actions.addView(spacer, new LinearLayout.LayoutParams(0, 1, 1f));

        quality = new TextView(context);
        quality.setTextColor(0xB3FFFFFF);
        quality.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
        quality.setTypeface(NativeTheme.numberTypeface());
        quality.setText("720P");
        quality.setOnClickListener(v -> cycleQuality());
        actions.addView(quality, new LinearLayout.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));

        speed = new TextView(context);
        speed.setTextColor(0xB3FFFFFF);
        speed.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
        speed.setTypeface(NativeTheme.numberTypeface());
        speed.setText("1.0x");
        speed.setPadding(NativeTheme.dp(context, 6), 0, 0, 0);
        final float[] speeds = {1f, 1.25f, 1.5f, 2f};
        final int[] speedIndex = {0};
        speed.setOnClickListener(v -> {
            speedIndex[0] = (speedIndex[0] + 1) % speeds.length;
            float value = speeds[speedIndex[0]];
            engine.setSpeed(value);
            speed.setText(value == 1f ? "1.0x" : value + "x");
        });
        actions.addView(speed, new LinearLayout.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));

        error = new TextView(context);
        error.setTextColor(NativeTheme.ROSE);
        error.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13);
        error.setGravity(Gravity.CENTER);
        error.setVisibility(View.GONE);
        LayoutParams errorParams = new LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        errorParams.gravity = Gravity.CENTER;
        addView(error, errorParams);

        longPressRunnable = () -> {
            if (!engine.isPlaying() || pulling) return;
            longPressed = true;
            engine.setSpeed(2f);
            performHapticFeedback(android.view.HapticFeedbackConstants.VIRTUAL_KEY);
        };

        engine.setListener(new VideoEngine.Listener() {
            @Override public void onProgress(long positionMs, long durationMs, boolean playing) {
                if (!scrubbing) {
                    wheel.setProgress(positionMs, durationMs);
                    grid.setProgress(positionMs, durationMs);
                }
                danmaku.setPosition(positionMs);
                updatePlayIcon(playing);
            }

            @Override public void onReady() {
                poster.setVisibility(View.GONE);
                error.setVisibility(View.GONE);
                engine.play();
            }

            @Override public void onFirstFrame() {
                poster.setVisibility(View.GONE);
            }

            @Override public void onError(String message) {
                error.setText(message);
                error.setVisibility(View.VISIBLE);
            }
        });

        setOnTouchListener(this::onRootTouch);
        qualityQn = NativeTheme.quality(context);
        loadQuality(qualityQn);
        if (!item.live && item.cid > 0) danmaku.load(item.cid);

        if (sourceView != null) {
            videoHost.post(() -> animateOpen(sourceView));
        }
    }

    private static ImageButton iconButton(Context context, int resource) {
        ImageButton button = new ImageButton(context);
        button.setImageResource(resource);
        button.setBackgroundColor(Color.TRANSPARENT);
        button.setColorFilter(Color.WHITE);
        return button;
    }

    private static int statusBarHeight(Context context) {
        int id = context.getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? context.getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }

    void start() {
        if (started) return;
        started = true;
    }

    private void animateOpen(View sourceView) {
        int[] rootLoc = new int[2];
        int[] sourceLoc = new int[2];
        getLocationInWindow(rootLoc);
        sourceView.getLocationInWindow(sourceLoc);
        int x = sourceLoc[0] - rootLoc[0];
        int y = sourceLoc[1] - rootLoc[1];
        int w = sourceView.getWidth();
        int h = sourceView.getHeight();
        if (w <= 0 || h <= 0) return;
        videoHost.setX(x);
        videoHost.setY(y);
        ViewGroup.LayoutParams lp = videoHost.getLayoutParams();
        lp.width = w;
        lp.height = h;
        videoHost.setLayoutParams(lp);
        videoHost.animate()
            .x(0).y(0)
            .setDuration(260)
            .withEndAction(() -> {
                ViewGroup.LayoutParams full = videoHost.getLayoutParams();
                full.width = LayoutParams.MATCH_PARENT;
                full.height = LayoutParams.MATCH_PARENT;
                videoHost.setLayoutParams(full);
                videoHost.setX(0);
                videoHost.setY(0);
            })
            .start();
    }

    private void loadQuality(int qn) {
        qualityQn = qn <= 0 ? 80 : qn;
        loadToken += 1;
        final int token = loadToken;
        final int requestQn = qualityQn;
        final boolean live = item.roomId > 0;
        if (live) {
            wheel.setVisibility(GONE);
            grid.setVisibility(GONE);
            bottomPanel.setVisibility(GONE);
            quality.setText("LIVE");
            speed.setVisibility(GONE);
            dmToggle.setVisibility(GONE);
            dmSend.setVisibility(GONE);
            liveChat.setVisibility(VISIBLE);
            startLiveChat();
        }
        pool.execute(() -> {
            JSONObject result;
            if (live) {
                result = extras.liveRoom(item.roomId);
            } else if (item.epId > 0) {
                result = extras.playPgc(item.epId, item.bvid, item.cid, requestQn);
            } else {
                result = api.playQuality(item.bvid, item.cid, requestQn);
            }
            final JSONObject value = result;
            main.post(() -> {
                if (token != loadToken) return;
                if (value == null || !value.optBoolean("ok", false)) {
                    if (!live && qualityQn > 64) loadQuality(64);
                    else if (!live && qualityQn > 32) loadQuality(32);
                    else {
                        error.setText(live ? "无法获取直播地址" : "无法获取播放地址");
                        error.setVisibility(View.VISIBLE);
                    }
                    return;
                }
                String url = value.optString("url", value.optString("remote", ""));
                String backup = value.optString("backup", value.optString("backupRemote", ""));
                String label = value.optString("qualityLabel", "");
                if (!live) quality.setText(label.isEmpty() ? requestQn + "P" : label);
                if (!value.optString("title", "").isEmpty()) title.setText(value.optString("title"));
                if (!value.optString("owner", "").isEmpty()) {
                    owner.setText(value.optString("owner") + " · UP 主页");
                }
                if (url.isEmpty()) return;
                engine.load(url, backup, true, false, false,
                    live ? 0L : Math.max(0, item.progressSec) * 1000L);
            });
        });
    }

    private void cycleQuality() {
        if (item.roomId > 0) return;
        if (qualityQn > 64) loadQuality(64);
        else if (qualityQn > 32) loadQuality(32);
        else loadQuality(80);
    }

    private void startLiveChat() {
        if (liveChatClient != null || item.roomId <= 0) return;
        liveChatClient = new LiveChatClient();
        pool.execute(() -> {
            JSONObject info = extras.liveDanmuInfo(item.roomId);
            final String token = info == null ? "" : info.optString("token", "");
            final String host = info == null ? "" : info.optString("host", "");
            final int port = info == null ? 443 : info.optInt("wssPort", 443);
            android.util.Log.i("O11A1LiveChat", "info token=" + token.length()
                + " host=" + host + " port=" + port + " ok=" + (info != null && info.optBoolean("ok")));
            main.post(() -> {
                if (destroyed || closing || token.isEmpty() || host.isEmpty()) return;
                LiveChatClient client = liveChatClient;
                if (client == null) return;
                client.connect(item.roomId, token, host, port, new LiveChatClient.Listener() {
                    @Override public void onMessage(String user, String text) {
                        appendLiveChat(user, text);
                    }

                    @Override public void onClosed() {
                    }
                });
            });
        });
    }

    private void appendLiveChat(String user, String text) {
        if (destroyed || text == null || text.isEmpty()) return;
        liveMessages.add(new String[]{user == null || user.isEmpty() ? "观众" : user, text});
        while (liveMessages.size() > 7) liveMessages.remove(0);
        renderLiveChat();
    }

    private void renderLiveChat() {
        liveChat.removeAllViews();
        for (String[] message : liveMessages) {
            TextView line = new TextView(getContext());
            String prefix = message[0] + "：";
            android.text.SpannableString value = new android.text.SpannableString(prefix + message[1]);
            value.setSpan(new android.text.style.ForegroundColorSpan(0xFF8FC4FF),
                0, prefix.length(), android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            line.setText(value);
            line.setTextColor(Color.WHITE);
            line.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
            line.setMaxLines(1);
            line.setEllipsize(android.text.TextUtils.TruncateAt.END);
            line.setShadowLayer(2f, 0f, 0f, Color.BLACK);
            liveChat.addView(line);
        }
    }

    private void stopLiveChat() {
        LiveChatClient client = liveChatClient;
        liveChatClient = null;
        if (client != null) client.close();
        liveMessages.clear();
        liveChat.removeAllViews();
    }

    private boolean onRootTouch(View view, MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                touchStartY = event.getY();
                touchStartX = event.getX();
                touchStartAt = System.currentTimeMillis();
                pulling = false;
                swipeComments = false;
                longPressed = false;
                pullProgress = 0;
                main.postDelayed(longPressRunnable, 180);
                return true;
            case MotionEvent.ACTION_MOVE:
                float dy = event.getY() - touchStartY;
                float dx = event.getX() - touchStartX;
                if (dx < -NativeTheme.dp(getContext(), 60)
                    && Math.abs(dx) > Math.abs(dy) * 1.3f) {
                    main.removeCallbacks(longPressRunnable);
                    swipeComments = true;
                } else if (Math.abs(dy) > 20 && Math.abs(dy) > Math.abs(dx)) {
                    main.removeCallbacks(longPressRunnable);
                    if (dy > 0) {
                        pulling = true;
                        updatePull(dy);
                    }
                }
                return true;
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                main.removeCallbacks(longPressRunnable);
                if (swipeComments) {
                    swipeComments = false;
                    CommentsView.show(getContext(), api, extras, item.aid);
                    return true;
                }
                if (longPressed) {
                    longPressed = false;
                    engine.setSpeed(1f);
                    return true;
                }
                if (pulling) {
                    float pullDy = Math.max(0, event.getY() - touchStartY);
                    float velocity = pullDy / Math.max(0.001f, (System.currentTimeMillis() - touchStartAt) / 1000f);
                    finishPull(pullDy, velocity);
                    return true;
                }
                if (System.currentTimeMillis() - touchStartAt < 240
                    && Math.abs(event.getX() - touchStartX) < 14
                    && Math.abs(event.getY() - touchStartY) < 14
                    && System.currentTimeMillis() - createdAt > 420) {
                    togglePlay();
                }
                return true;
            default:
                return false;
        }
    }

    private void updatePull(float dy) {
        float max = Math.max(NativeTheme.dp(getContext(), 120), getHeight() * 0.52f);
        pullProgress = Math.min(1, Math.max(0, dy / max));
        float fullW = getWidth();
        float fullH = getHeight();
        float targetW = fullW - NativeTheme.dp(getContext(), 48);
        float targetH = targetW * 9f / 16f;
        float targetX = NativeTheme.dp(getContext(), 24);
        float targetY = statusInset + NativeTheme.dp(getContext(), 12);
        float p = pullProgress;
        float w = fullW + (targetW - fullW) * p;
        float h = fullH + (targetH - fullH) * p;
        float x = (targetX) * p;
        float y = (targetY) * p;
        ViewGroup.LayoutParams lp = videoHost.getLayoutParams();
        lp.width = Math.max(1, Math.round(w));
        lp.height = Math.max(1, Math.round(h));
        videoHost.setLayoutParams(lp);
        videoHost.setX(x);
        videoHost.setY(y);
        topBar.setAlpha(1 - p);
        bottomPanel.setAlpha(1 - p);
        playButton.setAlpha(0);
        dim.setAlpha(1 - p * 0.5f);
    }

    private void finishPull(float dy, float velocity) {
        if (pullProgress > 0.28f || velocity > 780f) {
            close();
        } else {
            videoHost.animate().x(0).y(0).setDuration(220).withEndAction(() -> {
                ViewGroup.LayoutParams lp = videoHost.getLayoutParams();
                lp.width = LayoutParams.MATCH_PARENT;
                lp.height = LayoutParams.MATCH_PARENT;
                videoHost.setLayoutParams(lp);
                videoHost.setX(0);
                videoHost.setY(0);
            }).start();
            topBar.animate().alpha(1).setDuration(220).start();
            bottomPanel.animate().alpha(1).setDuration(220).start();
            playButton.setAlpha(engine.isPlaying() ? 0 : 1);
            dim.animate().alpha(1).setDuration(220).start();
            pullProgress = 0;
        }
    }

    private void togglePlay() {
        engine.toggle();
        updatePlayIcon(engine.isPlaying());
    }

    private void updatePlayIcon(boolean playing) {
        playButton.setImageResource(playing
            ? android.R.drawable.ic_media_pause
            : android.R.drawable.ic_media_play);
        playButton.setAlpha(playing ? 0f : 1f);
        videoHost.setBackgroundColor(playing ? Color.BLACK : NativeTheme.ROSE);
    }

    private void scrub(double ratio, boolean finished) {
        long duration = engine.player().getDuration();
        if (duration <= 0 || duration == androidx.media3.common.C.TIME_UNSET) return;
        if (!finished) {
            if (!scrubbing) {
                scrubbing = true;
                wasPlayingBeforeScrub = engine.isPlaying();
                engine.pause();
            }
            wheel.setProgress((long) (duration * ratio), duration);
            return;
        }
        engine.seekTo((long) (duration * ratio));
        scrubbing = false;
        if (wasPlayingBeforeScrub) engine.play();
    }

    private void showText(String text) {
        new android.app.AlertDialog.Builder(getContext())
            .setMessage(text)
            .setPositiveButton("好", null)
            .show();
    }

    boolean isPlaying() {
        return engine.isPlaying();
    }

    void setPipMode(boolean pip) {
        if (pip) {
            ViewGroup.LayoutParams lp = videoHost.getLayoutParams();
            lp.width = LayoutParams.MATCH_PARENT;
            lp.height = LayoutParams.MATCH_PARENT;
            videoHost.setLayoutParams(lp);
            videoHost.setX(0);
            videoHost.setY(0);
            videoHost.setVisibility(View.VISIBLE);
            topBar.setVisibility(View.GONE);
            bottomPanel.setVisibility(View.GONE);
            playButton.setVisibility(View.GONE);
            poster.setVisibility(View.GONE);
            danmaku.setVisibility(View.GONE);
            liveChat.setVisibility(View.GONE);
            dim.setVisibility(View.GONE);
            setBackgroundColor(Color.BLACK);
        } else {
            topBar.setVisibility(View.VISIBLE);
            bottomPanel.setVisibility(View.VISIBLE);
            playButton.setVisibility(View.VISIBLE);
            dim.setVisibility(View.VISIBLE);
            danmaku.setVisibility(danmaku.isDanmakuEnabled() ? View.VISIBLE : View.GONE);
            liveChat.setVisibility(item.roomId > 0 ? View.VISIBLE : View.GONE);
            setBackgroundColor(Color.TRANSPARENT);
        }
    }

    void close() {
        if (closing) return;
        closing = true;
        stopLiveChat();
        engine.stop();
        onClose.run();
    }

    void destroy() {
        if (destroyed) return;
        destroyed = true;
        stopLiveChat();
        danmaku.destroy();
        engine.release();
        pool.shutdownNow();
    }

    private void showDanmakuInput() {
        final android.widget.EditText input = new android.widget.EditText(getContext());
        input.setHint("发一条弹幕");
        input.setSingleLine(true);
        input.setTextColor(NativeTheme.foreground(getContext()));
        input.setHintTextColor(NativeTheme.tertiary(getContext()));
        int pad = NativeTheme.dp(getContext(), 12);
        input.setPadding(pad, pad / 2, pad, pad / 2);
        new android.app.AlertDialog.Builder(getContext())
            .setTitle("发弹幕")
            .setView(input)
            .setPositiveButton("发送", (dialog, which) -> {
                String text = input.getText().toString().trim();
                if (text.isEmpty()) return;
                long position = engine.player().getCurrentPosition();
                danmaku.send(text, position);
            })
            .setNegativeButton("取消", null)
            .show();
    }
}
