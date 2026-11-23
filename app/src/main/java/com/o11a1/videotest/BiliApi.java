package com.o11a1.videotest;

import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

/** Bilibili public web API client used by the WebView bridge. */
final class BiliApi {
    private static final String TAG = "O11A1Api";
    private final CookieStore cookies;
    private final StreamProxy proxy;

    BiliApi(CookieStore cookies, StreamProxy proxy) {
        this.cookies = cookies;
        this.proxy = proxy;
    }

    JSONObject popular(int page, int ps) {
        JSONObject out = new JSONObject();
        try {
            int pn = Math.max(1, page);
            String raw = cookies.request("https://api.bilibili.com/x/web-interface/popular?ps=" + ps + "&pn=" + pn, null, null);
            JSONObject json = new JSONObject(raw);
            JSONArray list = json.optJSONObject("data") == null ? null : json.getJSONObject("data").optJSONArray("list");
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item != null) items.put(video(item, false));
                }
            }
            out.put("ok", true);
            out.put("items", items);
            out.put("page", pn);
        } catch (Throwable error) {
            Log.w(TAG, "popular failed", error);
            out = error(error);
        }
        return out;
    }

    JSONObject recommend(int page, int ps, int fresh) {
        JSONObject out = new JSONObject();
        try {
            int pn = Math.max(1, page);
            int size = ps <= 0 ? 20 : ps;
            int freshIndex = fresh <= 0 ? pn : fresh;
            String raw = cookies.request(
                "https://api.bilibili.com/x/web-interface/index/top/feed/rcmd?ps=" + size
                    + "&fresh_type=3&fresh_idx=" + freshIndex
                    + "&fresh_idx_1h=" + freshIndex
                    + "&homepage_ver=1&brush=" + Math.max(0, freshIndex - 1)
                    + "&screen=1920-1080&platform=web",
                null, null);
            JSONObject data = new JSONObject(raw).optJSONObject("data");
            JSONArray list = data == null ? null : data.optJSONArray("item");
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item == null) continue;
                    String gotoType = item.optString("goto", "av");
                    if (!gotoType.isEmpty() && !"av".equals(gotoType)) continue;
                    if (item.optString("bvid", "").isEmpty()) continue;
                    items.put(video(item, false));
                }
            }
            if (items.length() == 0) return popular(page, ps);
            out.put("ok", true);
            out.put("items", items);
            out.put("page", pn);
            out.put("fresh", freshIndex);
        } catch (Throwable error) {
            Log.w(TAG, "recommend failed", error);
            out = popular(page, ps);
        }
        return out;
    }

    JSONObject search(String keyword, int page) {
        JSONObject out = new JSONObject();
        try {
            String q = URLEncoder.encode(keyword == null ? "" : keyword, "UTF-8");
            int pn = Math.max(1, page);
            String raw = cookies.request("https://api.bilibili.com/x/web-interface/search/type?search_type=video&keyword=" + q + "&page=" + pn, null, null);
            JSONObject data = new JSONObject(raw).optJSONObject("data");
            JSONArray list = data == null ? null : data.optJSONArray("result");
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item == null) continue;
                    if (!"video".equals(item.optString("type", "video"))) continue;
                    items.put(video(item, true));
                }
            }
            out.put("ok", true);
            out.put("items", items);
            out.put("page", pn);
        } catch (Throwable error) {
            Log.w(TAG, "search failed", error);
            out = error(error);
        }
        return out;
    }

    JSONObject play(String bvid, long cid) {
        return playWithQns(bvid, cid, new int[]{64, 32, 16});
    }

    JSONObject playLow(String bvid, long cid) {
        return playWithQns(bvid, cid, new int[]{16});
    }

    JSONObject playQuality(String bvid, long cid, int qn) {
        if (qn <= 0) qn = 32;
        if (qn == 16) return playWithQns(bvid, cid, new int[]{16});
        return playWithQns(bvid, cid, qualityLadder(qn));
    }

    static int[] qualityLadder(int qn) {
        int target = qn <= 0 ? 64 : qn;
        int[] all = {120, 116, 112, 80, 74, 64, 32, 16};
        int[] temp = new int[all.length];
        int count = 0;
        for (int value : all) {
            if (value <= target) temp[count++] = value;
        }
        if (count == 0) temp[count++] = 16;
        int[] out = new int[count];
        System.arraycopy(temp, 0, out, 0, count);
        return out;
    }

    JSONObject playQns(String bvid, long cid, int[] qns) {
        return playWithQns(bvid, cid, qns);
    }

    long resolveCid(String bvid) {
        long cid = firstCid(bvid);
        return cid;
    }

    JSONObject playRemote(String bvid, long cid, int qn) {
        JSONObject out = new JSONObject();
        try {
            if (cid <= 0) {
                long pageCid = firstCid(bvid);
                if (pageCid > 0) cid = pageCid;
            }
            if (cid <= 0) throw new IllegalStateException("cid not found");
            int[] qns = qn <= 0 ? new int[]{80, 64, 32, 16} : BiliApi.qualityLadder(qn);
            JSONObject data = null;
            for (int candidate : qns) {
                String url = "https://api.bilibili.com/x/player/playurl?bvid=" + bvid + "&cid=" + cid
                    + "&qn=" + candidate + "&fnval=1&fourk=1";
                JSONObject json = new JSONObject(cookies.request(url, null, null));
                if (json.optInt("code", -1) != 0) continue;
                JSONObject candidateData = json.optJSONObject("data");
                if (candidateData != null && candidateData.optJSONArray("durl") != null
                    && candidateData.getJSONArray("durl").length() > 0) {
                    data = candidateData;
                    break;
                }
            }
            if (data == null) throw new IllegalStateException("playurl unavailable");
            JSONObject first = data.getJSONArray("durl").getJSONObject(0);
            String remote = first.optString("url", "");
            if (remote.isEmpty()) throw new IllegalStateException("empty stream url");
            int quality = data.optInt("quality", 16);
            out.put("ok", true);
            out.put("cid", cid);
            out.put("url", remote);
            if (first.optJSONArray("backup_url") != null && first.getJSONArray("backup_url").length() > 0) {
                out.put("backup", first.getJSONArray("backup_url").getString(0));
            }
            out.put("quality", quality);
            out.put("qualityLabel", qualityLabel(quality));
            out.put("format", data.optString("format", "mp4"));
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    private JSONObject playWithQns(String bvid, long cid, int[] qns) {
        JSONObject out = new JSONObject();
        try {
            Log.i(TAG, "play request bvid=" + bvid + " cid=" + cid + " cookie=" + cookies.header().length());
            if (cid <= 0) {
                long pageCid = firstCid(bvid);
                if (pageCid > 0) cid = pageCid;
            }
            if (cid <= 0) throw new IllegalStateException("cid not found");
            JSONObject data = null;
            for (int qn : qns) {
                String url = "https://api.bilibili.com/x/player/playurl?bvid=" + bvid + "&cid=" + cid
                    + "&qn=" + qn + "&fnval=1&fourk=0";
                String raw = cookies.request(url, null, null);
                JSONObject json = new JSONObject(raw);
                int code = json.optInt("code", -1);
                Log.i(TAG, "playurl qn=" + qn + " code=" + code + " msg=" + json.optString("message") + " len=" + raw.length());
                if (code != 0) continue;
                data = json.optJSONObject("data");
                if (data != null && data.optJSONArray("durl") != null && data.getJSONArray("durl").length() > 0) break;
                data = null;
            }
            if (data == null) throw new IllegalStateException("playurl unavailable");
            JSONArray durl = data.getJSONArray("durl");
            JSONObject first = durl.getJSONObject(0);
            String remote = first.optString("url", "");
            if (first.optJSONArray("backup_url") != null && first.getJSONArray("backup_url").length() > 0) {
                out.put("backup", proxy.localUrl(first.getJSONArray("backup_url").getString(0)));
            }
            if (remote.isEmpty()) throw new IllegalStateException("empty stream url");
            int quality = data.optInt("quality", 16);
            out.put("ok", true);
            out.put("cid", cid);
            out.put("url", proxy.localUrl(remote));
            out.put("quality", quality);
            out.put("qualityLabel", qualityLabel(quality));
            out.put("format", data.optString("format", "mp4"));
        } catch (Throwable error) {
            Log.w(TAG, "play failed", error);
            out = error(error);
        }
        return out;
    }

    private long firstCid(String bvid) {
        try {
            String raw = cookies.request("https://api.bilibili.com/x/player/pagelist?bvid=" + bvid, null, null);
            Log.i(TAG, "pagelist " + bvid + " len=" + raw.length() + " head=" + raw.substring(0, Math.min(120, raw.length())));
            JSONArray data = new JSONObject(raw).optJSONArray("data");
            if (data != null && data.length() > 0) return data.getJSONObject(0).optLong("cid", 0);
        } catch (Throwable error) {
            Log.w(TAG, "pagelist failed", error);
        }
        return 0;
    }

    JSONObject danmaku(long cid) {
        JSONObject out = new JSONObject();
        try {
            String raw = cookies.request("https://api.bilibili.com/x/v1/dm/list.so?oid=" + cid, null, null);
            Log.i(TAG, "danmaku cid=" + cid + " len=" + raw.length() + " head=" + raw.substring(0, Math.min(90, raw.length())));
            JSONArray items = new JSONArray();
            java.util.regex.Matcher matcher = java.util.regex.Pattern
                .compile("<d p=\"([^\"]+)\"[^>]*>(.*?)</d>", java.util.regex.Pattern.DOTALL)
                .matcher(raw);
            int count = 0;
            while (matcher.find() && count < 1600) {
                String[] parts = matcher.group(1).split(",");
                if (parts.length < 4) continue;
                JSONObject row = new JSONObject();
                try {
                    row.put("t", Double.parseDouble(parts[0]));
                    row.put("mode", Integer.parseInt(parts[1]));
                    row.put("color", Integer.parseInt(parts[3]));
                } catch (Throwable ignored) { continue; }
                String text = android.text.Html.fromHtml(matcher.group(2), android.text.Html.FROM_HTML_MODE_LEGACY).toString();
                row.put("text", text);
                items.put(row);
                count += 1;
            }
            out.put("ok", true);
            out.put("items", items);
        } catch (Throwable error) {
            Log.w(TAG, "danmaku failed", error);
            out = error(error);
        }
        return out;
    }
    JSONObject comments(long aid, int page) {
        JSONObject out = new JSONObject();
        try {
            String raw = cookies.request("https://api.bilibili.com/x/v2/reply?type=1&oid=" + aid + "&pn=" + Math.max(1, page) + "&sort=2", null, null);
            JSONObject json = new JSONObject(raw);
            JSONObject data = json.optJSONObject("data");
            JSONArray replies = data == null ? null : data.optJSONArray("replies");
            JSONArray items = new JSONArray();
            if (replies != null) {
                for (int i = 0; i < replies.length(); i += 1) {
                    JSONObject reply = replies.optJSONObject(i);
                    if (reply == null) continue;
                    JSONObject member = reply.optJSONObject("member");
                    JSONObject content = reply.optJSONObject("content");
                    JSONObject row = new JSONObject();
                    row.put("user", member == null ? "用户" : member.optString("uname", "用户"));
                    row.put("avatar", member == null ? "" : https(member.optString("avatar", "")));
                    row.put("message", content == null ? "" : content.optString("message", ""));
                    row.put("like", reply.optInt("like", 0));
                    row.put("time", reply.optLong("ctime", 0));
                    items.put(row);
                }
            }
            out.put("ok", true);
            out.put("items", items);
            JSONObject pageInfo = data == null ? null : data.optJSONObject("page");
            out.put("count", pageInfo == null ? items.length() : pageInfo.optInt("count", items.length()));
        } catch (Throwable error) {
            Log.w(TAG, "comments failed", error);
            out = error(error);
        }
        return out;
    }

    JSONObject session() {
        JSONObject out = new JSONObject();
        try {
            String raw = cookies.request("https://api.bilibili.com/x/web-interface/nav", null, null);
            JSONObject data = new JSONObject(raw).optJSONObject("data");
            boolean login = data != null && data.optBoolean("isLogin", false);
            out.put("ok", true);
            out.put("loggedIn", login || cookies.loggedIn());
            out.put("name", data == null ? "" : data.optString("uname", ""));
            out.put("mid", data == null ? 0 : data.optLong("mid", 0));
        } catch (Throwable error) {
            try {
                out = new JSONObject();
                out.put("ok", true);
                out.put("loggedIn", cookies.loggedIn());
                out.put("name", "");
            } catch (Throwable ignored) {}
        }
        return out;
    }

    void logout() {
        cookies.clear();
    }

    private JSONObject video(JSONObject item, boolean search) {
        JSONObject out = new JSONObject();
        String title = item.optString("title", "视频");
        title = strip(title);
        String pic = https(item.optString("pic", item.optString("pic_url", "")));
        String owner;
        JSONObject ownerObj = item.optJSONObject("owner");
        if (ownerObj != null) owner = ownerObj.optString("name", "UP 主");
        else owner = item.optString("author", "UP 主");
        owner = strip(owner);
        String duration;
        if (search) duration = item.optString("duration", "00:00");
        else duration = duration(item.optInt("duration", 0));
        long play = 0;
        if (search) {
            String playRaw = item.optString("play", "0");
            try { play = Long.parseLong(playRaw); } catch (Throwable ignored) {}
        } else {
            JSONObject stat = item.optJSONObject("stat");
            if (stat != null) play = stat.optLong("view", 0);
        }
        try {
            out.put("bvid", item.optString("bvid", ""));
            out.put("aid", item.optLong("aid", item.optLong("id", 0)));
            out.put("cid", item.optLong("cid", 0));
            out.put("title", title);
            out.put("pic", pic);
            out.put("owner", owner);
            if (ownerObj != null) {
                out.put("mid", ownerObj.optLong("mid", 0));
                out.put("ownerFace", https(ownerObj.optString("face", "")));
            } else {
                out.put("mid", item.optLong("mid", 0));
            }
            out.put("duration", duration);
            out.put("play", play);
            out.put("playText", count(play));
            out.put("desc", strip(item.optString("desc", item.optString("description", ""))));
            out.put("meta", owner + " · " + count(play) + " 播放");
        } catch (Throwable ignored) {}
        return out;
    }

    private static String duration(int seconds) {
        int s = Math.max(0, seconds);
        int h = s / 3600;
        int m = (s % 3600) / 60;
        int r = s % 60;
        if (h > 0) return String.format(Locale.CHINA, "%d:%02d:%02d", h, m, r);
        return String.format(Locale.CHINA, "%02d:%02d", m, r);
    }

    private static String count(long n) {
        if (n >= 100000000L) return String.format(Locale.CHINA, "%.1f 亿", n / 100000000.0);
        if (n >= 10000L) return String.format(Locale.CHINA, "%.1f 万", n / 10000.0);
        return String.valueOf(n);
    }

    private static String qualityLabel(int q) {
        switch (q) {
            case 120: return "4K";
            case 116: return "1080P60";
            case 112: return "1080P+";
            case 80: return "1080P";
            case 74: return "720P60";
            case 64: return "720P";
            case 32: return "480P";
            case 16: return "360P";
            default: return q + "P";
        }
    }

    private static String https(String url) {
        if (url == null) return "";
        if (url.startsWith("//")) return "https:" + url;
        if (url.startsWith("http://")) return "https://" + url.substring(7);
        return url;
    }

    private static String strip(String html) {
        if (html == null) return "";
        String text = html.replaceAll("<[^>]+>", "");
        return text.replace("&amp;", "&").replace("&quot;", "\"").replace("&#39;", "'")
            .replace("&lt;", "<").replace("&gt;", ">").replace("&nbsp;", " ");
    }

    private static JSONObject error(Throwable error) {
        JSONObject out = new JSONObject();
        try {
            out.put("ok", false);
            out.put("error", error == null ? "unknown" : (error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage()));
        } catch (Throwable ignored) {}
        return out;
    }
}
