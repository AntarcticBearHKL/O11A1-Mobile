package com.o11a1.videotest;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.util.Log;
import android.webkit.JavascriptInterface;

import org.json.JSONObject;

/** JavaScript bridge exposed as window.O11A1Native. */
final class WebAppBridge {
    private static final String TAG = "O11A1Bridge";
    private final Activity activity;
    private final BiliApi api;
    private final StreamProxy proxy;
    private final CookieStore cookies;

    WebAppBridge(Activity activity, BiliApi api, StreamProxy proxy, CookieStore cookies) {
        this.activity = activity;
        this.api = api;
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
