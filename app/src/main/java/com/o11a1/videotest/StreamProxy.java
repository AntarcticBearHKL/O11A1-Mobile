package com.o11a1.videotest;

import android.util.Base64;
import android.util.Log;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URL;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicLong;

/** Tiny localhost media proxy: adds Bilibili headers and forwards Range requests. */
final class StreamProxy {
    private static final String TAG = "O11A1Proxy";
    private static final String UA = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36";
    private static final String DESKTOP_UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36";
    private static final long MEDIA_CHUNK = 1024 * 1024;
    private final CookieStore cookies;
    private final ServerSocket server;
    private final ExecutorService pool = Executors.newCachedThreadPool();
    private volatile boolean running = true;
    private final AtomicLong bytesServed = new AtomicLong();
    private final AtomicLong requestCount = new AtomicLong();
    private final Set<String> blockedMediaUrls = ConcurrentHashMap.newKeySet();
    private static final long PREFIX_BYTES = 512 * 1024;
    private static final long PREFIX_TTL = 10 * 60 * 1000L;
    private static final int PREFIX_MAX = 24;
    private final Map<String, PrefixEntry> prefixes = new ConcurrentHashMap<>();
    private final Set<String> prefixesLoading = ConcurrentHashMap.newKeySet();

    private static final class PrefixEntry {
        final byte[] data;
        final long total;
        final String type;
        final long at;

        PrefixEntry(byte[] data, long total, String type, long at) {
            this.data = data;
            this.total = total;
            this.type = type;
            this.at = at;
        }
    }

    StreamProxy(CookieStore cookies) throws IOException {
        this.cookies = cookies;
        server = new ServerSocket(0, 50, InetAddress.getByName("127.0.0.1"));
        Thread acceptThread = new Thread(this::acceptLoop, "o11a1-proxy-accept");
        acceptThread.setDaemon(true);
        acceptThread.start();
        Log.i(TAG, "listening on " + server.getLocalPort());
    }

    int port() {
        return server.getLocalPort();
    }

    String localUrl(String remote) {
        return localUrl(new String[]{remote});
    }

    String localUrl(String remote, String backup) {
        return localUrl(new String[]{remote, backup}, false);
    }

    String localUrl(String remote, String backup, boolean preview) {
        return localUrl(new String[]{remote, backup}, preview);
    }

    String localUrl(String[] remotes) {
        return localUrl(remotes, false);
    }

    String localUrl(String[] remotes, boolean preview) {
        org.json.JSONArray list = new org.json.JSONArray();
        if (remotes != null) {
            for (String remote : remotes) {
                if (remote != null && !remote.isEmpty()) list.put(remote);
            }
        }
        String payload = list.length() > 0 ? list.toString() : "";
        String token = Base64.encodeToString(payload.getBytes(StandardCharsets.UTF_8),
            Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING);
        return "http://127.0.0.1:" + port() + "/s?u=" + token + (preview ? "&p=1" : "");
    }

    void prefetchPreview(String remote, String backup) {
        prefetchPreview(new String[]{remote, backup});
    }

    void prefetchPreview(String[] remotes) {
        List<String> list = new ArrayList<>();
        if (remotes != null) {
            for (String remote : remotes) {
                if (remote != null && !remote.isEmpty()
                    && (remote.startsWith("https://") || remote.startsWith("http://"))) {
                    list.add(remote);
                }
            }
        }
        if (list.isEmpty()) return;
        String key = prefixKey(list);
        PrefixEntry cached = prefixes.get(key);
        if (cached != null && System.currentTimeMillis() - cached.at < PREFIX_TTL) return;
        if (prefixes.size() >= PREFIX_MAX) return;
        if (prefixesLoading.size() >= 2) return;
        if (!prefixesLoading.add(key)) return;
        pool.execute(() -> {
            try {
                PrefixEntry entry = downloadPrefix(list);
                if (entry != null) {
                    prefixes.put(key, entry);
                    trimPrefixes();
                }
            } catch (Throwable error) {
                Log.w(TAG, "prefix prefetch failed", error);
            } finally {
                prefixesLoading.remove(key);
            }
        });
    }

    private PrefixEntry downloadPrefix(List<String> remotes) {
        for (String remote : remotes) {
            if (blockedMediaUrls.contains(remote)) continue;
            HttpURLConnection connection = null;
            try {
                connection = (HttpURLConnection) new URL(remote).openConnection();
                connection.setInstanceFollowRedirects(true);
                connection.setConnectTimeout(3000);
                connection.setReadTimeout(15000);
                connection.setRequestMethod("GET");
                connection.setRequestProperty("User-Agent", mediaUserAgent(remote));
                connection.setRequestProperty("Referer", "https://www.bilibili.com/");
                connection.setRequestProperty("Accept", "*/*");
                connection.setRequestProperty("Range", "bytes=0-" + (PREFIX_BYTES - 1));
                int code = connection.getResponseCode();
                if (code != 200 && code != 206) {
                    continue;
                }
                long total = 0;
                String contentRange = connection.getHeaderField("Content-Range");
                if (contentRange != null) {
                    int slash = contentRange.lastIndexOf('/');
                    if (slash >= 0) {
                        try { total = Long.parseLong(contentRange.substring(slash + 1)); } catch (Throwable ignored) {}
                    }
                }
                if (total <= 0) {
                    String length = connection.getHeaderField("Content-Length");
                    if (length != null) {
                        try { total = Long.parseLong(length); } catch (Throwable ignored) {}
                    }
                }
                if (total <= 0) continue;
                InputStream input = connection.getInputStream();
                if (input == null) continue;
                ByteArrayOutputStream buffer = new ByteArrayOutputStream();
                try (InputStream in = new BufferedInputStream(input)) {
                    byte[] chunk = new byte[32 * 1024];
                    long remaining = Math.min(PREFIX_BYTES, total);
                    while (remaining > 0) {
                        int read = in.read(chunk, 0, (int) Math.min(chunk.length, remaining));
                        if (read <= 0) break;
                        buffer.write(chunk, 0, read);
                        remaining -= read;
                    }
                }
                if (buffer.size() == 0) continue;
                return new PrefixEntry(buffer.toByteArray(), total,
                    connection.getContentType(), System.currentTimeMillis());
            } catch (Throwable error) {
                Log.w(TAG, "prefix fetch failed host=" + hostOf(remote));
            } finally {
                if (connection != null) connection.disconnect();
            }
        }
        return null;
    }

    private void trimPrefixes() {
        if (prefixes.size() <= PREFIX_MAX) return;
        long cutoff = System.currentTimeMillis() - PREFIX_TTL;
        for (Map.Entry<String, PrefixEntry> entry : prefixes.entrySet()) {
            if (entry.getValue().at < cutoff) prefixes.remove(entry.getKey());
        }
        while (prefixes.size() > PREFIX_MAX) {
            String oldest = null;
            long oldestAt = Long.MAX_VALUE;
            for (Map.Entry<String, PrefixEntry> entry : prefixes.entrySet()) {
                if (entry.getValue().at < oldestAt) {
                    oldestAt = entry.getValue().at;
                    oldest = entry.getKey();
                }
            }
            if (oldest == null) break;
            prefixes.remove(oldest);
        }
    }

    private static String prefixKey(List<String> remotes) {
        return String.join("\n", remotes);
    }

    private static String hostOf(String remote) {
        try { return new URL(remote).getHost(); } catch (Throwable ignored) { return "?"; }
    }

    String statsJson() {
        org.json.JSONObject out = new org.json.JSONObject();
        try {
            out.put("ok", true);
            out.put("bytes", bytesServed.get());
            out.put("requests", requestCount.get());
        } catch (Throwable ignored) {}
        return out.toString();
    }

    void stop() {
        running = false;
        blockedMediaUrls.clear();
        try { server.close(); } catch (IOException ignored) {}
        pool.shutdownNow();
    }

    private void acceptLoop() {
        while (running) {
            try {
                Socket socket = server.accept();
                pool.execute(() -> handle(socket));
            } catch (IOException e) {
                if (running) Log.w(TAG, "accept failed", e);
            }
        }
    }

    private void handle(Socket socket) {
        try (Socket s = socket) {
            s.setSoTimeout(15000);
            BufferedReader reader = new BufferedReader(new InputStreamReader(s.getInputStream(), StandardCharsets.ISO_8859_1));
            String requestLine = reader.readLine();
            if (requestLine == null) return;
            String[] parts = requestLine.split(" ");
            if (parts.length < 2) return;
            String method = parts[0].toUpperCase(Locale.US);
            String path = parts[1];
            Map<String, String> headers = new HashMap<>();
            String line;
            while ((line = reader.readLine()) != null && !line.isEmpty()) {
                int colon = line.indexOf(':');
                if (colon > 0) headers.put(line.substring(0, colon).trim().toLowerCase(Locale.US), line.substring(colon + 1).trim());
            }
            if (!path.startsWith("/s?")) {
                writeText(s.getOutputStream(), 404, "not found");
                return;
            }
            requestCount.incrementAndGet();
            String query = path.substring(3);
            String encoded = null;
            boolean preview = false;
            for (String pair : query.split("&")) {
                int eq = pair.indexOf('=');
                if (eq > 0 && pair.substring(0, eq).equals("u")) {
                    encoded = URLDecoder.decode(pair.substring(eq + 1), "UTF-8");
                } else if (eq > 0 && pair.substring(0, eq).equals("p")) {
                    preview = "1".equals(pair.substring(eq + 1));
                }
            }
            if (encoded == null || encoded.isEmpty()) {
                writeText(s.getOutputStream(), 400, "missing u");
                return;
            }
            String decoded = new String(Base64.decode(encoded, Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING), StandardCharsets.UTF_8);
            List<String> remotes = new ArrayList<>();
            try {
                org.json.JSONArray list = new org.json.JSONArray(decoded);
                for (int index = 0; index < list.length(); index += 1) {
                    String value = list.optString(index, "");
                    if (value.startsWith("https://") || value.startsWith("http://")) remotes.add(value);
                }
            } catch (Throwable ignored) {
                if (decoded.startsWith("https://") || decoded.startsWith("http://")) remotes.add(decoded);
            }
            if (remotes.isEmpty()) {
                writeText(s.getOutputStream(), 400, "bad url");
                return;
            }
            Log.i(TAG, "request " + method + " range=" + headers.get("range") + " preview=" + preview + " url=" + remotes.get(0).substring(0, Math.min(90, remotes.get(0).length())));
            stream(s, method, remotes, headers, preview);
        } catch (Throwable error) {
            Log.w(TAG, "proxy request failed", error);
        }
    }

    private static String boundedRange(String range) {
        if (range == null) return null;
        String value = range.trim();
        if (!value.startsWith("bytes=")) return value;
        int dash = value.indexOf('-');
        if (dash <= 6) return value;
        String startText = value.substring(6, dash);
        String endText = value.substring(dash + 1).trim();
        if (!endText.isEmpty() || !startText.matches("\\d+")) return value;
        try {
            long start = Long.parseLong(startText);
            return "bytes=" + start + "-" + (start + MEDIA_CHUNK - 1);
        } catch (Throwable ignored) {
            return value;
        }
    }

    private static long[] parseRange(String range) {
        if (range == null) return null;
        String value = range.trim();
        if (!value.startsWith("bytes=")) return null;
        String spec = value.substring(6);
        int dash = spec.indexOf('-');
        if (dash < 0) return null;
        try {
            long start = Long.parseLong(spec.substring(0, dash).trim());
            String endText = spec.substring(dash + 1).trim();
            long end = endText.isEmpty() ? -1 : Long.parseLong(endText);
            return new long[]{start, end};
        } catch (Throwable ignored) {
            return null;
        }
    }

    private void servePrefix(Socket socket, PrefixEntry prefix, long start, long end, String method) throws IOException {
        int max = prefix.data.length;
        int from = (int) Math.max(0, Math.min(start, max - 1));
        int to = (int) (end < 0 ? max - 1 : Math.max(from, Math.min(end, max - 1)));
        long total = Math.max(prefix.total, to + 1L);
        int length = to - from + 1;
        OutputStream out = socket.getOutputStream();
        StringBuilder head = new StringBuilder();
        head.append("HTTP/1.1 206 Partial Content\r\n");
        head.append("Access-Control-Allow-Origin: *\r\n");
        head.append("Accept-Ranges: bytes\r\n");
        head.append("Content-Type: ").append(prefix.type == null ? "video/mp4" : prefix.type).append("\r\n");
        head.append("Content-Length: ").append(length).append("\r\n");
        head.append("Content-Range: bytes ").append(from).append("-").append(to).append("/").append(total).append("\r\n");
        head.append("Cache-Control: no-store\r\nConnection: close\r\n\r\n");
        out.write(head.toString().getBytes(StandardCharsets.ISO_8859_1));
        if (!"HEAD".equals(method)) out.write(prefix.data, from, length);
        out.flush();
        Log.i(TAG, "prefix -> " + length + " range=bytes " + from + "-" + to + "/" + total);
    }

    private void stream(Socket socket, String method, List<String> remotes, Map<String, String> clientHeaders, boolean preview) throws IOException {
        HttpURLConnection connection = null;
        try {
            String range = clientHeaders.get("range");
            String upstreamRange = boundedRange(range);
            if (range != null) {
                PrefixEntry prefix = prefixes.get(prefixKey(remotes));
                if (prefix != null && System.currentTimeMillis() - prefix.at < PREFIX_TTL) {
                    long[] parsed = parseRange(range);
                    long start = parsed == null ? 0 : parsed[0];
                    long end = parsed == null ? -1 : parsed[1];
                    if (start < prefix.data.length) {
                        servePrefix(socket, prefix, start, end, method);
                        return;
                    }
                }
            }
            int code = -1;
            String selectedRemote = null;
            String contentType = null;
            String contentRange = null;
            String contentLength = null;
            for (String remote : remotes) {
                if (remote == null || blockedMediaUrls.contains(remote)) continue;
                for (int attempt = 0; attempt < 1; attempt += 1) {
                    if (connection != null) connection.disconnect();
                    connection = (HttpURLConnection) new URL(remote).openConnection();
                    connection.setInstanceFollowRedirects(true);
                    connection.setConnectTimeout(3000);
                    connection.setReadTimeout(7000);
                    connection.setRequestMethod("HEAD".equals(method) ? "HEAD" : "GET");
                    connection.setRequestProperty("User-Agent", mediaUserAgent(remote));
                    connection.setRequestProperty("Referer", "https://www.bilibili.com/");
                    connection.setRequestProperty("Accept", "*/*");
                    connection.setRequestProperty("Cache-Control", "no-cache");
                    if (upstreamRange != null) connection.setRequestProperty("Range", upstreamRange);
                    try {
                        code = connection.getResponseCode();
                    } catch (IOException error) {
                        code = -1;
                        blockedMediaUrls.add(remote);
                        Log.w(TAG, "remote timeout host=" + new URL(remote).getHost());
                    }
                    if (code == 200 || code == 206) {
                        selectedRemote = remote;
                        contentType = connection.getContentType();
                        contentRange = connection.getHeaderField("Content-Range");
                        contentLength = connection.getHeaderField("Content-Length");
                        Log.i(TAG, "remote -> " + code + " host=" + new URL(remote).getHost()
                            + " type=" + contentType + " len=" + contentLength + " range=" + contentRange);
                        break;
                    }
                    Log.w(TAG, "remote reject " + code + " host=" + new URL(remote).getHost());
                    if (code == 403 || code == 404 || code == 410) {
                        blockedMediaUrls.add(remote);
                        break;
                    }
                    if (attempt == 0) {
                        try { Thread.sleep(260L); } catch (InterruptedException ignored) {}
                    }
                }
                if (selectedRemote != null) break;
            }
            OutputStream out = socket.getOutputStream();
            if (selectedRemote == null) {
                writeText(out, 502, "upstream unavailable");
                return;
            }
            StringBuilder head = new StringBuilder();
            head.append("HTTP/1.1 ").append(code).append(" ").append(connection.getResponseMessage() == null ? "OK" : connection.getResponseMessage()).append("\r\n");
            head.append("Access-Control-Allow-Origin: *\r\n");
            head.append("Accept-Ranges: bytes\r\n");
            if (contentType != null) head.append("Content-Type: ").append(contentType).append("\r\n");
            if (contentLength != null) head.append("Content-Length: ").append(contentLength).append("\r\n");
            if (contentRange != null) head.append("Content-Range: ").append(contentRange).append("\r\n");
            head.append("Cache-Control: no-store\r\nConnection: close\r\n\r\n");
            out.write(head.toString().getBytes(StandardCharsets.ISO_8859_1));
            if (!"HEAD".equals(method)) {
                InputStream in = connection.getInputStream();
                if (in != null) {
                    try (InputStream input = new BufferedInputStream(in)) {
                        byte[] buffer = new byte[32 * 1024];
                        int read;
                        while ((read = input.read(buffer)) >= 0) {
                            out.write(buffer, 0, read);
                            bytesServed.addAndGet(read);
                        }
                    }
                }
            }
            out.flush();
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    private static String mediaUserAgent(String remote) {
        if (remote == null) return UA;
        String path = remote;
        int query = path.indexOf('?');
        if (query >= 0) path = path.substring(0, query);
        return path.endsWith(".m4s") || path.endsWith(".m4a") ? DESKTOP_UA : UA;
    }

    private static void writeText(OutputStream out, int code, String text) throws IOException {
        byte[] body = text.getBytes(StandardCharsets.UTF_8);
        String head = "HTTP/1.1 " + code + " " + (code == 200 ? "OK" : "Error") + "\r\n"
            + "Access-Control-Allow-Origin: *\r\n"
            + "Access-Control-Allow-Headers: Range\r\n"
            + "Access-Control-Expose-Headers: Content-Length,Content-Range\r\n"
            + "Content-Type: text/plain; charset=utf-8\r\n"
            + "Content-Length: " + body.length + "\r\nConnection: close\r\n\r\n";
        out.write(head.getBytes(StandardCharsets.ISO_8859_1));
        out.write(body);
        out.flush();
    }
}
