package com.o11a1.videotest;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.Window;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.common.BitMatrix;

import org.json.JSONObject;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class LoginDialog {
    interface OnLogin {
        void onLogin();
    }

    private final Dialog dialog;
    private final BiliApi api;
    private final ImageView qrView;
    private final TextView status;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final OnLogin onLogin;
    private String key = "";
    private boolean polling = false;
    private boolean stopped = false;

    static void show(Context context, BiliApi api, OnLogin onLogin) {
        new LoginDialog(context, api, onLogin).start();
    }

    private LoginDialog(Context context, BiliApi api, OnLogin onLogin) {
        this.api = api;
        this.onLogin = onLogin;
        dialog = new Dialog(context);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawable(
                new android.graphics.drawable.ColorDrawable(Color.TRANSPARENT));
        }

        LinearLayout root = new LinearLayout(context);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER_HORIZONTAL);
        root.setPadding(NativeTheme.dp(context, 24), NativeTheme.dp(context, 24),
            NativeTheme.dp(context, 24), NativeTheme.dp(context, 20));
        root.setBackground(NativeTheme.rounded(
            NativeTheme.isDark(context) ? 0xFF141414 : 0xFFFFFFFF,
            NativeTheme.dp(context, 20)));

        TextView title = new TextView(context);
        title.setText("扫码登录 B 站");
        title.setTextColor(NativeTheme.foreground(context));
        title.setTextSize(18);
        title.setTypeface(NativeTheme.titleTypeface());
        title.setGravity(Gravity.CENTER);
        root.addView(title);

        TextView hint = new TextView(context);
        hint.setText("用 B 站手机客户端扫码\n登录后同步关注、收藏和动态");
        hint.setTextColor(NativeTheme.secondary(context));
        hint.setTextSize(12);
        hint.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams hintParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        hintParams.topMargin = NativeTheme.dp(context, 6);
        hintParams.bottomMargin = NativeTheme.dp(context, 14);
        root.addView(hint, hintParams);

        qrView = new ImageView(context);
        qrView.setBackgroundColor(Color.WHITE);
        qrView.setPadding(NativeTheme.dp(context, 8), NativeTheme.dp(context, 8),
            NativeTheme.dp(context, 8), NativeTheme.dp(context, 8));
        LinearLayout.LayoutParams qrParams = new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 240), NativeTheme.dp(context, 240));
        qrParams.gravity = Gravity.CENTER_HORIZONTAL;
        root.addView(qrView, qrParams);

        status = new TextView(context);
        status.setText("正在生成二维码…");
        status.setTextColor(NativeTheme.secondary(context));
        status.setTextSize(13);
        status.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams statusParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        statusParams.topMargin = NativeTheme.dp(context, 12);
        root.addView(status, statusParams);

        TextView cancel = new TextView(context);
        cancel.setText("取消");
        cancel.setTextColor(NativeTheme.ACCENT);
        cancel.setTextSize(14);
        cancel.setGravity(Gravity.CENTER);
        cancel.setPadding(0, NativeTheme.dp(context, 14), 0, 0);
        cancel.setOnClickListener(v -> dismiss());
        root.addView(cancel);

        dialog.setContentView(root);
        dialog.setOnDismissListener(d -> stop());
    }

    private void start() {
        dialog.show();
        generate();
    }

    private void generate() {
        if (stopped) return;
        status.setText("正在生成二维码…");
        pool.execute(() -> {
            JSONObject result = api.qrGenerate();
            main.post(() -> {
                if (stopped) return;
                if (result == null || !result.optBoolean("ok", false)) {
                    status.setText("二维码生成失败，请重试");
                    return;
                }
                key = result.optString("key", "");
                String url = result.optString("url", "");
                Bitmap bitmap = qrBitmap(url, 640);
                if (bitmap != null) qrView.setImageBitmap(bitmap);
                status.setText("等待扫码");
                poll();
            });
        });
    }

    private void poll() {
        if (stopped || polling || key.isEmpty()) return;
        polling = true;
        pool.execute(() -> {
            JSONObject result = api.qrPoll(key);
            main.post(() -> {
                polling = false;
                if (stopped) return;
                if (result == null) {
                    main.postDelayed(this::poll, 1500);
                    return;
                }
                int state = result.optInt("state", -1);
                if (state == 0) {
                    status.setText("登录成功");
                    if (onLogin != null) onLogin.onLogin();
                    main.postDelayed(this::dismiss, 500);
                    return;
                }
                if (state == 86101) {
                    status.setText("等待扫码");
                } else if (state == 86090) {
                    status.setText("已扫码，请在手机上确认");
                } else if (state == 86038) {
                    status.setText("二维码已过期，正在刷新");
                    key = "";
                    main.postDelayed(this::generate, 400);
                    return;
                } else {
                    status.setText(result.optString("message", "等待扫码"));
                }
                main.postDelayed(this::poll, 1500);
            });
        });
    }

    private static Bitmap qrBitmap(String value, int size) {
        if (value == null || value.isEmpty()) return null;
        try {
            BitMatrix matrix = new MultiFormatWriter().encode(value, BarcodeFormat.QR_CODE, size, size);
            int[] pixels = new int[size * size];
            for (int y = 0; y < size; y++) {
                for (int x = 0; x < size; x++) {
                    pixels[y * size + x] = matrix.get(x, y) ? Color.BLACK : Color.WHITE;
                }
            }
            return Bitmap.createBitmap(pixels, size, size, Bitmap.Config.ARGB_8888);
        } catch (Throwable error) {
            return null;
        }
    }

    private void stop() {
        stopped = true;
        main.removeCallbacksAndMessages(null);
        pool.shutdownNow();
    }

    private void dismiss() {
        stop();
        if (dialog.isShowing()) dialog.dismiss();
    }
}
