package com.o11a1.videotest;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.PictureInPictureParams;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.util.Rational;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.Toast;

public final class MainActivity extends Activity implements FeedView.Host, MyView.Host {
    private CookieStore cookies;
    private BiliApi api;
    private BiliExtras extras;
    private FrameLayout root;
    private FrameLayout content;
    private GlassTabBarView tabBar;
    private ImageButton settingsButton;
    private ImageButton myButton;
    private FeedView feed;
    private VideoListView following;
    private VideoListView dynamic;
    private FishView fish;
    private MyView myView;
    private ModuleView moduleView;
    private SidebarView sidebarView;
    private View currentView;
    private PlayerOverlay overlay;
    private boolean toolbarHidden;
    private boolean searchVisible;

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        NativeTheme.applySystemBars(this);
        getWindow().setBackgroundDrawable(new android.graphics.drawable.ColorDrawable(
            NativeTheme.background(this)));

        cookies = new CookieStore(this);
        api = new BiliApi(cookies);
        extras = new BiliExtras(cookies, api);

        root = new FrameLayout(this);
        root.setBackgroundColor(NativeTheme.background(this));
        setContentView(root);

        content = new FrameLayout(this);
        content.setBackgroundColor(NativeTheme.background(this));
        root.addView(content, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        tabBar = new GlassTabBarView(this);
        tabBar.setOnSelect(index -> showTab(index));
        FrameLayout.LayoutParams tabParams = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, NativeTheme.dp(this, 58));
        tabParams.gravity = Gravity.BOTTOM;
        tabParams.leftMargin = NativeTheme.dp(this, 12);
        tabParams.rightMargin = NativeTheme.dp(this, 12);
        tabParams.bottomMargin = NativeTheme.dp(this, 10) + bottomInset();
        root.addView(tabBar, tabParams);

        settingsButton = new ImageButton(this);
        settingsButton.setImageResource(android.R.drawable.ic_menu_manage);
        settingsButton.setColorFilter(NativeTheme.foreground(this));
        settingsButton.setBackground(NativeTheme.rounded(NativeTheme.glass(this), NativeTheme.dp(this, 20)));
        settingsButton.setPadding(NativeTheme.dp(this, 9), NativeTheme.dp(this, 9),
            NativeTheme.dp(this, 9), NativeTheme.dp(this, 9));
        settingsButton.setOnClickListener(v -> showSettings());
        FrameLayout.LayoutParams settingsParams = new FrameLayout.LayoutParams(
            NativeTheme.dp(this, 40), NativeTheme.dp(this, 40));
        settingsParams.gravity = Gravity.TOP | Gravity.END;
        settingsParams.rightMargin = NativeTheme.dp(this, 16);
        settingsParams.topMargin = statusBar() + NativeTheme.dp(this, 6);
        root.addView(settingsButton, settingsParams);

        myButton = new ImageButton(this);
        myButton.setImageResource(android.R.drawable.ic_menu_myplaces);
        myButton.setColorFilter(NativeTheme.foreground(this));
        myButton.setBackground(NativeTheme.rounded(NativeTheme.glass(this), NativeTheme.dp(this, 20)));
        myButton.setPadding(NativeTheme.dp(this, 9), NativeTheme.dp(this, 9),
            NativeTheme.dp(this, 9), NativeTheme.dp(this, 9));
        myButton.setOnClickListener(v -> openMyView());
        FrameLayout.LayoutParams myParams = new FrameLayout.LayoutParams(
            NativeTheme.dp(this, 40), NativeTheme.dp(this, 40));
        myParams.gravity = Gravity.TOP | Gravity.START;
        myParams.leftMargin = NativeTheme.dp(this, 16);
        myParams.topMargin = statusBar() + NativeTheme.dp(this, 6);
        root.addView(myButton, myParams);

        // The original home has no top buttons. My and settings live in the
        // left navigation drawer; keep these views invisible for compatibility.
        settingsButton.setVisibility(View.GONE);
        myButton.setVisibility(View.GONE);

        showTab(0);
    }

    private int statusBar() {
        int id = getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : NativeTheme.dp(this, 24);
    }

    private int bottomInset() {
        int id = getResources().getIdentifier("navigation_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : 0;
    }

    private void showTab(int index) {
        if (currentView != null) content.removeView(currentView);
        switch (index) {
            case 0:
                if (feed == null) feed = new FeedView(this, api, extras, cookies, this);
                currentView = feed;
                break;
            case 1:
                if (following == null) {
                    following = new VideoListView(this, extras, VideoListView.Mode.FOLLOWING, 0,
                        (item, source) -> openPlayer(item, source), this::showLogin);
                }
                currentView = following;
                break;
            case 2:
                if (dynamic == null) {
                    dynamic = new VideoListView(this, extras, VideoListView.Mode.DYNAMIC, 0,
                        (item, source) -> openPlayer(item, source), this::showLogin);
                }
                currentView = dynamic;
                break;
            default:
                if (fish == null) fish = new FishView(this, extras);
                currentView = fish;
                break;
        }
        content.addView(currentView, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        tabBar.select(index, false);
        root.bringChildToFront(tabBar);
    }

    @Override public void onOpenPlayer(VideoItem item, View source) {
        openPlayer(item, source);
    }

    @Override public void onOpenProfile(long mid) {
        openProfile(mid);
    }

    @Override public void onToolbarHidden(boolean hidden) {
        toolbarHidden = hidden;
        if (searchVisible) return;
        tabBar.setHidden(hidden, true);
    }

    @Override public void onSearchVisibility(boolean visible) {
        searchVisible = visible;
        tabBar.setHidden(visible || toolbarHidden, true);
    }

    @Override public void onOpenSidebar() {
        openSidebar();
    }

    private void openSidebar() {
        if (sidebarView == null) {
            sidebarView = new SidebarView(this, new SidebarView.Host() {
                @Override public void onSidebarHome() {
                    showTab(0);
                }

                @Override public void onSidebarModule(ModuleView.Type type, String title) {
                    openModuleView(type, 0, title);
                }

                @Override public void onSidebarMy() {
                    openMyView();
                }

                @Override public void onSidebarSearch() {
                    showTab(0);
                    if (feed != null) feed.openSearchFromHost();
                }

                @Override public void onSidebarClosed() {
                }
            });
            sidebarView.setVisibility(View.GONE);
            root.addView(sidebarView, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        }
        root.bringChildToFront(sidebarView);
        sidebarView.open();
    }

    private void openPlayer(VideoItem item, View source) {
        if (overlay != null || item == null) return;
        if (feed != null) feed.onPauseFeed();
        tabBar.setHidden(true, true);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        if (Build.VERSION.SDK_INT >= 30) {
            android.view.WindowInsetsController controller = getWindow().getInsetsController();
            if (controller != null) controller.hide(android.view.WindowInsets.Type.systemBars());
        } else {
            getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    | View.SYSTEM_UI_FLAG_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
        }
        PlayerOverlay view = new PlayerOverlay(this, api, cookies, item, source,
            () -> closeOverlay(), this::openProfile);
        overlay = view;
        root.addView(view, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        view.start();
    }

    private void closeOverlay() {
        if (overlay == null) return;
        PlayerOverlay view = overlay;
        overlay = null;
        root.removeView(view);
        view.destroy();
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        if (Build.VERSION.SDK_INT >= 30) {
            android.view.WindowInsetsController controller = getWindow().getInsetsController();
            if (controller != null) controller.show(android.view.WindowInsets.Type.systemBars());
        }
        NativeTheme.applySystemBars(this);
        if (moduleView != null) {
            tabBar.setHidden(true, false);
        } else {
            tabBar.setHidden(toolbarHidden, false);
        }
        if (feed != null) feed.onResumeFeed();
    }

    private void openProfile(long mid) {
        if (mid <= 0) return;
        if (overlay != null) {
            overlay.close();
        }
        VideoListView view = new VideoListView(this, extras, VideoListView.Mode.SPACE, mid,
            (item, source) -> openPlayer(item, source), this::showLogin);
        FrameLayout holder = new FrameLayout(this);
        holder.setBackgroundColor(NativeTheme.background(this));
        holder.addView(view, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        android.app.Dialog dialog = new android.app.Dialog(this,
            android.R.style.Theme_Material_Light_NoActionBar_Fullscreen);
        dialog.setContentView(holder);
        dialog.setOnDismissListener(d -> {
            if (view != null) view.destroy();
        });
        dialog.show();
    }

    @Override public void openModule(ModuleView.Type type, long targetId, String title) {
        openModuleView(type, targetId, title);
    }

    @Override public void openFish() {
        closeMyView();
        showTab(3);
    }

    @Override public void openSettings() {
        closeMyView();
        showSettings();
    }

    @Override public void closeMy() {
        closeMyView();
    }

    private void openMyView() {
        if (myView != null) return;
        MyView view = new MyView(this, api, extras, cookies, this);
        myView = view;
        view.setTranslationX(-getResources().getDisplayMetrics().widthPixels);
        root.addView(view, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        view.animate().translationX(0).setDuration(240).start();
        tabBar.setHidden(true, true);
        if (feed != null) feed.onPauseFeed();
    }

    private void closeMyView() {
        if (myView == null) return;
        MyView view = myView;
        myView = null;
        view.animate().translationX(-getResources().getDisplayMetrics().widthPixels)
            .setDuration(200).withEndAction(() -> {
                root.removeView(view);
                view.destroy();
                if (moduleView == null) {
                    tabBar.setHidden(toolbarHidden, false);
                }
                if (feed != null) feed.onResumeFeed();
            }).start();
    }

    private void openModuleView(ModuleView.Type type, long targetId, String title) {
        if (moduleView != null) {
            root.removeView(moduleView);
            moduleView.destroy();
            moduleView = null;
        }
        ModuleView view = new ModuleView(this, api, extras, type, targetId, title,
            new ModuleView.Listener() {
                @Override public void onItem(ModuleItem item) {
                    if (item == null || item.kind == ModuleItem.Kind.MESSAGE) return;
                    if (item.kind == ModuleItem.Kind.SEASON) {
                        openModuleView(ModuleView.Type.SEASON, item.seasonId, item.title);
                    } else {
                        openPlayer(item.toVideo(), null);
                    }
                }

                @Override public void onLogin() {
                    showLogin();
                }

                @Override public void onClose() {
                    closeModuleView();
                }
            });
        moduleView = view;
        root.addView(view, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        tabBar.setHidden(true, true);
        if (feed != null) feed.onPauseFeed();
    }

    private void closeModuleView() {
        if (moduleView == null) return;
        ModuleView view = moduleView;
        moduleView = null;
        root.removeView(view);
        view.destroy();
        if (myView == null) {
            tabBar.setHidden(toolbarHidden, false);
        }
        if (feed != null) feed.onResumeFeed();
    }

    private void showSettings() {
        String theme = NativeTheme.themeMode(this);
        boolean loggedIn = cookies.loggedIn();
        String[] items = {
            "外观：" + ("dark".equals(theme) ? "深色" : "light".equals(theme) ? "浅色" : "跟随系统"),
            "默认清晰度：" + qualityLabel(NativeTheme.quality(this)),
            loggedIn ? "退出登录" : "扫码登录",
            "关于 O11A1"
        };
        new AlertDialog.Builder(this)
            .setTitle("设置")
            .setItems(items, (dialog, which) -> new android.os.Handler(
                android.os.Looper.getMainLooper()).postDelayed(() -> {
                    if (which == 0) chooseTheme();
                    else if (which == 1) chooseQuality();
                    else if (which == 2) {
                        if (loggedIn) {
                            cookies.clear();
                            Toast.makeText(this, "已退出登录", Toast.LENGTH_SHORT).show();
                        } else {
                            showLogin();
                        }
                    } else {
                        new AlertDialog.Builder(this)
                            .setMessage("O11A1 0.5.0 (108)\n纯原生 · 无 WebView")
                            .setPositiveButton("好", null)
                            .show();
                    }
                }, 150))
            .show();
    }

    private void showLogin() {
        LoginDialog.show(this, api, () -> {
            Toast.makeText(this, "登录成功", Toast.LENGTH_SHORT).show();
            if (following != null) following.reload();
            if (dynamic != null) dynamic.reload();
            if (moduleView != null) moduleView.reload();
            if (myView != null) myView.reload();
            if (feed != null) feed.onResumeFeed();
        });
    }

    private void chooseTheme() {
        String[] labels = {"跟随系统", "浅色", "深色"};
        String[] values = {"system", "light", "dark"};
        int checked = 0;
        String current = NativeTheme.themeMode(this);
        for (int i = 0; i < values.length; i++) if (values[i].equals(current)) checked = i;
        new AlertDialog.Builder(this)
            .setTitle("外观")
            .setSingleChoiceItems(labels, checked, (dialog, which) -> {
                NativeTheme.setThemeMode(this, values[which]);
                dialog.dismiss();
                recreate();
            })
            .show();
    }

    private void chooseQuality() {
        String[] labels = {"1080P", "720P", "480P"};
        int[] values = {80, 64, 32};
        int checked = 1;
        int current = NativeTheme.quality(this);
        for (int i = 0; i < values.length; i++) if (values[i] == current) checked = i;
        new AlertDialog.Builder(this)
            .setTitle("默认清晰度")
            .setSingleChoiceItems(labels, checked, (dialog, which) -> {
                NativeTheme.setQuality(this, values[which]);
                dialog.dismiss();
                Toast.makeText(this, "已设为 " + labels[which], Toast.LENGTH_SHORT).show();
            })
            .show();
    }
    private static String qualityLabel(int qn) {
        if (qn >= 80) return "1080P";
        if (qn >= 64) return "720P";
        if (qn >= 32) return "480P";
        return "360P";
    }

    @Override public void onUserLeaveHint() {
        if (overlay != null && overlay.isPlaying() && Build.VERSION.SDK_INT >= 26) {
            PictureInPictureParams.Builder builder = new PictureInPictureParams.Builder()
                .setAspectRatio(new Rational(16, 9));
            enterPictureInPictureMode(builder.build());
        }
        super.onUserLeaveHint();
    }

    @Override public void onPictureInPictureModeChanged(boolean inPip, Configuration config) {
        super.onPictureInPictureModeChanged(inPip, config);
        if (overlay != null) overlay.setPipMode(inPip);
        content.setVisibility(inPip ? View.GONE : View.VISIBLE);
        tabBar.setVisibility(inPip ? View.GONE : View.VISIBLE);
        root.setBackgroundColor(inPip ? Color.BLACK : NativeTheme.background(this));
        if (!inPip && isFinishing() && overlay != null) overlay.close();
    }

    @Override protected void onPause() {
        super.onPause();
        if (feed != null && !isInPictureInPictureMode()) feed.onPauseFeed();
    }

    @Override protected void onStop() {
        super.onStop();
        if (overlay != null && !isInPictureInPictureMode() && isFinishing()) {
            overlay.close();
        }
    }

    @Override protected void onResume() {
        super.onResume();
        if (feed != null && !isInPictureInPictureMode()) feed.onResumeFeed();
    }

    @Override public void onBackPressed() {
        if (myView != null) {
            closeMyView();
            return;
        }
        if (moduleView != null) {
            closeModuleView();
            return;
        }
        if (feed != null && feed.isSearchOpen()) {
            feed.closeSearchFromHost();
            return;
        }
        if (overlay != null) {
            overlay.close();
            return;
        }
        super.onBackPressed();
    }

    @Override protected void onDestroy() {
        if (feed != null) feed.destroy();
        if (fish != null) fish.destroy();
        if (myView != null) {
            myView.destroy();
            myView = null;
        }
        if (moduleView != null) {
            moduleView.destroy();
            moduleView = null;
        }
        if (overlay != null) {
            overlay.destroy();
            overlay = null;
        }
        super.onDestroy();
    }
}
