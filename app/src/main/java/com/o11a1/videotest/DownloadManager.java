package com.o11a1.videotest;

import android.content.Context;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Progressive MP4 offline download queue. Files live in app-private storage and play through StreamProxy. */
final class DownloadManager {
    private static final String TAG = "O11A1Download";
    private static final String UA = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36";

    private final Context context;
    private final BiliApi api;
    private final StreamProxy proxy;
    private final CookieStore cookies;
    private final File dir;
    private final File indexFile;
    private final List<JSONObject> items = new ArrayList<>();
    private final Set<String> cancelled = ConcurrentHashMap.newKeySet();
    private final ExecutorService pool = Executors.newFixedThreadPool(2);

    DownloadManager(Context context, BiliApi api, StreamProxy proxy, CookieStore cookies) {
        this.context = context;
        this.api = api;
        this.proxy = proxy;
        this.cookies = cookies;
        File root = new File(context.getFilesDir(), "offline");
        if (!root.exists()) root.mkdirs();
        this.dir = root;
        this.indexFile = new File(root, "index.json");
        load();
    }

    synchronized JSONObject start(String bvid, long cid, String title, String pic, String quality) {
        JSONObject out = new JSONObject();
        try {
            if (bvid == null || bvid.isEmpty()) throw new IllegalStateException("缺少 BV 号");
            JSONObject play = api.playRemote(bvid, cid, qn(quality));
            if (!play.optBoolean("ok")) {
                out.put("ok", false);
                out.put("error", play.optString("error", "无法获取下载地址"));
                return out;
            }
            long realCid = play.optLong("cid", cid);
            String id = bvid + "-" + realCid;
            JSONObject existing = find(id);
            if (existing != null && "completed".equals(existing.optString("status"))) {
                out.put("ok", true);
                out.put("item", decorate(existing));
                return out;
            }
            JSONObject item = existing == null ? new JSONObject() : existing;
            item.put("id", id);
            item.put("bvid", bvid);
            item.put("cid", realCid);
            item.put("title", title == null || title.isEmpty() ? bvid : title);
            item.put("pic", pic == null ? "" : pic);
            item.put("quality", play.optString("qualityLabel", quality));
            item.put("status", "downloading");
            item.put("downloaded", existing == null ? 0 : existing.optLong("downloaded", 0));
            item.put("total", existing == null ? 0 : existing.optLong("total", 0));
            item.put("created", existing == null ? System.currentTimeMillis() : existing.optLong("created", System.currentTimeMillis()));
            item.put("error", "");
            if (existing == null) items.add(item);
            save();
            String remote = play.optString("url", "");
            String backup = play.optString("backup", "");
            download(item, remote, backup);
            out.put("ok", true);
            out.put("item", decorate(item));
        } catch (Throwable error) {
            try {
                out.put("ok", false);
                out.put("error", error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage());
            } catch (Throwable ignored) {}
        }
        return out;
    }

    synchronized JSONObject list() {
        JSONObject out = new JSONObject();
        try {
            JSONArray rows = new JSONArray();
            long totalBytes = 0;
            for (JSONObject item : items) {
                if ("completed".equals(item.optString("status"))) totalBytes += item.optLong("downloaded", 0);
                rows.put(decorate(item));
            }
            out.put("ok", true);
            out.put("items", rows);
            out.put("storage", totalBytes);
            out.put("count", rows.length());
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    synchronized JSONObject remove(String id) {
        JSONObject out = new JSONObject();
        try {
            cancelled.add(id);
            JSONObject item = find(id);
            if (item != null) {
                deleteFile(item.optString("path", ""));
                deleteFile(new File(dir, id + ".part").getAbsolutePath());
                items.remove(item);
                save();
            }
            out.put("ok", true);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    synchronized JSONObject pause(String id) {
        JSONObject out = new JSONObject();
        try {
            cancelled.add(id);
            JSONObject item = find(id);
            if (item != null && "downloading".equals(item.optString("status"))) {
                item.put("status", "paused");
                save();
            }
            out.put("ok", true);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    synchronized JSONObject resume(String id) {
        JSONObject out = new JSONObject();
        try {
            JSONObject item = find(id);
            if (item == null) throw new IllegalStateException("任务不存在");
            if ("completed".equals(item.optString("status"))) {
                out.put("ok", true);
                out.put("item", decorate(item));
                return out;
            }
            cancelled.remove(id);
            item.put("status", "downloading");
            item.put("error", "");
            save();
            JSONObject play = api.playRemote(item.optString("bvid"), item.optLong("cid"), qn(item.optString("quality")));
            if (!play.optBoolean("ok")) throw new IllegalStateException(play.optString("error", "无法获取下载地址"));
            item.put("quality", play.optString("qualityLabel", item.optString("quality")));
            download(item, play.optString("url", ""), play.optString("backup", ""));
            out.put("ok", true);
            out.put("item", decorate(item));
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    private void download(JSONObject item, String remote, String backup) {
        final String id;
        try {
            id = item.getString("id");
        } catch (Throwable error) {
            return;
        }
        cancelled.remove(id);
        pool.execute(() -> {
            File part = new File(dir, id + ".part");
            File target = new File(dir, id + ".mp4");
            try {
                long existing = part.exists() ? part.length() : 0;
                long total = -1;
                String lastError = "";
                String[] sources = backup == null || backup.isEmpty()
                    ? new String[]{remote} : new String[]{remote, backup};
                for (String source : sources) {
                    if (source == null || source.isEmpty()) continue;
                    try {
                        total = transfer(item, part, source, existing);
                        if (total >= 0) break;
                    } catch (Throwable error) {
                        lastError = error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage();
                        Log.w(TAG, "source failed " + source.substring(0, Math.min(60, source.length())), error);
                        if (part.exists()) existing = part.length();
                    }
                }
                if (cancelled.contains(id)) {
                    item.put("status", "paused");
                    save();
                    return;
                }
                if (total < 0 && part.length() == 0) throw new IllegalStateException(lastError.isEmpty() ? "下载失败" : lastError);
                if (part.length() <= 0) throw new IllegalStateException("下载内容为空");
                if (target.exists()) target.delete();
                if (!part.renameTo(target)) throw new IllegalStateException("保存文件失败");
                synchronized (DownloadManager.this) {
                    item.put("status", "completed");
                    item.put("downloaded", target.length());
                    item.put("total", target.length());
                    item.put("path", target.getAbsolutePath());
                    item.put("error", "");
                    save();
                }
                Log.i(TAG, "download complete " + id + " " + target.length());
            } catch (Throwable error) {
                Log.w(TAG, "download failed " + id, error);
                synchronized (DownloadManager.this) {
                    if (!cancelled.contains(id)) {
                        try {
                            item.put("status", "error");
                            item.put("error", error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage());
                            save();
                        } catch (Throwable ignored) {}
                    }
                }
            }
        });
    }

    private long transfer(JSONObject item, File part, String remote, long existing) throws Exception {
        if (remote == null || remote.isEmpty()) throw new IllegalStateException("下载地址为空");
        HttpURLConnection connection = (HttpURLConnection) new URL(remote).openConnection();
        connection.setConnectTimeout(15000);
        connection.setReadTimeout(30000);
        connection.setRequestProperty("User-Agent", UA);
        connection.setRequestProperty("Referer", "https://www.bilibili.com/");
        connection.setRequestProperty("Accept", "*/*");
        connection.setRequestProperty("Accept-Encoding", "identity");
        String cookie = cookies.header();
        if (!cookie.isEmpty()) connection.setRequestProperty("Cookie", cookie);
        if (existing > 0) connection.setRequestProperty("Range", "bytes=" + existing + "-");
        int code = connection.getResponseCode();
        if (code != 200 && code != 206) {
            if (existing > 0 && code == 416) return part.length();
            throw new IllegalStateException("HTTP " + code);
        }
        if (code == 200 && existing > 0) {
            existing = 0;
            if (part.exists() && !part.delete()) throw new IllegalStateException("无法重置下载文件");
        }
        long contentLength = connection.getContentLengthLong();
        long total = code == 206 ? existing + contentLength : contentLength;
        synchronized (this) {
            item.put("total", total);
            item.put("downloaded", existing);
            item.put("status", "downloading");
            save();
        }
        try (InputStream input = new BufferedInputStream(connection.getInputStream());
             FileOutputStream output = new FileOutputStream(part, existing > 0)) {
            if (existing > 0) {
                // FileOutputStream append already positions at the end; range resumes at existing.
            }
            byte[] buffer = new byte[64 * 1024];
            int read;
            long written = existing;
            long lastSave = System.currentTimeMillis();
            while ((read = input.read(buffer)) >= 0) {
                if (cancelled.contains(item.optString("id"))) break;
                output.write(buffer, 0, read);
                written += read;
                if (System.currentTimeMillis() - lastSave > 600) {
                    lastSave = System.currentTimeMillis();
                    synchronized (this) {
                        item.put("downloaded", written);
                        save();
                    }
                }
            }
            synchronized (this) {
                item.put("downloaded", written);
                save();
            }
        } finally {
            connection.disconnect();
        }
        return total;
    }

    private JSONObject decorate(JSONObject item) throws Exception {
        JSONObject row = new JSONObject(item.toString());
        File file = new File(item.optString("path", ""));
        if ("completed".equals(item.optString("status")) && !file.isFile()) {
            row.put("status", "missing");
        }
        long downloaded = item.optLong("downloaded", 0);
        long total = item.optLong("total", 0);
        row.put("progress", total > 0 ? Math.min(100, Math.round(downloaded * 100.0 / total)) : 0);
        row.put("downloadedText", sizeText(downloaded));
        row.put("totalText", total > 0 ? sizeText(total) : "未知");
        if ("completed".equals(item.optString("status")) && file.isFile()) {
            row.put("url", proxy.localFileUrl(file.getAbsolutePath()));
        }
        return row;
    }

    private JSONObject find(String id) {
        for (JSONObject item : items) {
            if (id.equals(item.optString("id"))) return item;
        }
        return null;
    }

    private void load() {
        try {
            if (!indexFile.isFile()) return;
            String raw = new String(java.nio.file.Files.readAllBytes(indexFile.toPath()), StandardCharsets.UTF_8);
            JSONArray rows = new JSONArray(raw);
            for (int i = 0; i < rows.length(); i += 1) {
                JSONObject item = rows.optJSONObject(i);
                if (item == null) continue;
                if ("downloading".equals(item.optString("status"))) item.put("status", "paused");
                items.add(item);
            }
        } catch (Throwable error) {
            Log.w(TAG, "index load failed", error);
        }
    }

    private synchronized void save() {
        try {
            JSONArray rows = new JSONArray();
            for (JSONObject item : items) rows.put(item);
            try (FileOutputStream output = new FileOutputStream(indexFile)) {
                output.write(rows.toString().getBytes(StandardCharsets.UTF_8));
            }
        } catch (Throwable error) {
            Log.w(TAG, "index save failed", error);
        }
    }

    private void deleteFile(String path) {
        try {
            if (path != null && !path.isEmpty()) new File(path).delete();
        } catch (Throwable ignored) {}
    }

    private static int qn(String label) {
        if (label == null) return 64;
        switch (label) {
            case "4K": return 120;
            case "1080P60": return 116;
            case "1080P": return 80;
            case "720P": return 64;
            case "480P": return 32;
            case "360P": return 16;
            case "仅音频": return 16;
            default: return 64;
        }
    }

    private static String sizeText(long bytes) {
        if (bytes >= 1024L * 1024L * 1024L) return String.format(java.util.Locale.CHINA, "%.2f GB", bytes / 1073741824.0);
        if (bytes >= 1024L * 1024L) return String.format(java.util.Locale.CHINA, "%.1f MB", bytes / 1048576.0);
        if (bytes >= 1024L) return String.format(java.util.Locale.CHINA, "%.0f KB", bytes / 1024.0);
        return bytes + " B";
    }

    private static JSONObject error(Throwable error) {
        JSONObject out = new JSONObject();
        try {
            out.put("ok", false);
            out.put("error", error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage());
        } catch (Throwable ignored) {}
        return out;
    }
}
