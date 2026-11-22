package com.o11a1.videotest;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/** Full-screen V2 UI (bundled web design) with a native Bilibili bridge. */
public final class MainActivity extends Activity {
    private static final String TAG = "O11A1App";
    private WebView webView;
    private StreamProxy proxy;
    private CookieStore cookieStore;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        getWindow().setBackgroundDrawable(
            new android.graphics.drawable.ColorDrawable(Color.rgb(250, 250, 252)));
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        hideSystemUi();
        if (Build.VERSION.SDK_INT >= 28) {
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }

        CookieStore cookies = new CookieStore(this);
        cookieStore = cookies;
        try {
            proxy = new StreamProxy(cookies, this);
        } catch (Throwable error) {
            Log.e(TAG, "stream proxy failed", error);
        }
        BiliApi api = new BiliApi(cookies, proxy);
        WebAppBridge bridge = new WebAppBridge(this, api, proxy, cookies);

        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(250, 250, 252));
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

        setContentView(webView);
        webView.loadUrl("file:///android_asset/web/index.html?v=101");
        Thread warm = new Thread(() -> cookies.ensureBuvid(), "o11a1-buvid");
        warm.setDaemon(true);
        warm.start();
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
        if (hasFocus) hideSystemUi();
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
        if (proxy != null) proxy.stop();
        if (webView != null) {
            webView.removeJavascriptInterface("O11A1Native");
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
