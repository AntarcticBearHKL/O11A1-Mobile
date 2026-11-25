package com.o11a1.videotest;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.PictureInPictureParams;
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

public final class MainActivity extends Activity implements FeedView.Host {
    private CookieStore cookies;
    private BiliApi api;
    private BiliExtras extras;
    private FrameLayout root;
    private FrameLayout content;
    private GlassTabBarView tabBar;
    private ImageButton settingsButton;
    private FeedView feed;
    private VideoListView following;
    private VideoListView dynamic;
    private FishView fish;
    private View currentView;
    private PlayerOverlay overlay;
    private boolean toolbarHidden;
    private boolean searchVisible;

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
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
        tabParams.bottomMargin = NativeTheme.dp(this, 12);
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

        showTab(0);
    }

    private int statusBar() {
        int id = getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : NativeTheme.dp(this, 24);
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
                        (item, source) -> openPlayer(item, source));
                }
                currentView = following;
                break;
            case 2:
                if (dynamic == null) {
                    dynamic = new VideoListView(this, extras, VideoListView.Mode.DYNAMIC, 0,
                        (item, source) -> openPlayer(item, source));
                }
                currentView = dynamic;
                break;
            default:
                if (fish == null) fish = new FishView(this);
                currentView = fish;
                break;
        }
        content.addView(currentView, new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        tabBar.select(index, false);
        root.bringChildToFront(tabBar);
        root.bringChildToFront(settingsButton);
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
        settingsButton.animate().alpha(hidden ? 0 : 1).setDuration(350).start();
    }

    @Override public void onSearchVisibility(boolean visible) {
        searchVisible = visible;
        tabBar.setHidden(visible || toolbarHidden, true);
        settingsButton.animate().alpha(visible || toolbarHidden ? 0 : 1).setDuration(250).start();
    }

    private void openPlayer(VideoItem item, View source) {
        if (overlay != null || item == null) return;
        if (feed != null) feed.onPauseFeed();
        tabBar.setHidden(true, true);
        settingsButton.animate().alpha(0).setDuration(250).start();
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
        tabBar.setHidden(toolbarHidden, false);
        settingsButton.animate().alpha(toolbarHidden ? 0 : 1).setDuration(250).start();
        if (feed != null) feed.onResumeFeed();
    }

    private void openProfile(long mid) {
        if (mid <= 0) return;
        if (overlay != null) {
            overlay.close();
        }
        VideoListView view = new VideoListView(this, extras, VideoListView.Mode.SPACE, mid,
            (item, source) -> openPlayer(item, source));
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

    private void showSettings() {
        String theme = NativeTheme.themeMode(this);
        String[] items = {
            "外观：" + ("dark".equals(theme) ? "深色" : "light".equals(theme) ? "浅色" : "跟随系统"),
            "默认清晰度：" + qualityLabel(NativeTheme.quality(this)),
            "退出登录",
            "关于 O11A1"
        };
        new AlertDialog.Builder(this)
            .setTitle("设置")
            .setItems(items, (dialog, which) -> {
                if (which == 0) chooseTheme();
                else if (which == 1) chooseQuality();
                else if (which == 2) {
                    cookies.clear();
                    Toast.makeText(this, "已退出登录", Toast.LENGTH_SHORT).show();
                } else {
                    new AlertDialog.Builder(this)
                        .setMessage("O11A1 0.5.0 (108)\n纯原生 · 无 WebView")
                        .setPositiveButton("好", null)
                        .show();
                }
            })
            .show();
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
        settingsButton.setVisibility(inPip ? View.GONE : View.VISIBLE);
        root.setBackgroundColor(inPip ? Color.BLACK : NativeTheme.background(this));
        if (!inPip && isFinishing() && overlay != null) overlay.close();
    }

    @Override protected void onPause() {
        super.onPause();
        if (feed != null && !isInPictureInPictureMode()) feed.onPauseFeed();
    }

    @Override protected void onResume() {
        super.onResume();
        if (feed != null && !isInPictureInPictureMode()) feed.onResumeFeed();
    }

    @Override public void onBackPressed() {
        if (overlay != null) {
            overlay.close();
            return;
        }
        super.onBackPressed();
    }

    @Override protected void onDestroy() {
        if (feed != null) feed.destroy();
        if (overlay != null) {
            overlay.destroy();
            overlay = null;
        }
        super.onDestroy();
    }
}
