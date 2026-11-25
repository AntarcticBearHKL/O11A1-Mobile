package com.o11a1.videotest;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.PictureInPictureParams;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.Rational;
import android.view.Display;
import android.view.View;
import android.view.WindowManager;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import org.json.JSONObject;

/** Full-screen V2 UI (bundled web design) with a native Bilibili bridge. */
public final class MainActivity extends Activity {
    private static final String TAG = "O11A1App";
    private WebView webView;
    private FrameLayout root;
    private boolean pipExitPending;
    private boolean isResumed;
    private CookieStore cookieStore;
    private NativePlayerHost nativePlayers;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        getWindow().setBackgroundDrawable(
            new android.graphics.drawable.ColorDrawable(Color.TRANSPARENT));
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        applyMaxRefreshRate();
        hideSystemUi();
        getWindow().setFormat(PixelFormat.TRANSLUCENT);
        if (Build.VERSION.SDK_INT >= 28) {
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }

        CookieStore cookies = new CookieStore(this);
        cookieStore = cookies;
        BiliApi api = new BiliApi(cookies);
        WebAppBridge bridge = new WebAppBridge(this, api, cookies);

        webView = new WebView(this);
        bridge.setWebView(webView);
        nativePlayers = new NativePlayerHost(this, cookies, js -> {
            WebView view = webView;
            if (view != null) {
                view.post(() -> {
                    try {
                        view.evaluateJavascript(js, null);
                    } catch (Throwable ignored) {}
                });
            }
        });
        bridge.setNativePlayers(nativePlayers);
        webView.setBackgroundColor(Color.TRANSPARENT);
        webView.setLongClickable(false);
        webView.setHapticFeedbackEnabled(false);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);
        settings.setSupportZoom(false);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        settings.setCacheMode(WebSettings.LOAD_DEFAULT);
        String appVersion = "0.0.0";
        try {
            appVersion = getPackageManager().getPackageInfo(getPackageName(), 0).versionName;
        } catch (Throwable ignored) {}
        settings.setUserAgentString(settings.getUserAgentString() + " O11A1/" + appVersion);

        webView.addJavascriptInterface(bridge, "O11A1Native");
        WebView.setWebContentsDebuggingEnabled(true);
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                Log.i(TAG, "page finished " + url);
            }

            @Override
            public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
                Log.w(TAG, "web error " + errorCode + " " + description + " " + failingUrl);
            }
        });
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onConsoleMessage(ConsoleMessage message) {
                Log.i(TAG, "console " + message.message() + " @" + message.lineNumber());
                return true;
            }
        });

        FrameLayout stage = new FrameLayout(this);
        root = stage;
        stage.setBackgroundColor(Color.TRANSPARENT);
        stage.addView(nativePlayers.backgroundView(), new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT));
        stage.addView(webView, new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT));
        stage.addView(nativePlayers.overlayView(), new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT));
        setContentView(stage);
        webView.loadUrl("file:///android_asset/web/index.html?v=" + appVersion);
        Thread warm = new Thread(() -> cookies.ensureBuvid(), "o11a1-buvid");
        warm.setDaemon(true);
        warm.start();
    }

    String enterPipFromPlayer(String slotId) {
        JSONObject out = new JSONObject();
        try {
            if (Build.VERSION.SDK_INT < 26) {
                out.put("ok", false);
                return out.toString();
            }
            if (isInPictureInPictureMode()) {
                out.put("ok", true);
                return out.toString();
            }
            NativePlayerHost.PipInfo info = nativePlayers.pipInfo(slotId);
            Log.i(TAG, "enterPiP info=" + (info != null)
                + " resumed=" + isResumed
                + " inPip=" + isInPictureInPictureMode());
            if (info == null || !info.playing) {
                out.put("ok", false);
                return out.toString();
            }
            int width = Math.max(1, info.width);
            int height = Math.max(1, info.height);
            double ratio = (double) width / height;
            if (ratio > 2.39) width = (int) Math.round(height * 2.39);
            else if (ratio < 1.0 / 2.39) height = (int) Math.round(width * 2.39);

            /* Full-bleed the native video before the system captures the
               transition, so the PiP window never shows the feed UI. */
            nativePlayers.setPipMode(true);
            if (webView != null) webView.setVisibility(View.INVISIBLE);
            if (root != null) root.setBackgroundColor(Color.BLACK);

            PictureInPictureParams.Builder builder = new PictureInPictureParams.Builder()
                .setAspectRatio(new Rational(width, height))
                .setSourceRectHint(info.rect);
            if (Build.VERSION.SDK_INT >= 31) builder.setSeamlessResizeEnabled(true);
            boolean entered = enterPictureInPictureMode(builder.build());
            Log.i(TAG, "enterPictureInPictureMode result=" + entered);
            if (!entered) {
                nativePlayers.setPipMode(false);
                if (webView != null) webView.setVisibility(View.VISIBLE);
                if (root != null) root.setBackgroundColor(Color.TRANSPARENT);
            }
            out.put("ok", entered);
        } catch (Throwable error) {
            Log.w(TAG, "enter PiP failed", error);
            try { out.put("ok", false); } catch (Throwable ignored) {}
            nativePlayers.setPipMode(false);
            if (webView != null) webView.setVisibility(View.VISIBLE);
            if (root != null) root.setBackgroundColor(Color.TRANSPARENT);
        }
        return out.toString();
    }

    private void notifyPip(String event, String reason) {
        WebView view = webView;
        if (view == null) return;
        String javascript;
        if ("start".equals(event)) {
            javascript = "window.O11A1Pip&&O11A1Pip.onStart&&O11A1Pip.onStart()";
        } else if ("fail".equals(event)) {
            javascript = "window.O11A1Pip&&O11A1Pip.onFail&&O11A1Pip.onFail()";
        } else {
            javascript = "window.O11A1Pip&&O11A1Pip.onExit&&O11A1Pip.onExit('" + reason + "')";
        }
        view.post(() -> {
            try { view.evaluateJavascript(javascript, null); } catch (Throwable ignored) {}
        });
    }

    @Override
    public void onPictureInPictureModeChanged(boolean inPip, Configuration configuration) {
        super.onPictureInPictureModeChanged(inPip, configuration);
        if (inPip) {
            pipExitPending = false;
            if (webView != null) webView.setVisibility(View.INVISIBLE);
            if (root != null) root.setBackgroundColor(Color.BLACK);
            nativePlayers.setPipMode(true);
            notifyPip("start", null);
            return;
        }
        if (webView != null) webView.setVisibility(View.VISIBLE);
        if (root != null) root.setBackgroundColor(Color.TRANSPARENT);
        nativePlayers.setPipMode(false);
        /* Expand brings the activity back through onResume; dismissing the PiP
           window stops it through onStop. Decide after the transition. */
        pipExitPending = true;
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            if (!pipExitPending) return;
            pipExitPending = false;
            notifyPip("exit", isResumed ? "expand" : "close");
        }, 400);
    }

    private void applyMaxRefreshRate() {
        try {
            Display display = getWindowManager().getDefaultDisplay();
            Display.Mode current = display.getMode();
            Display.Mode best = null;
            float bestRate = 0f;
            if (Build.VERSION.SDK_INT >= 23) {
                for (Display.Mode mode : display.getSupportedModes()) {
                    if (mode.getPhysicalWidth() != current.getPhysicalWidth()
                        || mode.getPhysicalHeight() != current.getPhysicalHeight()) {
                        continue;
                    }
                    float rate = mode.getRefreshRate();
                    if (rate <= 120.5f && rate > bestRate + 0.05f) {
                        bestRate = rate;
                        best = mode;
                    }
                }
            }
            WindowManager.LayoutParams attrs = getWindow().getAttributes();
            if (best != null) {
                if (attrs.preferredDisplayModeId != best.getModeId()) {
                    attrs.preferredDisplayModeId = best.getModeId();
                }
                attrs.preferredRefreshRate = best.getRefreshRate();
            } else {
                attrs.preferredRefreshRate = Math.min(120f, display.getRefreshRate());
            }
            getWindow().setAttributes(attrs);
        } catch (Throwable error) {
            Log.w(TAG, "max refresh rate unavailable", error);
        }
    }

    private void hideSystemUi() {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            applyMaxRefreshRate();
            hideSystemUi();
        }
    }

    @Override
    public void onBackPressed() {
        if (webView != null) {
            webView.evaluateJavascript(
                "window.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape',code:'Escape',bubbles:true}));", null);
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onUserLeaveHint() {
        super.onUserLeaveHint();
        if (Build.VERSION.SDK_INT >= 26 && nativePlayers != null && nativePlayers.isMainPlaying()) {
            enterPipFromPlayer("main");
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        isResumed = true;
        if (cookieStore != null) cookieStore.reload();
        applyMaxRefreshRate();
        hideSystemUi();
        if (webView != null) webView.onResume();
        if (pipExitPending) {
            pipExitPending = false;
            notifyPip("exit", "expand");
        }
    }

    @Override
    protected void onPause() {
        isResumed = false;
        if (webView != null) webView.onPause();
        super.onPause();
    }

    @Override
    protected void onStop() {
        if (pipExitPending) {
            pipExitPending = false;
            nativePlayers.stopMain();
            notifyPip("exit", "close");
        }
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        if (nativePlayers != null) nativePlayers.releaseAll();
        if (webView != null) {
            webView.removeJavascriptInterface("O11A1Native");
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
