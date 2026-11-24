package com.o11a1.videotest;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.Display;
import android.view.View;
import android.view.WindowManager;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

/** Full-screen V2 UI (bundled web design) with a native Bilibili bridge. */
public final class MainActivity extends Activity {
    private static final String TAG = "O11A1App";
    private WebView webView;
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
        settings.setUserAgentString(settings.getUserAgentString() + " O11A1/0.2");

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

        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.TRANSPARENT);
        root.addView(nativePlayers.backgroundView(), new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT));
        root.addView(webView, new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT));
        root.addView(nativePlayers.overlayView(), new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT));
        setContentView(root);
        webView.loadUrl("file:///android_asset/web/index.html?v=285");
        Thread warm = new Thread(() -> cookies.ensureBuvid(), "o11a1-buvid");
        warm.setDaemon(true);
        warm.start();
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
    protected void onResume() {
        super.onResume();
        if (cookieStore != null) cookieStore.reload();
        applyMaxRefreshRate();
        hideSystemUi();
        if (webView != null) webView.onResume();
    }

    @Override
    protected void onPause() {
        if (webView != null) webView.onPause();
        super.onPause();
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
