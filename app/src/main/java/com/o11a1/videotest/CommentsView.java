package com.o11a1.videotest;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.bitmap.CircleCrop;

import org.json.JSONArray;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class CommentsView {
    private final Context context;
    private final BiliApi api;
    private final BiliExtras extras;
    private final long aid;
    private final Dialog dialog;
    private final RecyclerView list;
    private final TextView status;
    private final EditText input;
    private final CommentAdapter adapter;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private int page = 1;
    private boolean loading = false;

    static void show(Context context, BiliApi api, BiliExtras extras, long aid) {
        new CommentsView(context, api, extras, aid).open();
    }

    private CommentsView(Context context, BiliApi api, BiliExtras extras, long aid) {
        this.context = context;
        this.api = api;
        this.extras = extras;
        this.aid = aid;
        dialog = new Dialog(context);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setCanceledOnTouchOutside(true);
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawable(
                new android.graphics.drawable.ColorDrawable(Color.TRANSPARENT));
        }

        LinearLayout root = new LinearLayout(context);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackground(NativeTheme.rounded(NativeTheme.background(context), NativeTheme.dp(context, 20)));
        root.setPadding(0, 0, 0, 0);

        LinearLayout header = new LinearLayout(context);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.setPadding(NativeTheme.dp(context, 16), NativeTheme.dp(context, 12),
            NativeTheme.dp(context, 8), NativeTheme.dp(context, 8));
        root.addView(header, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        TextView title = new TextView(context);
        title.setText("评论");
        title.setTextColor(NativeTheme.foreground(context));
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 17);
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
        status.setVisibility(View.GONE);
        root.addView(status, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        list = new RecyclerView(context);
        list.setLayoutManager(new LinearLayoutManager(context));
        list.setBackgroundColor(Color.TRANSPARENT);
        adapter = new CommentAdapter(context);
        list.setAdapter(adapter);
        list.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override public void onScrolled(RecyclerView recyclerView, int dx, int dy) {
                if (!recyclerView.canScrollVertically(1)) load();
            }
        });
        root.addView(list, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        LinearLayout composer = new LinearLayout(context);
        composer.setOrientation(LinearLayout.HORIZONTAL);
        composer.setGravity(Gravity.CENTER_VERTICAL);
        composer.setPadding(NativeTheme.dp(context, 16), NativeTheme.dp(context, 8),
            NativeTheme.dp(context, 16), NativeTheme.dp(context, 12));
        root.addView(composer, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        input = new EditText(context);
        input.setHint("发一条友善的评论");
        input.setSingleLine(true);
        input.setTextColor(NativeTheme.foreground(context));
        input.setHintTextColor(NativeTheme.tertiary(context));
        input.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13);
        input.setImeOptions(EditorInfo.IME_ACTION_SEND);
        input.setPadding(NativeTheme.dp(context, 12), 0, NativeTheme.dp(context, 12), 0);
        input.setBackground(NativeTheme.rounded(
            NativeTheme.isDark(context) ? 0x22FFFFFF : 0x0D000000,
            NativeTheme.dp(context, 18)));
        LinearLayout.LayoutParams inputParams = new LinearLayout.LayoutParams(
            0, NativeTheme.dp(context, 38), 1f);
        composer.addView(input, inputParams);

        TextView send = new TextView(context);
        send.setText("发送");
        send.setTextColor(NativeTheme.ACCENT);
        send.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13);
        send.setGravity(Gravity.CENTER);
        send.setPadding(NativeTheme.dp(context, 12), 0, 0, 0);
        send.setOnClickListener(v -> sendComment());
        composer.addView(send, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT, NativeTheme.dp(context, 38)));

        dialog.setContentView(root);
        dialog.setOnDismissListener(d -> destroy());
    }

    private void open() {
        dialog.show();
        Window window = dialog.getWindow();
        if (window != null) {
            WindowManager.LayoutParams params = new WindowManager.LayoutParams();
            params.copyFrom(window.getAttributes());
            params.width = ViewGroup.LayoutParams.MATCH_PARENT;
            params.height = Math.round(context.getResources().getDisplayMetrics().heightPixels * 0.72f);
            params.gravity = Gravity.BOTTOM;
            window.setAttributes(params);
        }
        load();
    }

    private void load() {
        if (loading) return;
        loading = true;
        if (adapter.getItemCount() == 0) {
            status.setText("正在加载评论…");
            status.setVisibility(View.VISIBLE);
        }
        final int request = page;
        pool.execute(() -> {
            JSONObject result = api.comments(aid, request);
            final JSONObject value = result;
            main.post(() -> {
                loading = false;
                if (value == null || !value.optBoolean("ok", false)) {
                    status.setText(value == null ? "评论加载失败" : value.optString("error", "评论加载失败"));
                    status.setVisibility(View.VISIBLE);
                    return;
                }
                List<CommentItem> rows = new ArrayList<>();
                JSONArray array = value.optJSONArray("items");
                if (array != null) {
                    for (int i = 0; i < array.length(); i++) {
                        JSONObject row = array.optJSONObject(i);
                        if (row != null) rows.add(CommentItem.from(row));
                    }
                }
                adapter.append(rows);
                page += 1;
                status.setVisibility(rows.isEmpty() && adapter.getItemCount() == 0 ? View.VISIBLE : View.GONE);
                if (rows.isEmpty() && adapter.getItemCount() == 0) status.setText("还没有评论");
            });
        });
    }

    private void sendComment() {
        String text = input.getText().toString().trim();
        if (text.isEmpty()) return;
        input.setText("");
        pool.execute(() -> {
            JSONObject result = extras.sendComment(aid, text);
            final JSONObject value = result;
            main.post(() -> {
                if (value == null || !value.optBoolean("ok", false)) {
                    input.setText(text);
                    status.setText(value == null ? "发送失败" : value.optString("error", "发送失败"));
                    status.setVisibility(View.VISIBLE);
                } else {
                    adapter.setItems(new ArrayList<>());
                    page = 1;
                    load();
                }
            });
        });
    }

    private void dismiss() {
        if (dialog.isShowing()) dialog.dismiss();
    }

    private void destroy() {
        pool.shutdownNow();
        main.removeCallbacksAndMessages(null);
    }

    static final class CommentItem {
        String user = "";
        String avatar = "";
        String message = "";
        int like = 0;
        long time = 0;

        static CommentItem from(JSONObject json) {
            CommentItem item = new CommentItem();
            item.user = json.optString("user", "用户");
            item.avatar = json.optString("avatar", "");
            item.message = json.optString("message", "");
            item.like = json.optInt("like", 0);
            item.time = json.optLong("time", 0);
            return item;
        }
    }

    private static final class CommentAdapter extends RecyclerView.Adapter<CommentHolder> {
        private final Context context;
        private final List<CommentItem> items = new ArrayList<>();

        CommentAdapter(Context context) {
            this.context = context;
        }

        void setItems(List<CommentItem> values) {
            items.clear();
            if (values != null) items.addAll(values);
            notifyDataSetChanged();
        }

        void append(List<CommentItem> values) {
            if (values == null || values.isEmpty()) return;
            int start = items.size();
            items.addAll(values);
            notifyItemRangeInserted(start, values.size());
        }

        int getItemCountSafe() {
            return items.size();
        }

        @Override public int getItemCount() {
            return items.size();
        }

        @androidx.annotation.NonNull
        @Override public CommentHolder onCreateViewHolder(@androidx.annotation.NonNull ViewGroup parent, int viewType) {
            CommentRow row = new CommentRow(context);
            row.setLayoutParams(new RecyclerView.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
            return new CommentHolder(row);
        }

        @Override public void onBindViewHolder(@androidx.annotation.NonNull CommentHolder holder, int position) {
            holder.row.setItem(items.get(position));
        }
    }

    private static final class CommentHolder extends RecyclerView.ViewHolder {
        final CommentRow row;
        CommentHolder(CommentRow row) {
            super(row);
            this.row = row;
        }
    }

    private static final class CommentRow extends LinearLayout {
        private final ImageView avatar = new ImageView(getContext());
        private final TextView name = new TextView(getContext());
        private final TextView message = new TextView(getContext());
        private final TextView meta = new TextView(getContext());

        CommentRow(Context context) {
            super(context);
            setOrientation(HORIZONTAL);
            setPadding(NativeTheme.dp(context, 16), NativeTheme.dp(context, 10),
                NativeTheme.dp(context, 16), NativeTheme.dp(context, 10));

            avatar.setBackgroundColor(0xFF141414);
            addView(avatar, new LinearLayout.LayoutParams(
                NativeTheme.dp(context, 36), NativeTheme.dp(context, 36)));

            LinearLayout body = new LinearLayout(context);
            body.setOrientation(VERTICAL);
            LinearLayout.LayoutParams bodyParams = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
            bodyParams.leftMargin = NativeTheme.dp(context, 10);
            addView(body, bodyParams);

            name.setTextColor(NativeTheme.secondary(context));
            name.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            body.addView(name);

            message.setTextColor(NativeTheme.foreground(context));
            message.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
            message.setLineSpacing(0, 1.15f);
            LinearLayout.LayoutParams messageParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            messageParams.topMargin = NativeTheme.dp(context, 4);
            body.addView(message, messageParams);

            meta.setTextColor(NativeTheme.tertiary(context));
            meta.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
            LinearLayout.LayoutParams metaParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            metaParams.topMargin = NativeTheme.dp(context, 6);
            body.addView(meta, metaParams);
        }

        void setItem(CommentItem item) {
            name.setText(item.user);
            message.setText(item.message);
            String time = "";
            if (item.time > 0) {
                long seconds = item.time > 100000000000L ? item.time / 1000 : item.time;
                time = new SimpleDateFormat("MM-dd HH:mm", Locale.CHINA)
                    .format(new Date(seconds * 1000));
            }
            meta.setText((time.isEmpty() ? "" : time + " · ") + "赞 " + item.like);
            if (item.avatar == null || item.avatar.isEmpty()) {
                avatar.setImageResource(android.R.drawable.sym_def_app_icon);
            } else {
                Glide.with(this).load(item.avatar).transform(new CircleCrop()).into(avatar);
            }
        }
    }
}
