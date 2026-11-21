package com.o11a1.videotest;

import android.content.Context;
import android.util.Base64;
import android.util.Log;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
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
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicLong;

/** Tiny localhost media proxy: adds Bilibili headers and forwards Range requests. */
final class StreamProxy {
    private static final String TAG = "O11A1Proxy";
    private static final String UA = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36";
    private final CookieStore cookies;
    private final ServerSocket server;
    private final ExecutorService pool = Executors.newCachedThreadPool();
    private final String filesRoot;
    private volatile boolean running = true;
    private final AtomicLong bytesServed = new AtomicLong();
    private final AtomicLong requestCount = new AtomicLong();

    StreamProxy(CookieStore cookies, android.content.Context context) throws IOException {
        this.cookies = cookies;
        String root = "";
        try {
            root = context.getFilesDir().getCanonicalPath();
        } catch (IOException ignored) {}
        this.filesRoot = root;
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
        String token = Base64.encodeToString(remote.getBytes(StandardCharsets.UTF_8),
            Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING);
        return "http://127.0.0.1:" + port() + "/s?u=" + token;
    }

    String localFileUrl(String path) {
        String token = Base64.encodeToString(path.getBytes(StandardCharsets.UTF_8),
            Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING);
        return "http://127.0.0.1:" + port() + "/f?p=" + token;
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
            if (!path.startsWith("/s?") && !path.startsWith("/f?")) {
                writeText(s.getOutputStream(), 404, "not found");
                return;
            }
            if (path.startsWith("/f?")) {
                requestCount.incrementAndGet();
                String encodedFile = null;
                for (String pair : path.substring(3).split("&")) {
                    int eq = pair.indexOf('=');
                    if (eq > 0 && pair.substring(0, eq).equals("p")) {
                        encodedFile = URLDecoder.decode(pair.substring(eq + 1), "UTF-8");
                    }
                }
                if (encodedFile == null || encodedFile.isEmpty()) {
                    writeText(s.getOutputStream(), 400, "missing p");
                    return;
                }
                String local = new String(Base64.decode(encodedFile, Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING), StandardCharsets.UTF_8);
                java.io.File file = new java.io.File(local);
                if (!file.getCanonicalPath().startsWith(filesRoot) || !file.isFile()) {
                    writeText(s.getOutputStream(), 404, "file not found");
                    return;
                }
                serveFile(s.getOutputStream(), file, headers.get("range"));
                return;
            }
            requestCount.incrementAndGet();
            String query = path.substring(3);
            String encoded = null;
            for (String pair : query.split("&")) {
                int eq = pair.indexOf('=');
                if (eq > 0 && pair.substring(0, eq).equals("u")) {
                    encoded = URLDecoder.decode(pair.substring(eq + 1), "UTF-8");
                }
            }
            if (encoded == null || encoded.isEmpty()) {
                writeText(s.getOutputStream(), 400, "missing u");
                return;
            }
            String remote = new String(Base64.decode(encoded, Base64.URL_SAFE | Base64.NO_WRAP | Base64.NO_PADDING), StandardCharsets.UTF_8);
            if (!remote.startsWith("https://") && !remote.startsWith("http://")) {
                writeText(s.getOutputStream(), 400, "bad url");
                return;
            }
            Log.i(TAG, "request " + method + " range=" + headers.get("range") + " url=" + remote.substring(0, Math.min(90, remote.length())));
            stream(s, method, remote, headers);
        } catch (Throwable error) {
            Log.w(TAG, "proxy request failed", error);
        }
    }

    private void stream(Socket socket, String method, String remote, Map<String, String> clientHeaders) throws IOException {
        HttpURLConnection connection = null;
        try {
            String range = clientHeaders.get("range");
            int code = -1;
            String contentType = null;
            String contentRange = null;
            String contentLength = null;
            for (int attempt = 0; attempt < 3; attempt += 1) {
                if (connection != null) connection.disconnect();
                connection = (HttpURLConnection) new URL(remote).openConnection();
                connection.setInstanceFollowRedirects(true);
                connection.setConnectTimeout(15000);
                connection.setReadTimeout(30000);
                connection.setRequestMethod("HEAD".equals(method) ? "HEAD" : "GET");
                connection.setRequestProperty("User-Agent", UA);
                connection.setRequestProperty("Referer", "https://www.bilibili.com/");
                connection.setRequestProperty("Accept", "*/*");
                connection.setRequestProperty("Cache-Control", "no-cache");
                if (range != null) connection.setRequestProperty("Range", range);
                try {
                    code = connection.getResponseCode();
                } catch (IOException error) {
                    if (attempt < 2) {
                        try { Thread.sleep(320L * (attempt + 1)); } catch (InterruptedException ignored) {}
                        continue;
                    }
                    throw error;
                }
                contentType = connection.getContentType();
                contentRange = connection.getHeaderField("Content-Range");
                contentLength = connection.getHeaderField("Content-Length");
                Log.i(TAG, "remote -> " + code + " type=" + contentType + " len=" + contentLength + " range=" + contentRange + " attempt=" + attempt);
                if (code >= 500 && attempt < 2) {
                    try { Thread.sleep(320L * (attempt + 1)); } catch (InterruptedException ignored) {}
                    continue;
                }
                break;
            }
            OutputStream out = socket.getOutputStream();
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
                InputStream in = code >= 400 ? connection.getErrorStream() : connection.getInputStream();
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

    private void serveFile(OutputStream out, java.io.File file, String range) throws IOException {
        long length = file.length();
        long start = 0;
        long end = length - 1;
        boolean partial = false;
        if (range != null && range.startsWith("bytes=")) {
            try {
                String spec = range.substring(6).split(",")[0];
                String[] parts = spec.split("-", -1);
                if (!parts[0].isEmpty()) start = Long.parseLong(parts[0]);
                if (parts.length > 1 && !parts[1].isEmpty()) end = Math.min(length - 1, Long.parseLong(parts[1]));
                partial = true;
            } catch (Throwable ignored) {
                start = 0;
                end = length - 1;
                partial = false;
            }
        }
        if (start < 0 || start >= length) {
            writeText(out, 416, "range not satisfiable");
            return;
        }
        long count = Math.max(0, end - start + 1);
        String type = file.getName().endsWith(".m4a") ? "audio/mp4" : "video/mp4";
        StringBuilder head = new StringBuilder();
        head.append(partial ? "HTTP/1.1 206 Partial Content\r\n" : "HTTP/1.1 200 OK\r\n");
        head.append("Access-Control-Allow-Origin: *\r\n");
        head.append("Accept-Ranges: bytes\r\n");
        head.append("Content-Type: ").append(type).append("\r\n");
        head.append("Content-Length: ").append(count).append("\r\n");
        if (partial) head.append("Content-Range: bytes ").append(start).append("-").append(end).append("/").append(length).append("\r\n");
        head.append("Cache-Control: no-store\r\nConnection: close\r\n\r\n");
        out.write(head.toString().getBytes(StandardCharsets.ISO_8859_1));
        try (java.io.RandomAccessFile input = new java.io.RandomAccessFile(file, "r")) {
            input.seek(start);
            byte[] buffer = new byte[64 * 1024];
            long remaining = count;
            while (remaining > 0) {
                int read = input.read(buffer, 0, (int) Math.min(buffer.length, remaining));
                if (read < 0) break;
                out.write(buffer, 0, read);
                bytesServed.addAndGet(read);
                remaining -= read;
            }
        }
        out.flush();
    }

    private static void writeText(OutputStream out, int code, String text) throws IOException {
        byte[] body = text.getBytes(StandardCharsets.UTF_8);
        String head = "HTTP/1.1 " + code + " " + (code == 200 ? "OK" : "Error") + "\r\n"
            + "Content-Type: text/plain; charset=utf-8\r\n"
            + "Content-Length: " + body.length + "\r\nConnection: close\r\n\r\n";
        out.write(head.getBytes(StandardCharsets.ISO_8859_1));
        out.write(body);
        out.flush();
    }
}
