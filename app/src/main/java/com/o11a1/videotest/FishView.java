package com.o11a1.videotest;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.text.InputType;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import org.json.JSONObject;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class FishView extends FrameLayout {
    private final Context context;
    private final BiliExtras extras;
    private final SharedPreferences prefs;
    private final ExecutorService pool = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private final EditText endpoint;
    private final EditText apiKey;
    private final EditText model;
    private final EditText prompt;
    private final TextView output;
    private final Button run;

    FishView(Context context, BiliExtras extras) {
        super(context);
        this.context = context;
        this.extras = extras;
        this.prefs = context.getSharedPreferences("o11a1_native_ui", Context.MODE_PRIVATE);
        setBackgroundColor(NativeTheme.background(context));

        ScrollView scroll = new ScrollView(context);
        addView(scroll, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        LinearLayout root = new LinearLayout(context);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(NativeTheme.dp(context, 22), statusBar() + NativeTheme.dp(context, 18),
            NativeTheme.dp(context, 22), NativeTheme.dp(context, 30));
        scroll.addView(root, new ScrollView.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));

        TextView title = new TextView(context);
        title.setText("AI 养鱼");
        title.setTextColor(NativeTheme.foreground(context));
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 26);
        title.setTypeface(NativeTheme.titleTypeface());
        root.addView(title);

        TextView hint = new TextView(context);
        hint.setText("OpenAI 兼容接口 · 真实请求 · 结果只在本机显示\n没有 API Key 时不会伪造结果");
        hint.setTextColor(NativeTheme.secondary(context));
        hint.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        hint.setPadding(0, NativeTheme.dp(context, 6), 0, NativeTheme.dp(context, 16));
        root.addView(hint);

        endpoint = field(root, "API 地址", "https://api.deepseek.com/chat/completions", false);
        apiKey = field(root, "API Key", "sk-...", true);
        model = field(root, "模型", "deepseek-chat", false);
        prompt = field(root, "饲料 / 提示词",
            "用三句话点评今天 B 站最热的一条视频，并给出一个养鱼式的比喻。", false);
        prompt.setSingleLine(false);
        prompt.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        prompt.setMinLines(4);
        prompt.setGravity(Gravity.TOP);

        run = new Button(context);
        run.setText("生成");
        run.setAllCaps(false);
        run.setTextColor(Color.WHITE);
        run.setTypeface(NativeTheme.titleTypeface());
        run.setBackground(NativeTheme.rounded(NativeTheme.ACCENT, NativeTheme.dp(context, 16)));
        run.setOnClickListener(v -> generate());
        LinearLayout.LayoutParams runParams = new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, NativeTheme.dp(context, 48));
        runParams.topMargin = NativeTheme.dp(context, 8);
        root.addView(run, runParams);

        output = new TextView(context);
        output.setTextColor(NativeTheme.foreground(context));
        output.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14);
        output.setLineSpacing(0, 1.25f);
        output.setTextIsSelectable(true);
        output.setPadding(NativeTheme.dp(context, 14), NativeTheme.dp(context, 14),
            NativeTheme.dp(context, 14), NativeTheme.dp(context, 14));
        output.setBackground(NativeTheme.glassPanel(context, NativeTheme.dp(context, 16)));
        output.setText("等待投喂。");
        LinearLayout.LayoutParams outputParams = new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        outputParams.topMargin = NativeTheme.dp(context, 16);
        root.addView(output, outputParams);

        endpoint.setText(prefs.getString("ai_endpoint", endpoint.getHint().toString()));
        apiKey.setText(prefs.getString("ai_key", ""));
        model.setText(prefs.getString("ai_model", model.getHint().toString()));
        prompt.setText(prefs.getString("ai_prompt", prompt.getHint().toString()));
    }

    private EditText field(LinearLayout parent, String label, String hint, boolean secret) {
        TextView title = new TextView(context);
        title.setText(label);
        title.setTextColor(NativeTheme.secondary(context));
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
            LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
        titleParams.topMargin = NativeTheme.dp(context, 10);
        parent.addView(title, titleParams);

        EditText edit = new EditText(context);
        edit.setHint(hint);
        edit.setTextColor(NativeTheme.foreground(context));
        edit.setHintTextColor(NativeTheme.tertiary(context));
        edit.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13);
        edit.setSingleLine(true);
        edit.setInputType(secret
            ? InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD
            : InputType.TYPE_CLASS_TEXT);
        edit.setPadding(NativeTheme.dp(context, 12), NativeTheme.dp(context, 8),
            NativeTheme.dp(context, 12), NativeTheme.dp(context, 8));
        edit.setBackground(NativeTheme.rounded(
            NativeTheme.isDark(context) ? 0x22FFFFFF : 0x0D000000,
            NativeTheme.dp(context, 12)));
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
            LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        params.topMargin = NativeTheme.dp(context, 4);
        parent.addView(edit, params);
        return edit;
    }

    private int statusBar() {
        int id = getResources().getIdentifier("status_bar_height", "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : NativeTheme.dp(context, 24);
    }

    private void generate() {
        String endpointValue = endpoint.getText().toString().trim();
        String keyValue = apiKey.getText().toString().trim();
        String modelValue = model.getText().toString().trim();
        String promptValue = prompt.getText().toString().trim();
        prefs.edit()
            .putString("ai_endpoint", endpointValue)
            .putString("ai_key", keyValue)
            .putString("ai_model", modelValue)
            .putString("ai_prompt", promptValue)
            .apply();
        if (keyValue.isEmpty()) {
            output.setText("需要先填写 API Key。\n这里不会在没 Key 时伪造结果。");
            return;
        }
        if (promptValue.isEmpty()) {
            output.setText("先写点饲料 / 提示词。");
            return;
        }
        run.setEnabled(false);
        run.setText("生成中…");
        output.setText("正在请求 AI…");
        pool.execute(() -> {
            JSONObject result = extras.aiChat(endpointValue, keyValue, modelValue, promptValue);
            final JSONObject value = result;
            main.post(() -> {
                run.setEnabled(true);
                run.setText("生成");
                if (value == null || !value.optBoolean("ok", false)) {
                    output.setText("请求失败：\n" + (value == null ? "接口无响应" : value.optString("error", "未知错误")));
                } else {
                    String text = value.optString("text", "");
                    output.setText(text.isEmpty() ? "AI 返回了空内容。" : text);
                }
            });
        });
    }

    void destroy() {
        pool.shutdownNow();
        main.removeCallbacksAndMessages(null);
    }
}
