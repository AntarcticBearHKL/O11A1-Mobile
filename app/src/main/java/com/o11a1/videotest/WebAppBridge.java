package com.o11a1.videotest;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentValues;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.util.Log;
import android.view.PixelCopy;
import android.webkit.JavascriptInterface;

import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.FutureTask;
import java.util.concurrent.TimeUnit;

/** JavaScript bridge exposed as window.O11A1Native. */
final class WebAppBridge {
    private static final String TAG = "O11A1Bridge";
    private final Activity activity;
    private final BiliApi api;
    private final BiliExtras extras;
    private final StreamProxy proxy;
    private final CookieStore cookies;

    WebAppBridge(Activity activity, BiliApi api, StreamProxy proxy, CookieStore cookies) {
        this.activity = activity;
        this.api = api;
        this.extras = new BiliExtras(cookies, proxy, api);
        this.proxy = proxy;
        this.cookies = cookies;
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
        return api.popular(page, ps <= 0 ? 20 : ps).toString();
    }

    @JavascriptInterface
    public String search(String keyword, int page) {
        return api.search(keyword, page).toString();
    }

    @JavascriptInterface
    public String play(String bvid, long cid) {
        return api.play(bvid, cid).toString();
    }

    @JavascriptInterface
    public String account() {
        return extras.account().toString();
    }

    @JavascriptInterface
    public String favorites(int page) {
        return extras.favorites(page).toString();
    }

    @JavascriptInterface
    public String history(int page, String cursor) {
        return extras.history(page, cursor).toString();
    }

    @JavascriptInterface
    public String following(int page) {
        return extras.following(page).toString();
    }

    @JavascriptInterface
    public String dynamicFeed(int page, String filter) {
        return extras.dynamicFeed(page, filter).toString();
    }

    @JavascriptInterface
    public String messages(int page, String filter) {
        return extras.messages(page, filter).toString();
    }

    @JavascriptInterface
    public String ranking(int page) {
        return extras.ranking(page).toString();
    }

    @JavascriptInterface
    public String bangumi(int page, int seasonType) {
        return extras.bangumi(page, seasonType).toString();
    }

    @JavascriptInterface
    public String season(long seasonId) {
        return extras.season(seasonId).toString();
    }

    @JavascriptInterface
    public String playPgc(long epId, String bvid, long cid, int qn) {
        return extras.playPgc(epId, bvid, cid, qn).toString();
    }

    @JavascriptInterface
    public String live(int page) {
        return extras.live(page).toString();
    }

    @JavascriptInterface
    public String liveRoom(long roomId) {
        FutureTask<String> task = new FutureTask<>(() -> extras.liveRoom(roomId).toString());
        Thread worker = new Thread(task, "o11a1-live-room");
        worker.setDaemon(true);
        worker.start();
        try {
            return task.get(12, TimeUnit.SECONDS);
        } catch (Throwable error) {
            task.cancel(true);
            JSONObject out = new JSONObject();
            try {
                out.put("ok", false);
                out.put("error", "直播接口超时");
            } catch (Throwable ignored) {}
            return out.toString();
        }
    }

    @JavascriptInterface
    public String zone(int rid, int page) {
        return extras.zone(rid, page).toString();
    }

    @JavascriptInterface
    public String videoInfo(String bvid) {
        return extras.videoInfo(bvid).toString();
    }

    @JavascriptInterface
    public String like(long aid, boolean on) {
        return extras.like(aid, on).toString();
    }

    @JavascriptInterface
    public String coin(long aid, int count, boolean likeAlso) {
        return extras.coin(aid, count, likeAlso).toString();
    }

    @JavascriptInterface
    public String favorite(long aid, boolean on) {
        return extras.favorite(aid, on).toString();
    }

    @JavascriptInterface
    public String follow(long mid, boolean on) {
        return extras.follow(mid, on).toString();
    }

    @JavascriptInterface
    public String sendComment(long aid, String message) {
        return extras.sendComment(aid, message).toString();
    }

    @JavascriptInterface
    public String sendDanmaku(long cid, String message, long progressMs) {
        return extras.sendDanmaku(cid, message, progressMs).toString();
    }

    @JavascriptInterface
    public String comments(long aid, int page, int sort) {
        return extras.comments(aid, page, sort).toString();
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
    public String playLow(String bvid, long cid) {
        return api.playLow(bvid, cid).toString();
    }

    @JavascriptInterface
    public String playQuality(String bvid, long cid, int qn) {
        return api.playQuality(bvid, cid, qn).toString();
    }

    @JavascriptInterface
    public String comments(long aid, int page) {
        return api.comments(aid, page).toString();
    }

    @JavascriptInterface
    public String danmaku(long cid) {
        return api.danmaku(cid).toString();
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
        JSONObject out = new JSONObject();
        try {
            out.put("ok", true);
        } catch (Throwable ignored) {}
        return out.toString();
    }

    @JavascriptInterface
    public String qrGenerate() {
        JSONObject out = new JSONObject();
        try {
            String raw = cookies.request("https://passport.bilibili.com/x/passport-login/web/qrcode/generate", null, null);
            JSONObject json = new JSONObject(raw);
            JSONObject data = json.optJSONObject("data");
            if (json.optInt("code") != 0 || data == null) throw new IllegalStateException("qr code " + json.optInt("code"));
            String url = data.optString("url", "");
            String key = data.optString("qrcode_key", "");
            out.put("ok", true);
            out.put("key", key);
            out.put("url", url);
            out.put("image", QrUtil.pngBase64(url, 512));
        } catch (Throwable error) {
            Log.w(TAG, "qr generate failed", error);
            out = error(error);
        }
        return out.toString();
    }

    @JavascriptInterface
    public String qrPoll(String key) {
        JSONObject out = new JSONObject();
        try {
            String raw = cookies.request("https://passport.bilibili.com/x/passport-login/web/qrcode/poll?qrcode_key=" + key, null, null);
            JSONObject json = new JSONObject(raw);
            JSONObject data = json.optJSONObject("data");
            int code = data == null ? -1 : data.optInt("code", -1);
            out.put("ok", true);
            out.put("code", code);
            out.put("message", data == null ? "" : data.optString("message", ""));
            out.put("loggedIn", code == 0 || cookies.loggedIn());
        } catch (Throwable error) {
            out = error(error);
        }
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
    public void setOrientation(String mode) {
        activity.runOnUiThread(() -> {
            if ("landscape-left".equals(mode)) activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
            else if ("landscape-right".equals(mode)) activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE);
            else if ("portrait".equals(mode)) activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
            else activity.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR);
        });
    }

    @JavascriptInterface
    public String proxyInfo() {
        JSONObject out = new JSONObject();
        try {
            out.put("ok", true);
            out.put("port", proxy.port());
        } catch (Throwable ignored) {}
        return out.toString();
    }

    @JavascriptInterface
    public void log(String message) {
        Log.i(TAG, message == null ? "null" : message);
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
