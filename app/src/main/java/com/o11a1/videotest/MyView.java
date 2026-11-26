package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.GridLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.bitmap.CircleCrop;

import org.json.JSONObject;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class MyView extends FrameLayout {
    interface Host {
        void openModule(ModuleView.Type type, long targetId, String title);
        void openFish();
        void openSettings();
        void closeMy();
    }

    private final Context context;
    private final BiliApi api;
    private final BiliExtras extras;
    private final CookieStore cookies;
    private final Host host;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ImageView avatar = new ImageView(getContext());
    private final TextView name = new TextView(getContext());
    private final TextView meta = new TextView(getContext());
    private final TextView accountAction = new TextView(getContext());
    private boolean loggedIn = false;
    private long mid = 0;

    MyView(Context context, BiliApi api, BiliExtras extras, CookieStore cookies, Host host) {
        super(context);
        this.context = context;
        this.api = api;
        this.extras = extras;
        this.cookies = cookies;
        this.host = host;
        setBackgroundColor(NativeTheme.background(context));
        setClickable(true);

        ScrollView scroll = new ScrollView(context);
        addView(scroll, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        LinearLayout root = new LinearLayout(context);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(NativeTheme.dp(context, 18), statusBar() + NativeTheme.dp(context, 10),
            NativeTheme.dp(context, 18), NativeTheme.dp(context, 28));
        scroll.addView(root, new ScrollView.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        LinearLayout top = new LinearLayout(context);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        root.addView(top, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 48)));

        ImageButton back = new ImageButton(context);
        back.setImageResource(R.drawable.ic_back);
        back.setBackgroundColor(Color.TRANSPARENT);
        back.setColorFilter(NativeTheme.foreground(context));
        back.setOnClickListener(v -> host.closeMy());
        top.addView(back, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 44), NativeTheme.dp(context, 44)));

        TextView title = new TextView(context);
        title.setText("我的");
        title.setTextColor(NativeTheme.foreground(context));
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 22);
        title.setTypeface(NativeTheme.titleTypeface());
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
            0, LayoutParams.WRAP_CONTENT, 1f);
        titleParams.leftMargin = NativeTheme.dp(context, 4);
        top.addView(title, titleParams);

        LinearLayout account = new LinearLayout(context);
        account.setOrientation(LinearLayout.HORIZONTAL);
        account.setGravity(Gravity.CENTER_VERTICAL);
        account.setPadding(0, NativeTheme.dp(context, 12), 0, NativeTheme.dp(context, 18));
        root.addView(account, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        avatar.setBackgroundColor(0xFF141414);
        avatar.setClipToOutline(true);
        account.addView(avatar, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 58), NativeTheme.dp(context, 58)));

        LinearLayout names = new LinearLayout(context);
        names.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams namesParams = new LinearLayout.LayoutParams(
            0, LayoutParams.WRAP_CONTENT, 1f);
        namesParams.leftMargin = NativeTheme.dp(context, 12);
        account.addView(names, namesParams);

        name.setTextColor(NativeTheme.foreground(context));
        name.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17);
        name.setTypeface(NativeTheme.titleTypeface());
        names.addView(name);

        meta.setTextColor(NativeTheme.secondary(context));
        meta.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        LinearLayout.LayoutParams metaParams = new LinearLayout.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        metaParams.topMargin = NativeTheme.dp(context, 4);
        names.addView(meta, metaParams);

        accountAction.setTextColor(NativeTheme.ACCENT);
        accountAction.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13);
        accountAction.setPadding(NativeTheme.dp(context, 10), NativeTheme.dp(context, 6),
            NativeTheme.dp(context, 10), NativeTheme.dp(context, 6));
        accountAction.setOnClickListener(v -> {
            if (loggedIn) {
                cookies.clear();
                loggedIn = false;
                loadAccount();
            } else {
                LoginDialog.show(context, api, this::loadAccount);
            }
        });
        account.addView(accountAction);

        GridLayout grid = new GridLayout(context);
        grid.setColumnCount(2);
        grid.setAlignmentMode(GridLayout.ALIGN_BOUNDS);
        grid.setUseDefaultMargins(false);
        root.addView(grid, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        addButton(grid, "热门", () -> host.openModule(ModuleView.Type.HOT, 0, "热门"));
        addButton(grid, "排行", () -> host.openModule(ModuleView.Type.RANK, 0, "排行"));
        addButton(grid, "番剧", () -> host.openModule(ModuleView.Type.BANGUMI, 0, "番剧"));
        addButton(grid, "影视", () -> host.openModule(ModuleView.Type.MOVIE, 0, "影视"));
        addButton(grid, "直播", () -> host.openModule(ModuleView.Type.LIVE, 0, "直播"));
        addButton(grid, "分区", () -> host.openModule(ModuleView.Type.ZONE, 0, "分区"));
        addButton(grid, "收藏", () -> host.openModule(ModuleView.Type.FAVORITES, 0, "收藏"));
        addButton(grid, "历史", () -> host.openModule(ModuleView.Type.HISTORY, 0, "历史"));
        addButton(grid, "关注", () -> host.openModule(ModuleView.Type.FOLLOWING, 0, "关注"));
        addButton(grid, "动态", () -> host.openModule(ModuleView.Type.DYNAMIC, 0, "动态"));
        addButton(grid, "消息", () -> host.openModule(ModuleView.Type.MESSAGES, 0, "消息"));
        addButton(grid, "养鱼", host::openFish);
        addButton(grid, "设置", host::openSettings);
        addButton(grid, "我的主页", () -> {
            if (mid > 0) host.openModule(ModuleView.Type.SPACE, mid, "我的主页");
        });

        loadAccount();
    }

    private int statusBar() {
        int id = getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }

    private void addButton(GridLayout grid, String label, Runnable action) {
        TextView button = new TextView(context);
        button.setText(label);
        button.setTextColor(NativeTheme.foreground(context));
        button.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        button.setTypeface(NativeTheme.titleTypeface());
        button.setGravity(Gravity.CENTER);
        button.setBackground(NativeTheme.glassPanel(context, NativeTheme.dp(context, 16)));
        button.setOnClickListener(v -> action.run());
        GridLayout.LayoutParams params = new GridLayout.LayoutParams();
        params.width = 0;
        params.height = NativeTheme.dp(context, 52);
        params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        params.setMargins(NativeTheme.dp(context, 4), NativeTheme.dp(context, 4),
            NativeTheme.dp(context, 4), NativeTheme.dp(context, 4));
        grid.addView(button, params);
    }

    private void loadAccount() {
        pool.execute(() -> {
            JSONObject result = extras.account();
            main.post(() -> {
                loggedIn = result != null && result.optBoolean("loggedIn", false);
                mid = result == null ? 0 : result.optLong("mid", 0);
                String displayName = result == null ? "" : result.optString("name", "");
                name.setText(loggedIn ? (displayName.isEmpty() ? "已登录" : displayName) : "未登录");
                int level = result == null ? 0 : result.optInt("level", 0);
                boolean vip = result != null && result.optBoolean("vip", false);
                meta.setText(loggedIn
                    ? ("UID " + mid + " · Lv" + level + (vip ? " · 大会员" : ""))
                    : "登录后同步关注、收藏、历史");
                accountAction.setText(loggedIn ? "退出登录" : "扫码登录");
                String face = result == null ? "" : result.optString("face", "");
                if (face.isEmpty()) {
                    avatar.setImageResource(android.R.drawable.sym_def_app_icon);
                } else {
                    Glide.with(this).load(face).transform(new CircleCrop()).into(avatar);
                }
            });
        });
    }

    void destroy() {
        pool.shutdownNow();
        main.removeCallbacksAndMessages(null);
    }

    void reload() {
        loadAccount();
    }
}
