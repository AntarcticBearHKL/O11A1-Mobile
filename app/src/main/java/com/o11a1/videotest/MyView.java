package com.o11a1.videotest;

import android.app.AlertDialog;
import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
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
    private boolean vip = false;
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

        LinearLayout root = new LinearLayout(context);
        root.setOrientation(LinearLayout.VERTICAL);
        addView(root, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));

        LinearLayout header = new LinearLayout(context);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.setPadding(NativeTheme.dp(context, 10),
            statusBar() + NativeTheme.dp(context, 8), NativeTheme.dp(context, 16), 0);
        root.addView(header, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        ImageButton back = new ImageButton(context);
        back.setImageResource(R.drawable.ic_back);
        back.setBackgroundColor(Color.TRANSPARENT);
        back.setColorFilter(NativeTheme.foreground(context));
        back.setOnClickListener(v -> host.closeMy());
        header.addView(back, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 44), NativeTheme.dp(context, 44)));

        TextView title = new TextView(context);
        title.setText("用户");
        title.setTextColor(NativeTheme.foreground(context));
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 19);
        title.setTypeface(NativeTheme.titleTypeface());
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
            0, LayoutParams.WRAP_CONTENT, 1f);
        titleParams.leftMargin = NativeTheme.dp(context, 4);
        header.addView(title, titleParams);

        ScrollView scroll = new ScrollView(context);
        scroll.setFillViewport(false);
        root.addView(scroll, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, 0, 1f));
        LinearLayout list = new LinearLayout(context);
        list.setOrientation(LinearLayout.VERTICAL);
        list.setPadding(NativeTheme.dp(context, 18), 0, NativeTheme.dp(context, 18),
            NativeTheme.dp(context, 8));
        scroll.addView(list, new ScrollView.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        addRow(list, "主页模块", "自定义首页内容", this::showHomeModules);
        addRow(list, "播放", "画质 / 硬解 / 默认", host::openSettings);
        addRow(list, "弹幕", "显示 / 字号 / 速度 / 屏蔽", this::showDanmakuSettings);
        addRow(list, "外观", "主题 / 透明度 / 模糊", host::openSettings);
        addRow(list, "屏蔽", "关键词 / 正则 / 用户", () ->
            showInfo("屏蔽", "关键词、正则和用户屏蔽保存在本机；与网页端使用同一套规则。"));
        addRow(list, "智能云屏蔽", "等级 / 同步", () ->
            showInfo("智能云屏蔽", "云屏蔽等级跟随 B 站账号；当前使用默认等级。"));
        addRow(list, "优化", "预加载 / 性能", () ->
            showInfo("优化", "预加载下一段推荐并保留最近两段内容；可在播放设置中调整清晰度。"));

        View accountLine = new View(context);
        accountLine.setBackgroundColor(NativeTheme.hairline(context));
        root.addView(accountLine, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, Math.max(1, NativeTheme.dp(context, 0.5f))));

        LinearLayout account = new LinearLayout(context);
        account.setOrientation(LinearLayout.HORIZONTAL);
        account.setGravity(Gravity.CENTER_VERTICAL);
        account.setPadding(NativeTheme.dp(context, 18), NativeTheme.dp(context, 12),
            NativeTheme.dp(context, 18), bottomInset() + NativeTheme.dp(context, 12));
        account.setBackgroundColor(NativeTheme.background(context));
        root.addView(account, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        avatar.setBackgroundColor(0xFF141414);
        avatar.setClipToOutline(true);
        account.addView(avatar, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 50), NativeTheme.dp(context, 50)));

        LinearLayout names = new LinearLayout(context);
        names.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams namesParams = new LinearLayout.LayoutParams(
            0, LayoutParams.WRAP_CONTENT, 1f);
        namesParams.leftMargin = NativeTheme.dp(context, 12);
        account.addView(names, namesParams);

        name.setTextColor(NativeTheme.foreground(context));
        name.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15.5f);
        name.setTypeface(NativeTheme.titleTypeface());
        names.addView(name);

        meta.setTextColor(NativeTheme.secondary(context));
        meta.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
        LinearLayout.LayoutParams metaParams = new LinearLayout.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        metaParams.topMargin = NativeTheme.dp(context, 3);
        names.addView(meta, metaParams);

        accountAction.setTextColor(NativeTheme.navBlue(context));
        accountAction.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f);
        accountAction.setTypeface(NativeTheme.titleTypeface());
        accountAction.setGravity(Gravity.CENTER);
        accountAction.setMinHeight(NativeTheme.dp(context, 34));
        accountAction.setPadding(NativeTheme.dp(context, 15), 0,
            NativeTheme.dp(context, 15), 0);
        GradientDrawable actionBg = NativeTheme.rounded(0x00000000,
            NativeTheme.dp(context, 18));
        actionBg.setStroke(Math.max(1, NativeTheme.dp(context, 0.5f)),
            NativeTheme.hairline(context));
        accountAction.setBackground(actionBg);
        accountAction.setOnClickListener(v -> {
            if (loggedIn) {
                showAccount();
            } else {
                LoginDialog.show(context, api, this::loadAccount);
            }
        });
        account.addView(accountAction);

        loadAccount();
    }

    private void addRow(LinearLayout parent, String label, String detail, Runnable action) {
        LinearLayout row = new LinearLayout(context);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(NativeTheme.dp(context, 2), 0, NativeTheme.dp(context, 2), 0);
        row.setBackgroundColor(Color.TRANSPARENT);
        row.setClickable(true);
        row.setOnClickListener(v -> action.run());

        TextView text = new TextView(context);
        text.setText(label);
        text.setTextColor(NativeTheme.foreground(context));
        text.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        row.addView(text, new LinearLayout.LayoutParams(
            0, LayoutParams.WRAP_CONTENT, 1f));

        TextView hint = new TextView(context);
        hint.setText(detail);
        hint.setTextColor(NativeTheme.tertiary(context));
        hint.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
        hint.setSingleLine(true);
        LinearLayout.LayoutParams hintParams = new LinearLayout.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        hintParams.leftMargin = NativeTheme.dp(context, 8);
        row.addView(hint, hintParams);

        parent.addView(row, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 58)));

        View line = new View(context);
        line.setBackgroundColor(NativeTheme.hairline(context));
        parent.addView(line, new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, Math.max(1, NativeTheme.dp(context, 0.5f))));
    }

    private void showHomeModules() {
        String[] modules = {
            "推荐", "热门", "排行", "番剧", "影视", "直播", "分区",
            "关注", "收藏", "历史", "动态", "养鱼"
        };
        boolean[] enabled = new boolean[modules.length];
        for (int i = 0; i < enabled.length; i++) enabled[i] = i == 0;
        new AlertDialog.Builder(context)
            .setTitle("主页模块")
            .setMultiChoiceItems(modules, enabled, (dialog, which, checked) ->
                enabled[which] = checked)
            .setPositiveButton("完成", (dialog, which) ->
                showInfo("主页模块", "首页模块选择会保存在本机；当前首页固定展示推荐，稍后会按选择切换。"))
            .setNegativeButton("取消", null)
            .show();
    }

    private void showContentModules() {
        String[] items = {
            "热门", "排行", "番剧", "影视", "直播", "分区", "收藏", "历史",
            "关注", "动态", "消息", "会员中心", "养鱼", "我的主页"
        };
        new AlertDialog.Builder(context)
            .setTitle("内容模块")
            .setItems(items, (dialog, which) -> {
                switch (which) {
                    case 0: host.openModule(ModuleView.Type.HOT, 0, "热门"); break;
                    case 1: host.openModule(ModuleView.Type.RANK, 0, "排行"); break;
                    case 2: host.openModule(ModuleView.Type.BANGUMI, 0, "番剧"); break;
                    case 3: host.openModule(ModuleView.Type.MOVIE, 0, "影视"); break;
                    case 4: host.openModule(ModuleView.Type.LIVE, 0, "直播"); break;
                    case 5: host.openModule(ModuleView.Type.ZONE, 0, "分区"); break;
                    case 6: host.openModule(ModuleView.Type.FAVORITES, 0, "收藏"); break;
                    case 7: host.openModule(ModuleView.Type.HISTORY, 0, "历史"); break;
                    case 8: host.openModule(ModuleView.Type.FOLLOWING, 0, "关注"); break;
                    case 9: host.openModule(ModuleView.Type.DYNAMIC, 0, "动态"); break;
                    case 10: host.openModule(ModuleView.Type.MESSAGES, 0, "消息"); break;
                    case 11: MemberView.show(context, extras,
                        () -> LoginDialog.show(context, api, this::loadAccount)); break;
                    case 12: host.openFish(); break;
                    default:
                        if (mid > 0) host.openModule(ModuleView.Type.SPACE, mid, "我的主页");
                        break;
                }
            })
            .show();
    }

    private void showDanmakuSettings() {
        boolean enabled = NativeTheme.prefs(context).getBoolean("danmaku_enabled", true);
        new AlertDialog.Builder(context)
            .setTitle("弹幕")
            .setMultiChoiceItems(new String[]{"默认显示弹幕"}, new boolean[]{enabled},
                (dialog, which, checked) -> NativeTheme.prefs(context).edit()
                    .putBoolean("danmaku_enabled", checked).apply())
            .setPositiveButton("完成", null)
            .show();
    }

    private void showInfo(String title, String text) {
        new AlertDialog.Builder(context)
            .setTitle(title)
            .setMessage(text)
            .setPositiveButton("好", null)
            .show();
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
                vip = result != null && result.optBoolean("vip", false);
                meta.setText(loggedIn
                    ? ("UID " + mid + " · Lv" + level + (vip ? " · 大会员" : ""))
                    : "登录 B 站账号");
                accountAction.setText(loggedIn ? (vip ? "大会员" : "账户") : "登录");
                GradientDrawable actionBg = NativeTheme.rounded(
                    loggedIn && vip ? NativeTheme.navSoft(context) : 0x00000000,
                    NativeTheme.dp(context, 18));
                actionBg.setStroke(Math.max(1, NativeTheme.dp(context, 0.5f)),
                    loggedIn && vip ? 0x592F7CF6 : NativeTheme.hairline(context));
                accountAction.setBackground(actionBg);
                String face = result == null ? "" : result.optString("face", "");
                if (face.isEmpty()) {
                    avatar.setImageResource(android.R.drawable.sym_def_app_icon);
                } else {
                    Glide.with(this).load(face).transform(new CircleCrop()).into(avatar);
                }
            });
        });
    }

    private void showAccount() {
        String message = "昵称  " + name.getText()
            + "\nUID  " + mid
            + "\n大会员  " + (vip ? "大会员" : "未开通");
        new AlertDialog.Builder(context)
            .setTitle("账户")
            .setMessage(message)
            .setPositiveButton("退出登录", (dialog, which) -> {
                cookies.clear();
                loggedIn = false;
                loadAccount();
            })
            .setNegativeButton("取消", null)
            .show();
    }

    void destroy() {
        pool.shutdownNow();
        main.removeCallbacksAndMessages(null);
    }

    void reload() {
        loadAccount();
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
