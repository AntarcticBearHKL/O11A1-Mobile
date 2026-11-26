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
import android.widget.ImageView;
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

    private final Context context;
    private final BiliApi api;
    private final OnOpen onOpen;
    private final Runnable onClose;
    private final EditText field;
    private final RecyclerView list;
    private final RecyclerView suggestionList;
    private final ResultAdapter adapter;
    private final SuggestionAdapter suggestionAdapter;
    private final TextView status;
    private final TextView sectionLabel;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private final Runnable suggestRunnable = this::suggestNow;
    private final List<String> hot = new ArrayList<>();
    private boolean hotLoaded = false;
    private int mode = 0;
    private int token = 0;

    SearchView(Context context, BiliApi api, OnOpen onOpen, Runnable onClose) {
        super(context);
        this.context = context;
        this.api = api;
        this.onOpen = onOpen;
        this.onClose = onClose;
        setBackgroundColor(NativeTheme.background(context));
        setClickable(true);

        LinearLayout top = new LinearLayout(context);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        top.setPadding(NativeTheme.dp(context, 8), 0, NativeTheme.dp(context, 12), 0);
        addView(top, new LayoutParams(LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 64)));

        ImageButton back = new ImageButton(context);
        back.setImageResource(R.drawable.ic_back);
        back.setBackgroundColor(Color.TRANSPARENT);
        back.setColorFilter(NativeTheme.foreground(context));
        back.setOnClickListener(v -> onClose.run());
        top.addView(back, new LinearLayout.LayoutParams(
            NativeTheme.dp(context, 44), NativeTheme.dp(context, 44)));

        FrameLayout searchBox = new FrameLayout(context);
        searchBox.setBackground(NativeTheme.rounded(
            NativeTheme.isDark(context) ? 0x22FFFFFF : 0x0D000000,
            NativeTheme.dp(context, 18)));
        ImageView magnifier = new ImageView(context);
        magnifier.setImageResource(R.drawable.ic_nav_search);
        magnifier.setColorFilter(NativeTheme.secondary(context));
        FrameLayout.LayoutParams magParams = new FrameLayout.LayoutParams(
            NativeTheme.dp(context, 19), NativeTheme.dp(context, 19));
        magParams.gravity = Gravity.START | Gravity.CENTER_VERTICAL;
        magParams.leftMargin = NativeTheme.dp(context, 14);
        searchBox.addView(magnifier, magParams);

        field = new EditText(context);
        field.setSingleLine(true);
        field.setHint("搜索视频 / UP / 番剧");
        field.setTextColor(NativeTheme.foreground(context));
        field.setHintTextColor(NativeTheme.secondary(context));
        field.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
        field.setImeOptions(EditorInfo.IME_ACTION_SEARCH);
        field.setPadding(NativeTheme.dp(context, 40), 0, NativeTheme.dp(context, 14), 0);
        field.setBackgroundColor(Color.TRANSPARENT);
        searchBox.addView(field, new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        LinearLayout.LayoutParams fieldParams = new LinearLayout.LayoutParams(
            0, NativeTheme.dp(context, 54), 1f);
        top.addView(searchBox, fieldParams);

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
        list.setPadding(0, 0, NativeTheme.dp(context, 8), 0);
        list.setClipToPadding(false);
        adapter = new ResultAdapter();
        list.setAdapter(adapter);
        LayoutParams listParams = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        listParams.topMargin = NativeTheme.dp(context, 64);
        addView(list, listParams);

        sectionLabel = new TextView(context);
        sectionLabel.setTextColor(NativeTheme.secondary(context));
        sectionLabel.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        sectionLabel.setTypeface(NativeTheme.titleTypeface());
        sectionLabel.setVisibility(View.GONE);
        LayoutParams labelParams = new LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        labelParams.topMargin = NativeTheme.dp(context, 72);
        labelParams.leftMargin = NativeTheme.dp(context, 20);
        addView(sectionLabel, labelParams);

        suggestionList = new RecyclerView(context);
        suggestionList.setLayoutManager(new LinearLayoutManager(context));
        suggestionList.setBackgroundColor(Color.TRANSPARENT);
        suggestionAdapter = new SuggestionAdapter(context, value -> {
            main.removeCallbacks(suggestRunnable);
            field.setText(value);
            field.setSelection(value.length());
            hideKeyboard();
            searchNow();
        });
        suggestionList.setAdapter(suggestionAdapter);
        LayoutParams suggestionParams = new LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        suggestionParams.topMargin = NativeTheme.dp(context, 98);
        addView(suggestionList, suggestionParams);

        field.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                main.removeCallbacks(suggestRunnable);
                main.postDelayed(suggestRunnable, 250);
            }
            @Override public void afterTextChanged(Editable s) {}
        });
        field.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                main.removeCallbacks(suggestRunnable);
                searchNow();
                hideKeyboard();
                return true;
            }
            return false;
        });

        loadHot();

        setOnApplyWindowInsetsListener((v, insets) -> {
            int insetTop = insets.getSystemWindowInsetTop();
            v.setPadding(0, insetTop, 0, 0);
            listParams.topMargin = NativeTheme.dp(context, 64);
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

    private void loadHot() {
        if (hotLoaded) {
            if (field.getText().toString().trim().isEmpty()) showHot();
            return;
        }
        pool.execute(() -> {
            JSONObject result = api.searchHot();
            final List<String> values = new ArrayList<>();
            if (result != null && result.optBoolean("ok", false)) {
                JSONArray array = result.optJSONArray("items");
                if (array != null) {
                    for (int i = 0; i < array.length(); i += 1) {
                        JSONObject row = array.optJSONObject(i);
                        if (row == null) continue;
                        String keyword = row.optString("keyword", "");
                        if (!keyword.isEmpty()) values.add(keyword);
                    }
                }
            }
            main.post(() -> {
                hotLoaded = true;
                hot.clear();
                hot.addAll(values);
                if (field.getText().toString().trim().isEmpty() && mode == 0) showHot();
            });
        });
    }

    private void showHot() {
        mode = 0;
        sectionLabel.setText("热搜");
        sectionLabel.setVisibility(hot.isEmpty() ? View.GONE : View.VISIBLE);
        suggestionAdapter.setItems(hot, true);
        suggestionList.setVisibility(View.VISIBLE);
        list.setVisibility(View.GONE);
        status.setVisibility(View.GONE);
        if (hot.isEmpty() && !hotLoaded) loadHot();
    }

    private void suggestNow() {
        String term = field.getText().toString().trim();
        if (term.isEmpty()) {
            showHot();
            return;
        }
        token += 1;
        final int current = token;
        pool.execute(() -> {
            JSONObject result = api.suggest(term);
            final List<String> values = new ArrayList<>();
            if (result != null && result.optBoolean("ok", false)) {
                JSONArray array = result.optJSONArray("items");
                if (array != null) {
                    for (int i = 0; i < array.length(); i += 1) {
                        JSONObject row = array.optJSONObject(i);
                        if (row == null) continue;
                        String value = row.optString("value", "");
                        if (value.isEmpty()) value = row.optString("term", "");
                        if (!value.isEmpty()) values.add(value);
                    }
                }
            }
            main.post(() -> {
                if (current != token) return;
                if (!field.getText().toString().trim().equals(term)) return;
                mode = 1;
                sectionLabel.setText("搜索建议");
                sectionLabel.setVisibility(values.isEmpty() ? View.GONE : View.VISIBLE);
                suggestionAdapter.setItems(values, false);
                suggestionList.setVisibility(View.VISIBLE);
                list.setVisibility(View.GONE);
                status.setVisibility(View.GONE);
            });
        });
    }

    private void showResultsMode() {
        mode = 2;
        sectionLabel.setVisibility(View.GONE);
        suggestionList.setVisibility(View.GONE);
        list.setVisibility(View.VISIBLE);
    }

    private void searchNow() {
        main.removeCallbacks(suggestRunnable);
        String term = field.getText().toString().trim();
        if (term.isEmpty()) {
            showHot();
            return;
        }
        token += 1;
        final int current = token;
        showResultsMode();
        adapter.setItems(new ArrayList<>());
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
                showResultsMode();
                adapter.setItems(rows);
                status.setText(rows.isEmpty() ? "没有找到相关视频" : "");
                status.setVisibility(rows.isEmpty() ? View.VISIBLE : View.GONE);
            });
        });
    }

    void destroy() {
        token += 1;
        main.removeCallbacks(suggestRunnable);
        pool.shutdownNow();
    }

    private final class ResultAdapter extends RecyclerView.Adapter<ResultHolder> {
        private final List<VideoItem> items = new ArrayList<>();

        void setItems(List<VideoItem> values) {
            items.clear();
            if (values != null) items.addAll(values);
            notifyDataSetChanged();
        }

        @Override public ResultHolder onCreateViewHolder(ViewGroup parent, int viewType) {
            HomeCardView card = new HomeCardView(context);
            RecyclerView.LayoutParams params = new RecyclerView.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            params.bottomMargin = NativeTheme.dp(context, 14);
            card.setLayoutParams(params);
            return new ResultHolder(card);
        }

        @Override public void onBindViewHolder(ResultHolder holder, int position) {
            VideoItem item = items.get(position);
            holder.card.setItem(item, () -> {
                hideKeyboard();
                onOpen.open(item);
            }, () -> {
                hideKeyboard();
                onOpen.open(item);
            });
        }

        @Override public int getItemCount() {
            return items.size();
        }
    }

    private static final class ResultHolder extends RecyclerView.ViewHolder {
        final HomeCardView card;

        ResultHolder(HomeCardView card) {
            super(card);
            this.card = card;
        }
    }

    private static final class SuggestionAdapter
        extends RecyclerView.Adapter<SuggestionAdapter.Holder> {
        interface OnPick {
            void pick(String value);
        }

        private final Context context;
        private final List<String> items = new ArrayList<>();
        private final OnPick onPick;
        private boolean hot = false;

        SuggestionAdapter(Context context, OnPick onPick) {
            this.context = context;
            this.onPick = onPick;
        }

        void setItems(List<String> values, boolean hot) {
            this.items.clear();
            this.items.addAll(values);
            this.hot = hot;
            notifyDataSetChanged();
        }

        @Override public Holder onCreateViewHolder(ViewGroup parent, int viewType) {
            TextView view = new TextView(context);
            view.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
            view.setSingleLine(true);
            view.setEllipsize(android.text.TextUtils.TruncateAt.END);
            view.setPadding(NativeTheme.dp(context, 20), NativeTheme.dp(context, 13),
                NativeTheme.dp(context, 20), NativeTheme.dp(context, 13));
            return new Holder(view);
        }

        @Override public void onBindViewHolder(Holder holder, int position) {
            final String value = items.get(position);
            holder.text.setText(hot ? (position + 1) + ".  " + value : value);
            holder.text.setTextColor(hot && position < 3
                ? 0xFFFB7299
                : NativeTheme.foreground(context));
            holder.text.setOnClickListener(v -> onPick.pick(value));
        }

        @Override public int getItemCount() {
            return items.size();
        }

        static final class Holder extends RecyclerView.ViewHolder {
            final TextView text;

            Holder(TextView view) {
                super(view);
                text = view;
            }
        }
    }
}
