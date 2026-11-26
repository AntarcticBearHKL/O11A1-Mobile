package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Left navigation drawer matching the original web app. */
final class SidebarView extends FrameLayout {
    interface Host {
        void onSidebarHome();
        void onSidebarModule(ModuleView.Type type, String title);
        void onSidebarMy();
        void onSidebarSearch();
        void onSidebarClosed();
    }

    private final Context context;
    private final Host host;
    private final View panel;
    private final View backdrop;
    private final int panelWidth;

    SidebarView(Context context, Host host) {
        super(context);
        this.context = context;
        this.host = host;
        setVisibility(GONE);

        backdrop = new View(context);
        backdrop.setBackgroundColor(NativeTheme.isDark(context) ? 0x8C000000 : 0x47000000);
        backdrop.setOnClickListener(v -> close());
        addView(backdrop, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        panelWidth = Math.round(getResources().getDisplayMetrics().widthPixels * 0.50f);
        LinearLayout sheet = new LinearLayout(context);
        sheet.setOrientation(LinearLayout.VERTICAL);
        GradientDrawable bg = new GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            NativeTheme.isDark(context)
                ? new int[]{0xBD121720, 0xE00A0D13}
                : new int[]{0xBDFAFAFC, 0xE0F4F5F9});
        float r = NativeTheme.dp(context, 26);
        bg.setCornerRadii(new float[]{0, 0, r, r, r, r, 0, 0});
        bg.setStroke(Math.max(1, NativeTheme.dp(context, 1)),
            NativeTheme.isDark(context) ? 0x14FFFFFF : 0x94FFFFFF);
        sheet.setBackground(bg);
        sheet.setPadding(NativeTheme.dp(context, 0), statusBar() + NativeTheme.dp(context, 16),
            NativeTheme.dp(context, 12), bottomInset() + NativeTheme.dp(context, 8));
        FrameLayout.LayoutParams sheetParams = new FrameLayout.LayoutParams(
            panelWidth, LayoutParams.MATCH_PARENT);
        sheetParams.gravity = Gravity.START;
        addView(sheet, sheetParams);
        panel = sheet;

        LinearLayout nav = new LinearLayout(context);
        nav.setOrientation(LinearLayout.VERTICAL);
        sheet.addView(nav, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, 0, 1f));
        nav.addView(new View(context), new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, 0, 1f));

        addRow(nav, "直播", R.drawable.ic_nav_live,
            () -> host.onSidebarModule(ModuleView.Type.LIVE, "直播"));
        addRow(nav, "番剧", R.drawable.ic_nav_bangumi,
            () -> host.onSidebarModule(ModuleView.Type.BANGUMI, "番剧"));
        addRow(nav, "消息", R.drawable.ic_nav_messages,
            () -> host.onSidebarModule(ModuleView.Type.MESSAGES, "消息"));
        addRow(nav, "历史", R.drawable.ic_nav_history,
            () -> host.onSidebarModule(ModuleView.Type.HISTORY, "历史"));
        nav.addView(new View(context), new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, 0, 1f));

        View footerLine = new View(context);
        footerLine.setBackgroundColor(NativeTheme.hairline(context));
        LinearLayout.LayoutParams lineParams = new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, Math.max(1, NativeTheme.dp(context, 0.5f)));
        lineParams.leftMargin = NativeTheme.dp(context, 26);
        lineParams.topMargin = NativeTheme.dp(context, 10);
        sheet.addView(footerLine, lineParams);

        LinearLayout footer = new LinearLayout(context);
        footer.setOrientation(LinearLayout.VERTICAL);
        sheet.addView(footer, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));
        addRow(footer, "用户", R.drawable.ic_nav_my, host::onSidebarMy);
    }

    private void addRow(LinearLayout parent, String label, int iconRes, Runnable action) {
        LinearLayout row = new LinearLayout(context);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER);
        row.setPadding(NativeTheme.dp(context, 8), 0, NativeTheme.dp(context, 8), 0);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(0x00000000);
        float r = NativeTheme.dp(context, 18);
        bg.setCornerRadii(new float[]{0, 0, r, r, r, r, 0, 0});
        row.setBackground(bg);
        row.setClickable(true);
        row.setOnClickListener(v -> {
            close();
            action.run();
        });

        ImageView icon = new ImageView(context);
        icon.setImageResource(iconRes);
        icon.setColorFilter(NativeTheme.isDark(context) ? 0xFFB0B0B6 : 0xFF6E6E73);
        row.addView(icon, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 19), NativeTheme.dp(context, 19)));

        TextView text = new TextView(context);
        text.setText(label);
        text.setTextColor(NativeTheme.foreground(context));
        text.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 14);
        text.setTypeface(NativeTheme.titleTypeface());
        LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        textParams.leftMargin = NativeTheme.dp(context, 10);
        row.addView(text, textParams);

        parent.addView(row, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 56)));
    }

    void open() {
        setVisibility(VISIBLE);
        panel.setTranslationX(-panelWidth);
        backdrop.setAlpha(0f);
        panel.animate().translationX(0).setDuration(240).start();
        backdrop.animate().alpha(1f).setDuration(200).start();
    }

    void close() {
        if (getVisibility() != VISIBLE) return;
        panel.animate().translationX(-panelWidth).setDuration(200).start();
        backdrop.animate().alpha(0f).setDuration(180).start();
        postDelayed(() -> {
            setVisibility(GONE);
            host.onSidebarClosed();
        }, 200);
    }

    private int statusBar() {
        int id = getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }

    private int bottomInset() {
        int id = getResources().getIdentifier("navigation_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }
}
