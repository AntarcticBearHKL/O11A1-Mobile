package com.o11a1.videotest;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

/** In-app Bilibili SMS login page. Shares the WebView cookie jar and imports SESSDATA on success. */
public final class WebLoginActivity extends Activity {
    private static final String UA = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36";
    private static final String LOGIN_URL = "https://passport.bilibili.com/login";
    private WebView webView;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private boolean finished = false;
    private String initialSess = "";

    private final Runnable cookiePoll = new Runnable() {
        @Override
        public void run() {
            if (finished) return;
            String cookie = CookieManager.getInstance().getCookie("https://www.bilibili.com");
            String sess = cookieValue(cookie, "SESSDATA");
            if (!sess.isEmpty() && !sess.equals(initialSess) && cookie.contains("bili_jct=")) {
                complete(cookie);
                return;
            }
            handler.postDelayed(this, 1200);
        }
    };

    private static String cookieValue(String header, String name) {
        if (header == null) return "";
        for (String part : header.split(";")) {
            String[] pair = part.trim().split("=", 2);
            if (pair.length == 2 && pair[0].trim().equals(name)) return pair[1].trim();
        }
        return "";
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.parseColor("#0B0D12"));
        getWindow().setNavigationBarColor(Color.parseColor("#0B0D12"));

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.parseColor("#0B0D12"));

        LinearLayout bar = new LinearLayout(this);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setPadding(18, 14, 12, 14);
        bar.setBackgroundColor(Color.parseColor("#141820"));

        TextView title = new TextView(this);
        title.setText("B 站短信验证码登录");
        title.setTextColor(Color.parseColor("#F2F5FA"));
        title.setTextSize(16);
        title.setSingleLine(true);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        bar.addView(title, titleParams);

        Button close = new Button(this);
        close.setText("关闭");
        close.setAllCaps(false);
        close.setTextColor(Color.parseColor("#9FB3CC"));
        close.setBackgroundColor(Color.TRANSPARENT);
        close.setOnClickListener(v -> finish());
        bar.addView(close);

        root.addView(bar, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setUserAgentString(UA);
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);
        CookieManager manager = CookieManager.getInstance();
        manager.setAcceptCookie(true);
        manager.setAcceptThirdPartyCookies(webView, true);
        initialSess = cookieValue(manager.getCookie("https://www.bilibili.com"), "SESSDATA");

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                injectSmsTab();
                handler.removeCallbacks(cookiePoll);
                handler.postDelayed(cookiePoll, 800);
            }
        });
        root.addView(webView, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));
        setContentView(root);
        webView.loadUrl(LOGIN_URL);
        handler.postDelayed(cookiePoll, 1500);
    }

    private void injectSmsTab() {
        String js = "(function(){"
            + "function clickSms(){"
            + "var all=document.querySelectorAll('div,span,button,a,p');"
            + "for(var i=0;i<all.length;i++){"
            + "var t=(all[i].textContent||'').trim();"
            + "if(t==='短信登录'||t==='短信验证码登录'||t==='验证码登录'){"
            + "all[i].click();return true;}}return false;}"
            + "if(!clickSms()){var n=0;var timer=setInterval(function(){n++;if(clickSms()||n>24)clearInterval(timer);},400);}"
            + "})();";
        webView.evaluateJavascript(js, null);
    }

    private void complete(String cookie) {
        if (finished) return;
        finished = true;
        handler.removeCallbacks(cookiePoll);
        CookieManager.getInstance().flush();
        new CookieStore(this).importHeader(cookie);
        setResult(RESULT_OK, new Intent().putExtra("cookies", cookie));
        finish();
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onDestroy() {
        handler.removeCallbacks(cookiePoll);
        if (webView != null) {
            webView.stopLoading();
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
