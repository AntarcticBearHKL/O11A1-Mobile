package com.o11a1.videotest;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class SearchView extends FrameLayout {
    interface OnOpen {
        void open(VideoItem item);
    }

    private final BiliApi api;
    private final OnOpen onOpen;
    private final Runnable onClose;
    private final EditText field;
    private final RecyclerView list;
    private final VideoRowAdapter adapter;
    private final TextView status;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private final Runnable searchRunnable = this::searchNow;
    private int token = 0;

    SearchView(Context context, BiliApi api, OnOpen onOpen, Runnable onClose) {
        super(context);
        this.api = api;
        this.onOpen = onOpen;
        this.onClose = onClose;
        setBackgroundColor(NativeTheme.background(context));
        setClickable(true);

        LinearLayout top = new LinearLayout(context);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        top.setPadding(NativeTheme.dp(context, 8), 0, NativeTheme.dp(context, 12), 0);
        addView(top, new LayoutParams(LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 56)));

        ImageButton back = new ImageButton(context);
        back.setImageResource(R.drawable.ic_back);
        back.setBackgroundColor(Color.TRANSPARENT);
        back.setColorFilter(NativeTheme.foreground(context));
        back.setOnClickListener(v -> onClose.run());
        top.addView(back, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 44), NativeTheme.dp(context, 44)));

        field = new EditText(context);
        field.setSingleLine(true);
        field.setHint("搜索视频、UP 主");
        field.setTextColor(NativeTheme.foreground(context));
        field.setHintTextColor(NativeTheme.secondary(context));
        field.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        field.setImeOptions(EditorInfo.IME_ACTION_SEARCH);
        field.setPadding(NativeTheme.dp(context, 14), 0, NativeTheme.dp(context, 14), 0);
        field.setBackground(NativeTheme.rounded(
            NativeTheme.isDark(context) ? 0x22FFFFFF : 0x0D000000,
            NativeTheme.dp(context, 14)));
        LinearLayout.LayoutParams fieldParams = new LinearLayout.LayoutParams(
            0, NativeTheme.dp(context, 42), 1f);
        top.addView(field, fieldParams);

        status = new TextView(context);
        status.setTextColor(NativeTheme.secondary(context));
        status.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13);
        status.setGravity(Gravity.CENTER);
        status.setVisibility(View.GONE);
        LayoutParams statusParams = new LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        statusParams.gravity = Gravity.CENTER;
        addView(status, statusParams);

        list = new RecyclerView(context);
        list.setLayoutManager(new LinearLayoutManager(context));
        list.setBackgroundColor(Color.TRANSPARENT);
        adapter = new VideoRowAdapter(context, (item, source) -> {
            hideKeyboard();
            onOpen.open(item);
        });
        list.setAdapter(adapter);
        LayoutParams listParams = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        listParams.topMargin = NativeTheme.dp(context, 56);
        addView(list, listParams);

        field.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                main.removeCallbacks(searchRunnable);
                main.postDelayed(searchRunnable, 320);
            }
            @Override public void afterTextChanged(Editable s) {}
        });
        field.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                main.removeCallbacks(searchRunnable);
                searchNow();
                hideKeyboard();
                return true;
            }
            return false;
        });

        setOnApplyWindowInsetsListener((v, insets) -> {
            int insetTop = insets.getSystemWindowInsetTop();
            v.setPadding(0, insetTop, 0, 0);
            listParams.topMargin = NativeTheme.dp(context, 56);
            return insets;
        });
    }

    void focus() {
        field.requestFocus();
        field.postDelayed(() -> {
            InputMethodManager imm = (InputMethodManager) getContext()
                .getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) imm.showSoftInput(field, InputMethodManager.SHOW_IMPLICIT);
        }, 120);
    }

    private void hideKeyboard() {
        InputMethodManager imm = (InputMethodManager) getContext()
            .getSystemService(Context.INPUT_METHOD_SERVICE);
        if (imm != null) imm.hideSoftInputFromWindow(field.getWindowToken(), 0);
    }

    private void searchNow() {
        String term = field.getText().toString().trim();
        if (term.isEmpty()) {
            adapter.setItems(new ArrayList<>());
            status.setVisibility(View.GONE);
            return;
        }
        token += 1;
        final int current = token;
        status.setText("搜索中…");
        status.setVisibility(View.VISIBLE);
        pool.execute(() -> {
            JSONObject result = api.search(term, 1);
            final List<VideoItem> rows = new ArrayList<>();
            if (result != null && result.optBoolean("ok", false)) {
                JSONArray array = result.optJSONArray("items");
                if (array != null) {
                    for (int i = 0; i < array.length(); i++) {
                        JSONObject row = array.optJSONObject(i);
                        if (row != null) rows.add(VideoItem.from(row));
                    }
                }
            }
            main.post(() -> {
                if (current != token) return;
                adapter.setItems(rows);
                status.setText(rows.isEmpty() ? "没有找到相关视频" : "");
                status.setVisibility(rows.isEmpty() ? View.VISIBLE : View.GONE);
            });
        });
    }

    void destroy() {
        token += 1;
        main.removeCallbacks(searchRunnable);
        pool.shutdownNow();
    }
}
