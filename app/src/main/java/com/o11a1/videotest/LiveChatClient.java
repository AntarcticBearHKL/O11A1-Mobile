package com.o11a1.videotest;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;
import java.util.zip.Inflater;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;
import okio.ByteString;

/** Minimal Bilibili live danmaku WebSocket client (JSON protocol). */
final class LiveChatClient {
    interface Listener {
        void onMessage(String user, String text);
        void onClosed();
    }

    private static final String TAG = "O11A1LiveChat";
    private static final String USER_AGENT =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            + " (KHTML, like Gecko) Chrome/124.0 Safari/537.36";

    private final Handler main = new Handler(Looper.getMainLooper());
    private final Runnable heartbeat = new Runnable() {
        @Override public void run() {
            if (closed) return;
            WebSocket current = socket;
            if (current != null) current.send(ByteString.of(packet(2, new byte[0])));
            main.postDelayed(this, 30_000);
        }
    };

    private OkHttpClient client;
    private WebSocket socket;
    private Listener listener;
    private boolean closed = false;
    private int attempts = 0;
    private long roomId = 0;
    private String token = "";
    private String host = "";
    private int port = 443;

    void connect(long roomId, String token, String host, int port, Listener listener) {
        this.roomId = roomId;
        this.token = token == null ? "" : token;
        this.host = host == null ? "" : host;
        this.port = port <= 0 ? 443 : port;
        this.listener = listener;
        this.closed = false;
        this.attempts += 1;
        open();
    }

    private void open() {
        if (closed || host.isEmpty()) return;
        if (client == null) {
            client = new OkHttpClient.Builder()
                .connectTimeout(12, TimeUnit.SECONDS)
                .readTimeout(0, TimeUnit.MILLISECONDS)
                .build();
        }
        String url = "wss://" + host + ":" + port + "/sub";
        Request request = new Request.Builder()
            .url(url)
            .header("User-Agent", USER_AGENT)
            .header("Origin", "https://live.bilibili.com")
            .header("Referer", "https://live.bilibili.com/" + roomId)
            .build();
        socket = client.newWebSocket(request, new WebSocketListener() {
            @Override public void onOpen(WebSocket webSocket, Response response) {
                Log.i(TAG, "connected " + host + ":" + port + " room=" + roomId);
                attempts = 0;
                sendAuth(webSocket);
                main.removeCallbacks(heartbeat);
                main.postDelayed(heartbeat, 30_000);
            }

            @Override public void onMessage(WebSocket webSocket, ByteString bytes) {
                parsePackets(bytes.toByteArray());
            }

            @Override public void onMessage(WebSocket webSocket, String text) {
                handleJson(text.getBytes(StandardCharsets.UTF_8));
            }

            @Override public void onFailure(WebSocket webSocket, Throwable t, Response response) {
                Log.w(TAG, "live chat failed: " + t.getMessage());
                main.removeCallbacks(heartbeat);
                if (!closed && attempts < 4) {
                    main.postDelayed(LiveChatClient.this::open, 2_500);
                }
            }

            @Override public void onClosed(WebSocket webSocket, int code, String reason) {
                main.removeCallbacks(heartbeat);
                if (!closed && listener != null) listener.onClosed();
            }
        });
    }

    private void sendAuth(WebSocket webSocket) {
        try {
            JSONObject auth = new JSONObject();
            auth.put("uid", 0);
            auth.put("roomid", roomId);
            auth.put("protover", 2);
            auth.put("platform", "web");
            auth.put("type", 2);
            auth.put("key", token);
            webSocket.send(ByteString.of(packet(7, auth.toString().getBytes(StandardCharsets.UTF_8))));
        } catch (Throwable error) {
            Log.w(TAG, "auth failed", error);
        }
    }

    private byte[] packet(int operation, byte[] body) {
        ByteBuffer buffer = ByteBuffer.allocate(16 + body.length).order(ByteOrder.BIG_ENDIAN);
        buffer.putInt(16 + body.length);
        buffer.putShort((short) 16);
        buffer.putShort((short) 1);
        buffer.putInt(operation);
        buffer.putInt(1);
        buffer.put(body);
        return buffer.array();
    }

    private void parsePackets(byte[] data) {
        int offset = 0;
        while (offset + 16 <= data.length) {
            ByteBuffer header = ByteBuffer.wrap(data, offset, 16).order(ByteOrder.BIG_ENDIAN);
            int total = header.getInt();
            int headerLength = header.getShort() & 0xFFFF;
            int version = header.getShort() & 0xFFFF;
            int operation = header.getInt();
            if (total < headerLength || headerLength < 16 || offset + total > data.length) {
                return;
            }
            int bodyStart = offset + headerLength;
            byte[] body = new byte[total - headerLength];
            System.arraycopy(data, bodyStart, body, 0, body.length);
            if (operation == 5) {
                if (version == 2) {
                    byte[] inflated = inflate(body);
                    if (inflated != null) parsePackets(inflated);
                } else if (version == 0 || version == 1) {
                    handleJson(body);
                }
            }
            offset += total;
        }
    }

    private byte[] inflate(byte[] data) {
        Inflater inflater = new Inflater();
        try {
            inflater.setInput(data);
            java.io.ByteArrayOutputStream output = new java.io.ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            while (!inflater.finished()) {
                int count = inflater.inflate(buffer);
                if (count <= 0) break;
                output.write(buffer, 0, count);
            }
            return output.toByteArray();
        } catch (Throwable error) {
            Log.w(TAG, "inflate failed", error);
            return null;
        } finally {
            inflater.end();
        }
    }

    private void handleJson(byte[] body) {
        try {
            JSONObject json = new JSONObject(new String(body, StandardCharsets.UTF_8));
            String cmd = json.optString("cmd", "");
            if (!cmd.startsWith("DANMU_MSG")) return;
            JSONArray info = json.optJSONArray("info");
            if (info == null) return;
            String text = info.optString(1, "");
            if (text.isEmpty()) return;
            JSONArray userInfo = info.optJSONArray(2);
            String user = userInfo == null ? "" : userInfo.optString(1, "");
            if (user.isEmpty()) {
                JSONObject data = json.optJSONObject("data");
                user = data == null ? "" : data.optString("uname", "");
            }
            final String name = user.isEmpty() ? "观众" : user;
            final String message = text;
            final Listener target = listener;
            if (target == null) return;
            main.post(() -> {
                if (!closed) target.onMessage(name, message);
            });
        } catch (Throwable ignored) {
        }
    }

    void close() {
        closed = true;
        main.removeCallbacks(heartbeat);
        WebSocket current = socket;
        socket = null;
        if (current != null) {
            try {
                current.close(1000, null);
            } catch (Throwable ignored) {
            }
        }
        OkHttpClient http = client;
        client = null;
        if (http != null) {
            http.dispatcher().executorService().shutdown();
        }
        listener = null;
    }
}
