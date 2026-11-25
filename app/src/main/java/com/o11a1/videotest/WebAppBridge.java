package com.o11a1.videotest;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentValues;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.graphics.Bitmap;
import android.media.AudioManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.provider.MediaStore;
import android.util.Log;
import android.view.PixelCopy;
import android.view.WindowManager;
import android.webkit.CookieManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.FutureTask;
import java.util.concurrent.TimeUnit;

/** JavaScript bridge exposed as window.O11A1Native. */
final class WebAppBridge {
    private static final String TAG = "O11A1Bridge";
    private final Activity activity;
    private final BiliApi api;
    private final BiliExtras extras;
    private final CookieStore cookies;
    private static final long PREVIEW_URL_TTL = 10 * 60 * 1000L;
    private static final long QUALITY_URL_TTL = 4 * 60 * 1000L;
    private final ConcurrentHashMap<String, PreviewEntry> previewUrls = new ConcurrentHashMap<>();
    private final Set<String> previewsLoading = ConcurrentHashMap.newKeySet();
    private final ConcurrentHashMap<String, PreviewEntry> qualityInfos = new ConcurrentHashMap<>();
    private final Set<String> qualityLoading = ConcurrentHashMap.newKeySet();
    private final ConcurrentHashMap<String, PreviewEntry> dashInfos = new ConcurrentHashMap<>();
    private final Set<String> dashLoading = ConcurrentHashMap.newKeySet();
    private final ExecutorService smsPool = Executors.newSingleThreadExecutor(runnable -> {
        Thread thread = new Thread(runnable, "o11a1-sms-login");
        thread.setDaemon(true);
        return thread;
    });
    private volatile WebView webView;
    private volatile NativePlayerHost nativePlayers;
    private final java.util.concurrent.atomic.AtomicBoolean smsBusy = new java.util.concurrent.atomic.AtomicBoolean(false);
    private final ExecutorService previewPool = Executors.newFixedThreadPool(2, runnable -> {
        Thread thread = new Thread(runnable, "o11a1-preview");
        thread.setDaemon(true);
        return thread;
    });
    private final ExecutorService qualityPool = Executors.newFixedThreadPool(2, runnable -> {
        Thread thread = new Thread(runnable, "o11a1-quality");
        thread.setDaemon(true);
        return thread;
    });

    private static final class PreviewEntry {
        final String json;
        final long at;

        PreviewEntry(String json, long at) {
            this.json = json;
            this.at = at;
        }
    }

    WebAppBridge(Activity activity, BiliApi api, CookieStore cookies) {
        this.activity = activity;
        this.api = api;
        this.extras = new BiliExtras(cookies, api);
        this.cookies = cookies;
    }

    void setWebView(WebView view) {
        this.webView = view;
    }

    void setNativePlayers(NativePlayerHost players) {
        this.nativePlayers = players;
    }

    @JavascriptInterface
    public String nativePlayerLoad(String slot, String json) {
        JSONObject out = new JSONObject();
        try {
            NativePlayerHost players = nativePlayers;
            if (players == null) {
                out.put("ok", false);
                out.put("error", "native player unavailable");
                return out.toString();
            }
            players.load(slot, new JSONObject(json == null ? "{}" : json));
            out.put("ok", true);
        } catch (Throwable error) {
            out = error(error);
        }
        return out.toString();
    }

    @JavascriptInterface
    public String nativePlayerControl(String slot, String action, double value) {
        JSONObject out = new JSONObject();
        try {
            NativePlayerHost players = nativePlayers;
            if (players != null) players.control(slot, action, value);
            out.put("ok", players != null);
        } catch (Throwable error) {
            out = error(error);
        }
        return out.toString();
    }

    @JavascriptInterface
    public String nativePlayerRect(String slot, double x, double y, double width, double height,
                                   boolean visible, double rotation) {
        JSONObject out = new JSONObject();
        try {
            NativePlayerHost players = nativePlayers;
            if (players != null) {
                players.rect(slot, (float) x, (float) y, (float) width, (float) height, visible,
                    (float) rotation);
            }
            out.put("ok", players != null);
        } catch (Throwable error) {
            out = error(error);
        }
        return out.toString();
    }

    @JavascriptInterface
    public String nativePlayerRelease(String slot) {        JSONObject out = new JSONObject();
        try {
            NativePlayerHost players = nativePlayers;
            if (players != null) players.release(slot);
            out.put("ok", players != null);
        } catch (Throwable error) {
            out = error(error);
        }
        return out.toString();
    }

    @JavascriptInterface
    public String nativePlayerLayer(String slot, boolean background) {
        JSONObject out = new JSONObject();
        try {
            NativePlayerHost players = nativePlayers;
            if (players != null) players.layer(slot, background);
            out.put("ok", players != null);
        } catch (Throwable error) {
            out = error(error);
        }
        return out.toString();
    }

    @JavascriptInterface
    public String nativePlayerState(String slot) {
        try {
            NativePlayerHost players = nativePlayers;
            return players == null ? "{\"ok\":false}" : players.snapshot(slot);
        } catch (Throwable error) {
            return error(error).toString();
        }
    }

    @JavascriptInterface
    public boolean available() {
        return true;
    }

    @JavascriptInterface
    public String version() {
        return "0.2.0-native";
    }

    @JavascriptInterface
    public String popular(int page, int ps) {
        return runExtra(() -> api.popular(page, ps <= 0 ? 20 : ps).toString());
    }

    @JavascriptInterface
    public String recommend(int page, int ps, int fresh) {
        return runExtra(() -> api.recommend(page, ps, fresh).toString());
    }

    @JavascriptInterface
    public String search(String keyword, int page) {
        return runExtra(() -> api.search(keyword, page).toString());
    }

    @JavascriptInterface
    public String play(String bvid, long cid) {
        return runExtra(() -> api.play(bvid, cid).toString());
    }

    @JavascriptInterface
    public String account() {
        return runExtra(() -> extras.account().toString());
    }

    @JavascriptInterface
    public String favorites(int page) {
        return runExtra(() -> extras.favorites(page).toString());
    }

    @JavascriptInterface
    public String history(int page, String cursor) {
        return runExtra(() -> extras.history(page, cursor).toString());
    }

    @JavascriptInterface
    public String following(int page) {
        return runExtra(() -> extras.following(page).toString());
    }

    @JavascriptInterface
    public String dynamicFeed(int page, String filter) {
        return runExtra(() -> extras.dynamicFeed(page, filter).toString());
    }

    @JavascriptInterface
    public String messages(int page, String filter) {
        return runExtra(() -> extras.messages(page, filter).toString());
    }

    @JavascriptInterface
    public String ranking(int page) {
        return runExtra(() -> extras.ranking(page).toString());
    }

    @JavascriptInterface
    public String space(long mid, int page, String order) {
        return runExtra(() -> extras.space(mid, page, order).toString());
    }

    @JavascriptInterface
    public String bangumi(int page, int seasonType) {
        return runExtra(() -> extras.bangumi(page, seasonType).toString());
    }

    @JavascriptInterface
    public String season(long seasonId) {
        return runExtra(() -> extras.season(seasonId).toString());
    }

    @JavascriptInterface
    public String playPgc(long epId, String bvid, long cid, int qn) {
        return runExtra(() -> extras.playPgc(epId, bvid, cid, qn).toString());
    }

    @JavascriptInterface
    public String live(int page) {
        return runExtra(() -> extras.live(page).toString());
    }

    @JavascriptInterface
    public String liveRoom(long roomId) {
        return runExtra(() -> extras.liveRoom(roomId).toString(), 15);
    }

    @JavascriptInterface
    public String liveDanmuInfo(long roomId) {
        return runExtra(() -> extras.liveDanmuInfo(roomId).toString(), 15);
    }

    @JavascriptInterface
    public String zone(int rid, int page) {
        return runExtra(() -> extras.zone(rid, page).toString());
    }

    @JavascriptInterface
    public String videoInfo(String bvid) {
        return runExtra(() -> extras.videoInfo(bvid).toString());
    }

    @JavascriptInterface
    public String related(String bvid) {
        return runExtra(() -> extras.related(bvid).toString());
    }

    @JavascriptInterface
    public String like(long aid, boolean on) {
        return runExtra(() -> extras.like(aid, on).toString());
    }

    @JavascriptInterface
    public String coin(long aid, int count, boolean likeAlso) {
        return runExtra(() -> extras.coin(aid, count, likeAlso).toString());
    }

    @JavascriptInterface
    public String favorite(long aid, boolean on) {
        return runExtra(() -> extras.favorite(aid, on).toString());
    }

    @JavascriptInterface
    public String follow(long mid, boolean on) {
        return runExtra(() -> extras.follow(mid, on).toString());
    }

    @JavascriptInterface
    public String sendComment(long aid, String message) {
        return runExtra(() -> extras.sendComment(aid, message).toString());
    }

    @JavascriptInterface
    public String sendDanmaku(long cid, String message, long progressMs) {
        return runExtra(() -> extras.sendDanmaku(cid, message, progressMs).toString());
    }

    @JavascriptInterface
    public String comments(long aid, int page, int sort) {
        return runExtra(() -> extras.comments(aid, page, sort).toString());
    }

    @JavascriptInterface
    public String commentsReplies(long aid, long root, int page) {
        return runExtra(() -> extras.commentsReplies(aid, root, page).toString());
    }

    @JavascriptInterface
    public String mediaStats() {
        return "{\"ok\":true,\"bytes\":0,\"requests\":0,\"direct\":true}";
    }

    @JavascriptInterface
    public int displayHz() {
        try {
            return Math.round(activity.getWindowManager().getDefaultDisplay().getRefreshRate());
        } catch (Throwable error) {
            return 0;
        }
    }

    @JavascriptInterface
    public double compositorFps() {
        return displayHz();
    }


    @JavascriptInterface
    public String sendSmsCode(String tel, String cid) {
        JSONObject out = new JSONObject();
        try {
            final String phone = tel == null ? "" : tel.trim();
            final String country = cid == null || cid.trim().isEmpty() ? "86" : cid.trim();
            if (!phone.matches("\\d{5,20}")) {
                out.put("ok", false);
                out.put("error", "请输入正确的手机号");
                return out.toString();
            }
            if (!smsBusy.compareAndSet(false, true)) {
                out.put("ok", false);
                out.put("pending", true);
                out.put("error", "正在验证，请稍候");
                return out.toString();
            }
            smsPool.execute(() -> {
                JSONObject result = new JSONObject();
                try {
                    result.put("tel", phone);
                    result.put("cid", country);
                    JSONObject captcha = api.loginCaptcha();
                    if (!captcha.optBoolean("ok", false)) {
                        result.put("ok", false);
                        result.put("error", captcha.optString("error", "验证码初始化失败"));
                    } else {
                        GeetestDialog.Result challenge = GeetestDialog.show(
                            activity,
                            captcha.optString("gt", ""),
                            captcha.optString("challenge", ""));
                        if (!challenge.ok) {
                            result.put("ok", false);
                            result.put("cancelled", challenge.cancelled);
                            result.put("error", challenge.cancelled ? "已取消验证" : challenge.error);
                        } else {
                            JSONObject send = api.smsSend(phone, country,
                                captcha.optString("token", ""),
                                captcha.optString("challenge", ""),
                                challenge.validate, challenge.seccode);
                            if (!send.optBoolean("ok", false)) {
                                result.put("ok", false);
                                result.put("error", send.optString("message",
                                    send.optString("error", "短信发送失败")));
                            } else {
                                result.put("ok", true);
                                result.put("captchaKey", send.optString("captchaKey", ""));
                            }
                        }
                    }
                } catch (Throwable error) {
                    result = error(error);
                } finally {
                    smsBusy.set(false);
                    notifySmsCode(result);
                }
            });
            out.put("ok", true);
            out.put("pending", true);
        } catch (Throwable error) {
            out = error(error);
            smsBusy.set(false);
        }
        return out.toString();
    }

    private void notifySmsCode(JSONObject result) {
        WebView view = webView;
        if (view == null) return;
        final String payload = result == null ? "{}" : result.toString();
        view.post(() -> {
            try {
                view.evaluateJavascript(
                    "window.O11A1Login&&window.O11A1Login.onSmsCode&&window.O11A1Login.onSmsCode("
                        + JSONObject.quote(payload) + ")", null);
            } catch (Throwable ignored) {}
        });
    }

    @JavascriptInterface
    public String smsLogin(String tel, String cid, String code, String captchaKey) {
        JSONObject out = new JSONObject();
        try {
            String phone = tel == null ? "" : tel.trim();
            String country = cid == null || cid.trim().isEmpty() ? "86" : cid.trim();
            String smsCode = code == null ? "" : code.trim();
            if (phone.isEmpty() || smsCode.isEmpty()) {
                out.put("ok", false);
                out.put("error", "手机号或验证码为空");
                return out.toString();
            }
            JSONObject result = api.smsLogin(phone, country, smsCode,
                captchaKey == null ? "" : captchaKey);
            if (!result.optBoolean("ok", false)) {
                out.put("ok", false);
                out.put("error", result.optString("error",
                    result.optString("message", "短信登录失败")));
                return out.toString();
            }
            syncCookiesToWebView();
            out.put("ok", true);
            out.put("loggedIn", true);
            out.put("name", result.optString("name", ""));
            out.put("mid", result.optLong("mid", 0));
        } catch (Throwable error) {
            out = error(error);
        }
        return out.toString();
    }

    private void syncCookiesToWebView() {
        try {
            CookieManager manager = CookieManager.getInstance();
            manager.setAcceptCookie(true);
            java.util.Map<String, String> snapshot = cookies.snapshot();
            for (java.util.Map.Entry<String, String> entry : snapshot.entrySet()) {
                String cookie = entry.getKey() + "=" + entry.getValue()
                    + "; Domain=.bilibili.com; Path=/";
                manager.setCookie("https://www.bilibili.com", cookie);
                manager.setCookie("https://api.bilibili.com", cookie);
                manager.setCookie("https://passport.bilibili.com", cookie);
            }
            manager.flush();
        } catch (Throwable ignored) {}
    }

    @JavascriptInterface
    public String copy(String text) {
        JSONObject out = new JSONObject();
        try {
            activity.runOnUiThread(() -> {
                try {
                    ClipboardManager manager = (ClipboardManager) activity.getSystemService(Context.CLIPBOARD_SERVICE);
                    if (manager != null) manager.setPrimaryClip(ClipData.newPlainText("O11A1", text));
                } catch (Throwable error) {
                    Log.w(TAG, "clipboard failed", error);
                }
            });
            out.put("ok", true);
        } catch (Throwable error) {
            out = error(error);
        }
        return out.toString();
    }

    @JavascriptInterface
    public String haptic(String style) {
        JSONObject out = new JSONObject();
        try {
            Vibrator vibrator = (Vibrator) activity.getSystemService(Context.VIBRATOR_SERVICE);
            if (vibrator == null || !vibrator.hasVibrator()) {
                out.put("ok", false);
                out.put("error", "no vibrator");
                return out.toString();
            }
            String value = style == null ? "light" : style;
            int amplitude = "heavy".equals(value) ? 255 : ("medium".equals(value) ? 190 : 130);
            vibrator.vibrate(VibrationEffect.createOneShot(8, amplitude));
            out.put("ok", true);
        } catch (Throwable error) {
            out = error(error);
        }
        return out.toString();
    }

    @JavascriptInterface
    public String screenshot() {
        JSONObject out = new JSONObject();
        try {
            int width = activity.getWindow().getDecorView().getWidth();
            int height = activity.getWindow().getDecorView().getHeight();
            if (width <= 0 || height <= 0) throw new IllegalStateException("window not laid out");
            Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            CountDownLatch latch = new CountDownLatch(1);
            int[] result = {PixelCopy.ERROR_UNKNOWN};
            activity.runOnUiThread(() -> {
                try {
                    PixelCopy.request(activity.getWindow(), bitmap, copyResult -> {
                        result[0] = copyResult;
                        latch.countDown();
                    }, new Handler(Looper.getMainLooper()));
                } catch (Throwable error) {
                    Log.w(TAG, "pixel copy failed", error);
                    latch.countDown();
                }
            });
            if (!latch.await(5, TimeUnit.SECONDS)) throw new IllegalStateException("screenshot timeout");
            if (result[0] != PixelCopy.SUCCESS) throw new IllegalStateException("pixel copy " + result[0]);
            String path = saveBitmap(bitmap);
            out.put("ok", true);
            out.put("path", path);
        } catch (Throwable error) {
            out = error(error);
        }
        return out.toString();
    }

    private String saveBitmap(Bitmap bitmap) throws Exception {
        String name = "O11A1_" + System.currentTimeMillis() + ".png";
        if (Build.VERSION.SDK_INT >= 29) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DISPLAY_NAME, name);
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/png");
            values.put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/O11A1");
            Uri uri = activity.getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            if (uri == null) throw new IllegalStateException("media store unavailable");
            try (java.io.OutputStream output = activity.getContentResolver().openOutputStream(uri)) {
                if (output == null) throw new IllegalStateException("media output unavailable");
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, output);
            }
            return uri.toString();
        }
        File directory = new File(activity.getExternalFilesDir(Environment.DIRECTORY_PICTURES), "O11A1");
        if (!directory.exists() && !directory.mkdirs()) throw new IllegalStateException("mkdir failed");
        File file = new File(directory, name);
        try (FileOutputStream output = new FileOutputStream(file)) {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, output);
        }
        return file.getAbsolutePath();
    }

    @JavascriptInterface
    public String previewCached(String bvid, long cid) {
        String key = bvid + ":" + cid;
        PreviewEntry cached = previewUrls.get(key);
        if (cached != null && System.currentTimeMillis() - cached.at < PREVIEW_URL_TTL) {
            return cached.json;
        }
        return "{\"ok\":false,\"missing\":true}";
    }

    @JavascriptInterface
    public String playLow(String bvid, long cid) {
        String key = bvid + ":" + cid;
        PreviewEntry cached = previewUrls.get(key);
        if (cached != null && System.currentTimeMillis() - cached.at < PREVIEW_URL_TTL) {
            return cached.json;
        }
        String value = runExtra(() -> api.playLow(bvid, cid).toString());
        cachePreview(key, value);
        return value;
    }

    @JavascriptInterface
    public void prewarmPreviews(String json) {
        if (json == null || json.isEmpty()) return;
        try {
            JSONArray list = new JSONArray(json);
            for (int index = 0; index < list.length(); index += 1) {
                JSONObject row = list.optJSONObject(index);
                if (row == null) continue;
                String bvid = row.optString("bvid", "");
                long cid = row.optLong("cid", 0);
                if (bvid.isEmpty()) continue;
                String key = bvid + ":" + cid;
                PreviewEntry cached = previewUrls.get(key);
                if (cached != null && System.currentTimeMillis() - cached.at < PREVIEW_URL_TTL) continue;
                if (!previewsLoading.add(key)) continue;
                previewPool.execute(() -> {
                    try {
                        String value = api.playLow(bvid, cid).toString();
                        cachePreview(key, value);
                    } catch (Throwable error) {
                        Log.w(TAG, "preview prewarm failed " + bvid, error);
                    } finally {
                        previewsLoading.remove(key);
                    }
                });
            }
        } catch (Throwable error) {
            Log.w(TAG, "preview prewarm parse failed", error);
        }
    }

    private void cachePreview(String key, String json) {
        if (key == null || json == null) return;
        previewUrls.put(key, new PreviewEntry(json, System.currentTimeMillis()));
        if (previewUrls.size() > 80) {
            long cutoff = System.currentTimeMillis() - PREVIEW_URL_TTL;
            for (Map.Entry<String, PreviewEntry> entry : previewUrls.entrySet()) {
                if (entry.getValue().at < cutoff) previewUrls.remove(entry.getKey());
            }
            while (previewUrls.size() > 80) {
                String oldest = null;
                long oldestAt = Long.MAX_VALUE;
                for (Map.Entry<String, PreviewEntry> entry : previewUrls.entrySet()) {
                    if (entry.getValue().at < oldestAt) {
                        oldestAt = entry.getValue().at;
                        oldest = entry.getKey();
                    }
                }
                if (oldest == null) break;
                previewUrls.remove(oldest);
            }
        }
    }

    @JavascriptInterface
    public String playQuality(String bvid, long cid, int qn) {
        String key = bvid + ":" + cid + ":" + qn;
        PreviewEntry cached = qualityInfos.get(key);
        if (cached != null && System.currentTimeMillis() - cached.at < QUALITY_URL_TTL) {
            return cached.json;
        }
        String value = runExtra(() -> api.playQuality(bvid, cid, qn).toString());
        cacheQuality(key, value);
        return value;
    }

    @JavascriptInterface
    public void prewarmQuality(String bvid, long cid, int qn) {
        String key = bvid + ":" + cid + ":" + qn;
        PreviewEntry cached = qualityInfos.get(key);
        if (cached != null && System.currentTimeMillis() - cached.at < QUALITY_URL_TTL) return;
        if (!qualityLoading.add(key)) return;
        qualityPool.execute(() -> {
            try {
                JSONObject json = api.playQuality(bvid, cid, qn);
                cacheQuality(key, json.toString());
            } catch (Throwable error) {
                Log.w(TAG, "quality prewarm failed " + bvid, error);
            } finally {
                qualityLoading.remove(key);
            }
        });
    }

    private void cacheQuality(String key, String json) {
        if (key == null || json == null) return;
        try {
            JSONObject parsed = new JSONObject(json);
            if (!parsed.optBoolean("ok", false)) return;
        } catch (Throwable ignored) {
            return;
        }
        qualityInfos.put(key, new PreviewEntry(json, System.currentTimeMillis()));
        if (qualityInfos.size() > 48) {
            long cutoff = System.currentTimeMillis() - QUALITY_URL_TTL;
            for (Map.Entry<String, PreviewEntry> entry : qualityInfos.entrySet()) {
                if (entry.getValue().at < cutoff) qualityInfos.remove(entry.getKey());
            }
            while (qualityInfos.size() > 48) {
                String oldest = null;
                long oldestAt = Long.MAX_VALUE;
                for (Map.Entry<String, PreviewEntry> entry : qualityInfos.entrySet()) {
                    if (entry.getValue().at < oldestAt) {
                        oldestAt = entry.getValue().at;
                        oldest = entry.getKey();
                    }
                }
                if (oldest == null) break;
                qualityInfos.remove(oldest);
            }
        }
    }

    @JavascriptInterface
    public String comments(long aid, int page) {
        return runExtra(() -> api.comments(aid, page).toString());
    }

    @JavascriptInterface
    public String danmaku(long cid) {
        return runExtra(() -> api.danmaku(cid).toString());
    }

    @JavascriptInterface
    public String session() {
        JSONObject info = api.session();
        try {
            info.put("cookie", cookies.header());
            info.put("hasSession", cookies.loggedIn());
        } catch (Throwable ignored) {}
        return info.toString();
    }

    @JavascriptInterface
    public String logout() {
        api.logout();
        previewUrls.clear();
        previewsLoading.clear();
        qualityInfos.clear();
        qualityLoading.clear();
        dashInfos.clear();
        dashLoading.clear();
        try {
            CookieManager manager = CookieManager.getInstance();
            manager.removeAllCookies(null);
            manager.flush();
        } catch (Throwable ignored) {}
        JSONObject out = new JSONObject();
        try {
            out.put("ok", true);
        } catch (Throwable ignored) {}
        return out.toString();
    }

    @JavascriptInterface
    public void setBrightness(int percent) {
        activity.runOnUiThread(() -> {
            try {
                android.view.WindowManager.LayoutParams lp = activity.getWindow().getAttributes();
                lp.screenBrightness = Math.max(0.02f, Math.min(1f, percent / 100f));
                activity.getWindow().setAttributes(lp);
            } catch (Throwable error) {
                Log.w(TAG, "brightness failed", error);
            }
        });
    }

    @JavascriptInterface
    public void restoreBrightness() {
        activity.runOnUiThread(() -> {
            try {
                android.view.WindowManager.LayoutParams lp = activity.getWindow().getAttributes();
                lp.screenBrightness = android.view.WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE;
                activity.getWindow().setAttributes(lp);
            } catch (Throwable error) {
                Log.w(TAG, "brightness restore failed", error);
            }
        });
    }

    @JavascriptInterface
    public int brightness() {
        try {
            android.view.WindowManager.LayoutParams lp = activity.getWindow().getAttributes();
            if (lp.screenBrightness >= 0f) {
                return Math.round(lp.screenBrightness * 100f);
            }
            int value = android.provider.Settings.System.getInt(
                activity.getContentResolver(),
                android.provider.Settings.System.SCREEN_BRIGHTNESS,
                128
            );
            return Math.round(value * 100f / 255f);
        } catch (Throwable error) {
            return 100;
        }
    }

    @JavascriptInterface
    public int volume() {
        try {
            AudioManager audio = (AudioManager) activity.getSystemService(Context.AUDIO_SERVICE);
            if (audio == null) return 0;
            int max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
            int current = audio.getStreamVolume(AudioManager.STREAM_MUSIC);
            return max > 0 ? Math.round(current * 100f / max) : 0;
        } catch (Throwable error) {
            return 0;
        }
    }

    @JavascriptInterface
    public void setVolume(int percent) {
        activity.runOnUiThread(() -> {
            try {
                AudioManager audio = (AudioManager) activity.getSystemService(Context.AUDIO_SERVICE);
                if (audio == null) return;
                int max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
                int index = Math.round(Math.max(0, Math.min(100, percent)) / 100f * max);
                audio.setStreamVolume(AudioManager.STREAM_MUSIC, index, 0);
            } catch (Throwable error) {
                Log.w(TAG, "volume failed", error);
            }
        });
    }

    @JavascriptInterface
    public void setOrientation(String mode) {
        activity.runOnUiThread(() -> {
            if ("landscape-left".equals(mode)) {
                activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
            } else if ("landscape-right".equals(mode)) {
                activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE);
            } else {
                activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
            }
        });
    }

    @JavascriptInterface
    public String proxyInfo() {
        JSONObject out = new JSONObject();
        try {
            out.put("ok", true);
            out.put("port", 0);
            out.put("disabled", true);
        } catch (Throwable ignored) {}
        return out.toString();
    }

    @JavascriptInterface
    public void log(String message) {
        Log.i(TAG, message == null ? "null" : message);
    }

    @JavascriptInterface
    public String memberCenter() {
        return runExtra(() -> extras.memberCenter().toString());
    }

    @JavascriptInterface
    public String dash(String bvid, long cid, int qn) {
        String key = bvid + ":" + cid + ":" + qn;
        PreviewEntry cached = dashInfos.get(key);
        if (cached != null && System.currentTimeMillis() - cached.at < QUALITY_URL_TTL) {
            return cached.json;
        }
        String value = runExtra(() -> extras.dash(bvid, cid, qn).toString(), 25);
        cacheDash(key, value);
        return value;
    }

    @JavascriptInterface
    public void prewarmDash(String bvid, long cid, int qn) {
        String key = bvid + ":" + cid + ":" + qn;
        PreviewEntry cached = dashInfos.get(key);
        if (cached != null && System.currentTimeMillis() - cached.at < QUALITY_URL_TTL) return;
        if (!dashLoading.add(key)) return;
        qualityPool.execute(() -> {
            try {
                String value = extras.dash(bvid, cid, qn).toString();
                cacheDash(key, value);
            } catch (Throwable error) {
                Log.w(TAG, "dash prewarm failed " + bvid, error);
            } finally {
                dashLoading.remove(key);
            }
        });
    }

    private void cacheDash(String key, String json) {
        if (key == null || json == null) return;
        try {
            JSONObject parsed = new JSONObject(json);
            if (!parsed.optBoolean("ok", false)) return;
        } catch (Throwable ignored) {
            return;
        }
        dashInfos.put(key, new PreviewEntry(json, System.currentTimeMillis()));
        if (dashInfos.size() > 24) {
            long cutoff = System.currentTimeMillis() - QUALITY_URL_TTL;
            for (Map.Entry<String, PreviewEntry> entry : dashInfos.entrySet()) {
                if (entry.getValue().at < cutoff) dashInfos.remove(entry.getKey());
            }
            while (dashInfos.size() > 24) {
                String oldest = null;
                long oldestAt = Long.MAX_VALUE;
                for (Map.Entry<String, PreviewEntry> entry : dashInfos.entrySet()) {
                    if (entry.getValue().at < oldestAt) {
                        oldestAt = entry.getValue().at;
                        oldest = entry.getKey();
                    }
                }
                if (oldest == null) break;
                dashInfos.remove(oldest);
            }
        }
    }

    @JavascriptInterface
    public String aiChat(String endpoint, String apiKey, String model, String prompt) {
        return runExtra(() -> extras.aiChat(endpoint, apiKey, model, prompt).toString(), 75);
    }

    private String runExtra(Callable<String> call) {
        return runExtra(call, 12);
    }

    private String runExtra(Callable<String> call, int seconds) {
        FutureTask<String> task = new FutureTask<>(call);
        Thread worker = new Thread(task, "o11a1-extra");
        worker.setDaemon(true);
        worker.start();
        try {
            return task.get(seconds, TimeUnit.SECONDS);
        } catch (Throwable error) {
            task.cancel(true);
            Log.w(TAG, "bridge call timed out", error);
            return "{\"ok\":false,\"error\":\"请求超时\"}";
        }
    }

    private static JSONObject error(Throwable error) {
        JSONObject out = new JSONObject();
        try {
            out.put("ok", false);
            out.put("error", error == null ? "unknown" : (error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage()));
        } catch (Throwable ignored) {}
        return out;
    }
}
