package com.o11a1.videotest;

import android.app.Activity;
import android.app.Dialog;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/** Small isolated WebView used only for Bilibili's Geetest challenge. */
final class GeetestDialog {
    private static final String TAG = "O11A1Geetest";
    private static final String BASE_URL = "https://passport.bilibili.com/login";
    private static final String UA = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36";

    static final class Result {
        boolean ok;
        boolean cancelled;
        String challenge = "";
        String validate = "";
        String seccode = "";
        String error = "";
    }

    static Result show(Activity activity, String gt, String challenge) {
        Result result = new Result();
        CountDownLatch latch = new CountDownLatch(1);
        AtomicReference<Result> finished = new AtomicReference<>();
        AtomicReference<Dialog> dialogRef = new AtomicReference<>();
        Handler main = new Handler(Looper.getMainLooper());
        main.post(() -> {
            try {
                Dialog dialog = new Dialog(activity);
                dialogRef.set(dialog);
                dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
                dialog.setCanceledOnTouchOutside(false);
                WebView web = new WebView(activity);
                web.setBackgroundColor(Color.parseColor("#0B0D12"));
                WebSettings settings = web.getSettings();
                settings.setJavaScriptEnabled(true);
                settings.setDomStorageEnabled(true);
                settings.setDatabaseEnabled(true);
                settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
                settings.setUserAgentString(UA);
                web.setWebChromeClient(new WebChromeClient());
                web.setWebViewClient(new WebViewClient());
                web.addJavascriptInterface(new Object() {
                    @JavascriptInterface
                    public void complete(String ch, String validate, String seccode) {
                        main.post(() -> {
                            if (finished.get() != null) return;
                            Result value = new Result();
                            value.ok = true;
                            value.challenge = ch == null ? "" : ch;
                            value.validate = validate == null ? "" : validate;
                            value.seccode = seccode == null ? "" : seccode;
                            finished.set(value);
                            dialog.dismiss();
                            latch.countDown();
                        });
                    }

                    @JavascriptInterface
                    public void cancel() {
                        main.post(() -> {
                            if (finished.get() != null) return;
                            Result value = new Result();
                            value.cancelled = true;
                            finished.set(value);
                            dialog.dismiss();
                            latch.countDown();
                        });
                    }

                    @JavascriptInterface
                    public void log(String message) {
                        Log.i(TAG, String.valueOf(message));
                    }
                }, "O11A1Geetest");
                dialog.setOnCancelListener(d -> {
                    if (finished.get() != null) return;
                    Result value = new Result();
                    value.cancelled = true;
                    finished.set(value);
                    latch.countDown();
                });
                dialog.setOnDismissListener(d -> {
                    if (finished.get() != null) return;
                    Result value = new Result();
                    value.cancelled = true;
                    finished.set(value);
                    latch.countDown();
                });
                dialog.setContentView(web, new ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
                Window window = dialog.getWindow();
                if (window != null) {
                    window.setBackgroundDrawable(new ColorDrawable(Color.parseColor("#0B0D12")));
                    window.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT);
                    window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
                }
                dialog.show();
                String html = loadAsset(activity, "geetest.html")
                    .replace("__GT__", escapeJs(gt))
                    .replace("__CHALLENGE__", escapeJs(challenge));
                Log.i(TAG, "loading captcha html len=" + html.length());
                web.loadDataWithBaseURL(BASE_URL, html, "text/html", "utf-8", null);
                Log.i(TAG, "captcha load requested");
            } catch (Throwable error) {
                Log.w(TAG, "dialog failed", error);
                Result value = new Result();
                value.error = "验证组件启动失败：" + error;
                finished.set(value);
                latch.countDown();
            }
        });
        try {
            if (!latch.await(15, TimeUnit.MINUTES)) {
                result.error = "验证超时";
                result.cancelled = true;
                main.post(() -> {
                    Dialog dialog = dialogRef.get();
                    if (dialog != null) {
                        try { dialog.dismiss(); } catch (Throwable ignored) {}
                    }
                });
                return result;
            }
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            result.error = "验证被中断";
            return result;
        }
        Result value = finished.get();
        return value == null ? result : value;
    }

    private static String loadAsset(Activity activity, String name) {
        try (InputStream in = activity.getAssets().open(name)) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) >= 0) out.write(buffer, 0, read);
            return out.toString(StandardCharsets.UTF_8.name());
        } catch (Throwable error) {
            Log.w(TAG, "asset read failed", error);
            return "<html><body style='background:#0b0d12;color:#fff;font-family:sans-serif;padding:24px'>验证页面加载失败</body></html>";
        }
    }

    private static String escapeJs(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "");
    }
}
