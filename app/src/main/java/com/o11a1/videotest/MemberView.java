package com.o11a1.videotest;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class MemberView {
    static void show(Context context, BiliExtras extras, Runnable onLogin) {
        new MemberView(context, extras, onLogin).open();
    }

    private final Context context;
    private final BiliExtras extras;
    private final Runnable onLogin;
    private final Dialog dialog;
    private final LinearLayout content;
    private final TextView status;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private boolean destroyed = false;

    private MemberView(Context context, BiliExtras extras, Runnable onLogin) {
        this.context = context;
        this.extras = extras;
        this.onLogin = onLogin;
        dialog = new Dialog(context);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setCanceledOnTouchOutside(true);

        LinearLayout root = new LinearLayout(context);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackground(NativeTheme.rounded(NativeTheme.background(context), NativeTheme.dp(context, 22)));

        LinearLayout header = new LinearLayout(context);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.setPadding(NativeTheme.dp(context, 20), NativeTheme.dp(context, 16),
            NativeTheme.dp(context, 10), NativeTheme.dp(context, 6));
        root.addView(header, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        TextView title = new TextView(context);
        title.setText("会员中心");
        title.setTextColor(NativeTheme.foreground(context));
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 20);
        title.setTypeface(NativeTheme.titleTypeface());
        header.addView(title, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

        ImageButton close = new ImageButton(context);
        close.setImageResource(android.R.drawable.ic_menu_close_clear_cancel);
        close.setBackgroundColor(Color.TRANSPARENT);
        close.setColorFilter(NativeTheme.secondary(context));
        close.setOnClickListener(v -> dismiss());
        header.addView(close, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 40), NativeTheme.dp(context, 40)));

        status = new TextView(context);
        status.setTextColor(NativeTheme.secondary(context));
        status.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13);
        status.setGravity(Gravity.CENTER);
        status.setPadding(0, 0, 0, NativeTheme.dp(context, 20));
        root.addView(status, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        ScrollView scroll = new ScrollView(context);
        scroll.setFillViewport(false);
        content = new LinearLayout(context);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(NativeTheme.dp(context, 20), 0, NativeTheme.dp(context, 20),
            NativeTheme.dp(context, 24));
        scroll.addView(content, new ScrollView.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        root.addView(scroll, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        dialog.setContentView(root);
        Window window = dialog.getWindow();
        if (window != null) {
            window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
            int width = context.getResources().getDisplayMetrics().widthPixels
                - NativeTheme.dp(context, 36);
            int height = (int) (context.getResources().getDisplayMetrics().heightPixels * 0.82f);
            window.setLayout(width, height);
            window.setGravity(Gravity.CENTER);
        }
        dialog.setOnDismissListener(d -> destroy());
    }

    private void open() {
        dialog.show();
        load();
    }

    private void load() {
        status.setText("正在加载会员信息…");
        status.setVisibility(View.VISIBLE);
        content.removeAllViews();
        pool.execute(() -> {
            JSONObject result = extras.memberCenter();
            main.post(() -> {
                if (destroyed) return;
                if (result == null || !result.optBoolean("ok", false)) {
                    String message = result == null ? "会员信息不可用" : result.optString("error", "会员信息不可用");
                    status.setText(message);
                    status.setVisibility(View.VISIBLE);
                    if (message.contains("登录")) {
                        TextView login = new TextView(context);
                        login.setText("扫码登录");
                        login.setTextColor(Color.WHITE);
                        login.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
                        login.setTypeface(NativeTheme.titleTypeface());
                        login.setGravity(Gravity.CENTER);
                        login.setBackground(NativeTheme.rounded(NativeTheme.ACCENT, NativeTheme.dp(context, 16)));
                        login.setOnClickListener(v -> {
                            dismiss();
                            if (onLogin != null) onLogin.run();
                        });
                        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 48));
                        params.topMargin = NativeTheme.dp(context, 16);
                        content.addView(login, params);
                    }
                    return;
                }
                status.setVisibility(View.GONE);
                render(result);
            });
        });
    }

    private void render(JSONObject data) {
        boolean vip = data.optBoolean("vip", false);
        long due = data.optLong("vipDue", 0);
        int vipType = data.optInt("vipType", 0);

        LinearLayout card = new LinearLayout(context);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(NativeTheme.dp(context, 16), NativeTheme.dp(context, 16),
            NativeTheme.dp(context, 16), NativeTheme.dp(context, 16));
        card.setBackground(NativeTheme.glassPanel(context, NativeTheme.dp(context, 16)));
        content.addView(card, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        TextView vipTitle = new TextView(context);
        vipTitle.setText(vip ? "大会员" : "普通用户");
        vipTitle.setTextColor(vip ? NativeTheme.ORANGE : NativeTheme.foreground(context));
        vipTitle.setTextSize(TypedValue.COMPLEX_UNIT_SP, 22);
        vipTitle.setTypeface(NativeTheme.titleTypeface());
        card.addView(vipTitle);

        TextView vipMeta = new TextView(context);
        if (vip) {
            String type = vipType == 2 ? "年度大会员" : (vipType == 1 ? "月度大会员" : "大会员");
            vipMeta.setText(type + " · 有效期至 " + formatDate(due));
        } else {
            vipMeta.setText("完成每日任务可积累经验，开通大会员享高清画质。");
        }
        vipMeta.setTextColor(NativeTheme.secondary(context));
        vipMeta.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        LinearLayout.LayoutParams metaParams = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        metaParams.topMargin = NativeTheme.dp(context, 4);
        card.addView(vipMeta, metaParams);

        JSONArray tasks = data.optJSONArray("tasks");
        if (tasks != null && tasks.length() > 0) {
            addSection("每日经验");
            LinearLayout taskCard = cardColumn();
            for (int i = 0; i < tasks.length(); i += 1) {
                JSONObject task = tasks.optJSONObject(i);
                if (task == null) continue;
                LinearLayout row = new LinearLayout(context);
                row.setOrientation(LinearLayout.HORIZONTAL);
                row.setGravity(Gravity.CENTER_VERTICAL);
                TextView label = new TextView(context);
                label.setText(task.optString("label", ""));
                label.setTextColor(NativeTheme.foreground(context));
                label.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
                row.addView(label, new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
                TextView detail = new TextView(context);
                String text = task.optString("detail", "");
                if (text.isEmpty()) {
                    text = "+" + task.optInt("reward", 0) + " 经验";
                }
                detail.setText(text);
                detail.setTextColor(NativeTheme.secondary(context));
                detail.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
                row.addView(detail);
                ImageView check = new ImageView(context);
                check.setImageResource(task.optBoolean("done", false)
                    ? android.R.drawable.checkbox_on_background
                    : android.R.drawable.checkbox_off_background);
                LinearLayout.LayoutParams checkParams = new LinearLayout.LayoutParams(
                    NativeTheme.dp(context, 20), NativeTheme.dp(context, 20));
                checkParams.leftMargin = NativeTheme.dp(context, 10);
                row.addView(check, checkParams);
                taskCard.addView(row, rowParams());
            }
            content.addView(taskCard, cardParams());
        }

        JSONArray log = data.optJSONArray("log");
        if (log != null && log.length() > 0) {
            addSection("最近经验");
            LinearLayout logCard = cardColumn();
            for (int i = 0; i < log.length(); i += 1) {
                JSONObject entry = log.optJSONObject(i);
                if (entry == null) continue;
                LinearLayout row = new LinearLayout(context);
                row.setOrientation(LinearLayout.HORIZONTAL);
                row.setGravity(Gravity.CENTER_VERTICAL);
                TextView delta = new TextView(context);
                int value = entry.optInt("delta", 0);
                delta.setText((value > 0 ? "+" : "") + value + " 经验");
                delta.setTextColor(value >= 0 ? 0xFF4CAF50 : NativeTheme.secondary(context));
                delta.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
                delta.setTypeface(NativeTheme.numberTypeface());
                row.addView(delta, new LinearLayout.LayoutParams(
                    NativeTheme.dp(context, 74), ViewGroup.LayoutParams.WRAP_CONTENT));
                TextView reason = new TextView(context);
                reason.setText(entry.optString("reason", ""));
                reason.setTextColor(NativeTheme.foreground(context));
                reason.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
                reason.setSingleLine(true);
                reason.setEllipsize(android.text.TextUtils.TruncateAt.END);
                row.addView(reason, new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
                TextView time = new TextView(context);
                time.setText(entry.optString("time", ""));
                time.setTextColor(NativeTheme.tertiary(context));
                time.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
                row.addView(time);
                logCard.addView(row, rowParams());
            }
            content.addView(logCard, cardParams());
        }
    }

    private LinearLayout.LayoutParams cardParams() {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        params.topMargin = NativeTheme.dp(context, 8);
        return params;
    }

    private LinearLayout cardColumn() {
        LinearLayout card = new LinearLayout(context);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(NativeTheme.dp(context, 16), NativeTheme.dp(context, 14),
            NativeTheme.dp(context, 16), NativeTheme.dp(context, 14));
        card.setBackground(NativeTheme.glassPanel(context, NativeTheme.dp(context, 16)));
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        params.topMargin = NativeTheme.dp(context, 8);
        card.setLayoutParams(params);
        return card;
    }

    private LinearLayout.LayoutParams rowParams() {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        params.topMargin = NativeTheme.dp(context, 10);
        return params;
    }

    private void addSection(String text) {
        TextView label = new TextView(context);
        label.setText(text);
        label.setTextColor(NativeTheme.foreground(context));
        label.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        label.setTypeface(NativeTheme.titleTypeface());
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        params.topMargin = NativeTheme.dp(context, 20);
        content.addView(label, params);
    }

    private String formatDate(long seconds) {
        if (seconds <= 0) return "—";
        return new SimpleDateFormat("yyyy-MM-dd", Locale.CHINA)
            .format(new Date(seconds * 1000L));
    }

    private void dismiss() {
        if (dialog.isShowing()) dialog.dismiss();
        destroy();
    }

    private void destroy() {
        if (destroyed) return;
        destroyed = true;
        main.removeCallbacksAndMessages(null);
        pool.shutdownNow();
    }
}
