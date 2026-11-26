package com.o11a1.videotest;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.view.View;
import android.view.Window;
import android.view.WindowInsetsController;

final class NativeTheme {
    static final int ACCENT = 0xFFFF5C75;
    static final int ROSE = 0xFFFFD9DE;
    static final int BLUE = 0xFF4C9AFF;
    static final int ORANGE = 0xFFFF9F43;
    static final int PINK = 0xFFFF5C8A;

    private NativeTheme() {}

    static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences("o11a1_native_ui", Context.MODE_PRIVATE);
    }

    static String themeMode(Context context) {
        return prefs(context).getString("theme", "system");
    }

    static void setThemeMode(Context context, String mode) {
        prefs(context).edit().putString("theme", mode).apply();
    }

    static int quality(Context context) {
        return prefs(context).getInt("quality", 80);
    }

    static void setQuality(Context context, int qn) {
        prefs(context).edit().putInt("quality", qn).apply();
    }

    static boolean isDark(Context context) {
        String mode = themeMode(context);
        if ("dark".equals(mode)) return true;
        if ("light".equals(mode)) return false;
        int flags = context.getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK;
        return flags == Configuration.UI_MODE_NIGHT_YES;
    }

    static int background(Context context) {
        return isDark(context) ? Color.BLACK : Color.WHITE;
    }

    static int foreground(Context context) {
        return isDark(context) ? Color.WHITE : Color.BLACK;
    }

    static int secondary(Context context) {
        return isDark(context) ? 0xFF9E9E9E : 0xFF616161;
    }

    static int tertiary(Context context) {
        return isDark(context) ? 0xFF707070 : 0xFF9E9E9E;
    }

    static int hairline(Context context) {
        return isDark(context) ? 0x1AFFFFFF : 0x14000000;
    }

    static int glass(Context context) {
        return isDark(context) ? 0xD9141414 : 0xD9FFFFFF;
    }

    static int navBlue(Context context) {
        return isDark(context) ? 0xFF7FB6FF : 0xFF005FB8;
    }

    static int navSoft(Context context) {
        return isDark(context) ? 0x332F7CF6 : 0xFFDCEEFF;
    }

    static int playColor(long count) {
        if (count >= 10_000_000L) return 0xFFD3453D;
        if (count >= 1_000_000L) return 0xFFC77700;
        if (count >= 100_000L) return 0xFF2F7CF6;
        if (count >= 10_000L) return 0xFF2F8A5A;
        return 0xFF8A909B;
    }

    static String freshness(long pubdate) {
        if (pubdate <= 0) return "";
        long seconds = pubdate > 100_000_000_000L ? pubdate / 1000 : pubdate;
        long age = Math.max(0, System.currentTimeMillis() / 1000 - seconds);
        if (age < 3600) return "刚刚";
        if (age < 86400) return (age / 3600) + "小时前";
        if (age < 86400L * 7) return (age / 86400) + "天前";
        if (age < 86400L * 30) return (age / (7 * 86400)) + "周前";
        if (age < 86400L * 90) return (age / (30 * 86400)) + "个月前";
        if (age < 86400L * 365) return (age / (90 * 86400)) + "季度前";
        return (age / (365 * 86400)) + "年前";
    }

    static int freshnessColor(long pubdate) {
        if (pubdate <= 0) return 0xFF8A909B;
        long seconds = pubdate > 100_000_000_000L ? pubdate / 1000 : pubdate;
        long age = Math.max(0, System.currentTimeMillis() / 1000 - seconds);
        if (age < 86400) return 0xFFD97862;
        if (age < 86400L * 7) return 0xFFC9984F;
        if (age < 86400L * 30) return 0xFF4F9A83;
        if (age < 86400L * 90) return 0xFF5C84C6;
        if (age < 86400L * 365) return 0xFF8A78B8;
        return 0xFF8A909B;
    }

    static int dp(Context context, float value) {
        return Math.round(value * context.getResources().getDisplayMetrics().density);
    }

    static GradientDrawable rounded(int color, float radiusPx) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(radiusPx);
        return drawable;
    }

    static GradientDrawable glassPanel(Context context, float radiusPx) {
        GradientDrawable drawable = rounded(glass(context), radiusPx);
        drawable.setStroke(Math.max(1, dp(context, 0.5f)), hairline(context));
        return drawable;
    }

    static Typeface titleTypeface() {
        return Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD);
    }

    static Typeface numberTypeface() {
        return Typeface.create("monospace", Typeface.NORMAL);
    }

    static void applySystemBars(Activity activity) {
        Window window = activity.getWindow();
        window.setStatusBarColor(Color.TRANSPARENT);
        window.setNavigationBarColor(Color.TRANSPARENT);
        View decor = window.getDecorView();
        int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION;
        decor.setSystemUiVisibility(flags);
        boolean dark = isDark(activity);
        if (Build.VERSION.SDK_INT >= 30) {
            WindowInsetsController controller = window.getInsetsController();
            if (controller != null) {
                int appearance = dark ? 0 : WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
                    | WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS;
                controller.setSystemBarsAppearance(appearance,
                    WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
                        | WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS);
            }
        } else if (!dark) {
            decor.setSystemUiVisibility(flags | View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
        }
    }
}
