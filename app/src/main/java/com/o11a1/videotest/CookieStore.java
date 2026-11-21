package com.o11a1.videotest;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.util.Log;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.zip.GZIPInputStream;
import java.util.zip.Inflater;

/** Persisted Bilibili cookie jar plus shared HTTP helpers. */
final class CookieStore {
    private static final String TAG = "O11A1Cookie";
    private static final String PREFS = "o11a1_native";
    private static final String KEY_COOKIES = "cookies";
    private static final String KEY_BUVID = "buvid";
    private static final String UA = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36";
    private final SharedPreferences prefs;
    private final Map<String, String> cookies = new LinkedHashMap<>();
    private final ThreadLocal<Boolean> ensuringBuvid = ThreadLocal.withInitial(() -> false);

    CookieStore(Context context) {
        prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        load();
    }

    private void load() {
        String raw = prefs.getString(KEY_COOKIES, "");
        if (TextUtils.isEmpty(raw)) return;
        for (String part : raw.split(";")) {
            String[] pair = part.trim().split("=", 2);
            if (pair.length == 2) cookies.put(pair[0], pair[1]);
        }
    }

    synchronized String header() {
        StringBuilder out = new StringBuilder();
        for (Map.Entry<String, String> entry : cookies.entrySet()) {
            if (out.length() > 0) out.append("; ");
            out.append(entry.getKey()).append('=').append(entry.getValue());
        }
        return out.toString();
    }

    synchronized boolean loggedIn() {
        String sess = cookies.get("SESSDATA");
        return sess != null && !sess.isEmpty();
    }

    synchronized String get(String name) {
        return cookies.get(name);
    }

    synchronized void put(String name, String value) {
        if (name == null || name.isEmpty()) return;
        cookies.put(name, value == null ? "" : value);
        persist();
    }

    synchronized void clear() {
        cookies.clear();
        prefs.edit().remove(KEY_COOKIES).remove(KEY_BUVID).apply();
    }

    private void persist() {
        StringBuilder raw = new StringBuilder();
        for (Map.Entry<String, String> entry : cookies.entrySet()) {
            if (raw.length() > 0) raw.append("; ");
            raw.append(entry.getKey()).append('=').append(entry.getValue());
        }
        prefs.edit().putString(KEY_COOKIES, raw.toString()).apply();
    }

    synchronized void ensureBuvid() {
        if (cookies.containsKey("buvid3")) return;
        if (Boolean.TRUE.equals(ensuringBuvid.get())) return;
        ensuringBuvid.set(true);
        try {
            String json = request("https://api.bilibili.com/x/frontend/finger/spi", null, null);
            JSONObject data = new JSONObject(json).optJSONObject("data");
            if (data != null) {
                String b3 = data.optString("b_3", "");
                String b4 = data.optString("b_4", "");
                if (!b3.isEmpty()) cookies.put("buvid3", b3);
                if (!b4.isEmpty()) cookies.put("buvid4", b4);
                persist();
                Log.i(TAG, "buvid ready");
            }
        } catch (Throwable error) {
            String fallback = java.util.UUID.randomUUID().toString().replace("-", "") + "infoc";
            cookies.put("buvid3", fallback);
            persist();
            Log.w(TAG, "buvid fallback", error);
        } finally {
            ensuringBuvid.set(false);
        }
    }

    void absorbSetCookies(Map<String, List<String>> fields) {
        if (fields == null) return;
        for (Map.Entry<String, List<String>> entry : fields.entrySet()) {
            if (entry.getKey() == null || !"set-cookie".equalsIgnoreCase(entry.getKey())) continue;
            for (String value : entry.getValue()) {
                String[] first = value.split(";", 2)[0].split("=", 2);
                if (first.length == 2) cookies.put(first[0].trim(), first[1].trim());
            }
        }
        persist();
    }

    String request(String url, Map<String, String> extraHeaders, String method) throws Exception {
        ensureBuvid();
        HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
        connection.setConnectTimeout(12000);
        connection.setReadTimeout(20000);
        connection.setInstanceFollowRedirects(true);
        connection.setRequestMethod(method == null ? "GET" : method);
        connection.setRequestProperty("User-Agent", UA);
        connection.setRequestProperty("Referer", "https://www.bilibili.com/");
        connection.setRequestProperty("Accept", "application/json, text/plain, */*");
        connection.setRequestProperty("Accept-Encoding", "identity");
        String cookie = header();
        if (!cookie.isEmpty()) connection.setRequestProperty("Cookie", cookie);
        if (extraHeaders != null) {
            for (Map.Entry<String, String> e : extraHeaders.entrySet()) connection.setRequestProperty(e.getKey(), e.getValue());
        }
        int code = connection.getResponseCode();
        InputStream in = code >= 400 ? connection.getErrorStream() : connection.getInputStream();
        StringBuilder body = new StringBuilder();
        if (in != null) {
            String encoding = connection.getContentEncoding();
            if (encoding == null) encoding = connection.getHeaderField("Content-Encoding");
            InputStream decoded = in;
            try {
                if (encoding != null && encoding.toLowerCase().contains("gzip")) {
                    decoded = new GZIPInputStream(in);
                } else if (encoding != null && encoding.toLowerCase().contains("deflate")) {
                    byte[] compressed = readAll(in);
                    byte[] plain;
                    try {
                        plain = inflate(compressed, false);
                    } catch (Throwable first) {
                        plain = inflate(compressed, true);
                    }
                    decoded = new ByteArrayInputStream(plain);
                }
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(decoded, StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) body.append(line).append('\n');
                }
            } finally {
                try { in.close(); } catch (Throwable ignored) {}
            }
        }
        Map<String, List<String>> fields = connection.getHeaderFields();
        absorbSetCookies(fields);
        connection.disconnect();
        if (code >= 400) Log.w(TAG, "HTTP " + code + " for " + url);
        return body.toString();
    }

    private static byte[] readAll(InputStream in) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buffer = new byte[8192];
        int read;
        while ((read = in.read(buffer)) >= 0) out.write(buffer, 0, read);
        return out.toByteArray();
    }

    private static byte[] inflate(byte[] data, boolean nowrap) throws Exception {
        Inflater inflater = new Inflater(nowrap);
        try {
            inflater.setInput(data);
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            while (!inflater.finished()) {
                int read = inflater.inflate(buffer);
                if (read == 0) {
                    if (inflater.needsInput() || inflater.needsDictionary()) break;
                }
                out.write(buffer, 0, read);
            }
            return out.toByteArray();
        } finally {
            inflater.end();
        }
    }
}
