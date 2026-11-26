package com.o11a1.videotest;

import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;

/** Account, community, PGC and live APIs used by the native UI. */
final class BiliExtras {
    private static final String TAG = "O11A1Extras";
    private static final int[] WBI_MIXIN_KEY = {
        46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35,
        27, 43, 5, 49, 33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13,
        37, 48, 7, 16, 24, 55, 40, 61, 26, 17, 0, 1, 60, 51, 30, 4,
        22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11, 36, 20, 34, 44, 52
    };
    private final CookieStore cookies;
    private final BiliApi api;
    private long cachedMid = 0;
    private long cachedFolderId = 0;
    private String cachedWbiKey = "";
    private long cachedWbiAt = 0;

    BiliExtras(CookieStore cookies, BiliApi api) {
        this.cookies = cookies;
        this.api = api;
    }

    /* ---------- account ---------- */

    JSONObject account() {
        JSONObject out = new JSONObject();
        try {
            JSONObject data = navData();
            boolean login = data != null && data.optBoolean("isLogin", false);
            JSONObject level = data == null ? null : data.optJSONObject("level_info");
            JSONObject vip = data == null ? null : data.optJSONObject("vip");
            long mid = data == null ? 0 : data.optLong("mid", 0);
            out.put("ok", true);
            out.put("loggedIn", login || cookies.loggedIn());
            out.put("hasSession", cookies.loggedIn());
            out.put("name", data == null ? "" : data.optString("uname", ""));
            out.put("face", data == null ? "" : https(data.optString("face", "")));
            out.put("mid", mid);
            out.put("level", level == null ? 0 : level.optInt("current_level", 0));
            out.put("vip", vip != null && vip.optInt("status", 0) == 1);
            out.put("vipLabel", vip == null ? "" : vip.optString("label", ""));
            out.put("coins", data == null ? 0 : data.optInt("coins", 0));
            out.put("sign", data == null ? "" : data.optString("sign", ""));
            if (mid > 0) {
                try {
                    JSONObject relation = fetch("https://api.bilibili.com/x/relation/stat?mid=" + mid)
                        .optJSONObject("data");
                    out.put("follower", relation == null ? 0 : relation.optLong("follower", 0));
                    out.put("following", relation == null ? 0 : relation.optLong("following", 0));
                } catch (Throwable ignored) {}
            }
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject favorites(int page) {
        if (!cookies.loggedIn()) return needLogin("登录后查看收藏");
        JSONObject out = new JSONObject();
        try {
            long folderId = defaultFolderId();
            JSONArray items = new JSONArray();
            int pn = Math.max(1, page);
            if (folderId > 0) {
                JSONObject json = fetch("https://api.bilibili.com/x/v3/fav/resource/list?media_id=" + folderId
                    + "&pn=" + pn + "&ps=20&platform=web");
                JSONObject data = json.optJSONObject("data");
                JSONArray medias = data == null ? null : data.optJSONArray("medias");
                if (medias != null) {
                    for (int i = 0; i < medias.length(); i += 1) {
                        JSONObject media = medias.optJSONObject(i);
                        if (media != null) items.put(mediaVideo(media));
                    }
                }
                out.put("count", data == null ? items.length() : data.optInt("info", items.length()));
                out.put("hasMore", medias != null && medias.length() >= 20);
            } else {
                out.put("count", 0);
                out.put("hasMore", false);
            }
            out.put("ok", true);
            out.put("loggedIn", true);
            out.put("items", items);
            out.put("page", pn);
            out.put("title", "收藏夹");
            if (items.length() == 0) out.put("note", "收藏夹为空");
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject history(int page, String cursor) {
        if (!cookies.loggedIn()) return needLogin("登录后查看历史");
        JSONObject out = new JSONObject();
        try {
            String url = "https://api.bilibili.com/x/web-interface/history/cursor?ps=20&type=archive";
            if (cursor != null && cursor.contains("|")) {
                String[] parts = cursor.split("\\|", -1);
                if (parts.length >= 2) {
                    url += "&max=" + URLEncoder.encode(parts[0], "UTF-8")
                        + "&view_at=" + URLEncoder.encode(parts[1], "UTF-8");
                }
            }
            JSONObject data = fetch(url).optJSONObject("data");
            JSONArray list = data == null ? null : data.optJSONArray("list");
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item == null) continue;
                    JSONObject history = item.optJSONObject("history");
                    JSONObject row = new JSONObject();
                    int durationSec = item.optInt("duration", 0);
                    int progress = item.optInt("progress", 0);
                    String bvid = history == null ? item.optString("bvid", "") : history.optString("bvid", "");
                    long aid = history == null ? item.optLong("oid", 0) : history.optLong("oid", 0);
                    long cid = history == null ? 0 : history.optLong("cid", 0);
                    String owner = strip(item.optString("author_name", "UP 主"));
                    row.put("bvid", bvid);
                    row.put("aid", aid);
                    row.put("cid", cid);
                    row.put("title", strip(item.optString("title", "视频")));
                    row.put("pic", https(item.optString("cover", "")));
                    row.put("owner", owner);
                    row.put("mid", history == null ? 0 : history.optLong("mid", 0));
                    row.put("duration", duration(durationSec));
                    row.put("durationSec", durationSec);
                    row.put("progress", progress);
                    row.put("play", 0);
                    row.put("playText", "");
                    row.put("meta", owner + (durationSec > 0
                        ? " · 看到 " + duration(progress) + " / " + duration(durationSec)
                        : ""));
                    items.put(row);
                }
            }
            String next = "";
            JSONObject cursorObj = data == null ? null : data.optJSONObject("cursor");
            if (cursorObj != null) {
                long max = cursorObj.optLong("max", 0);
                long viewAt = cursorObj.optLong("view_at", 0);
                if (max > 0) next = max + "|" + viewAt;
            }
            out.put("ok", true);
            out.put("loggedIn", true);
            out.put("items", items);
            out.put("page", Math.max(1, page));
            out.put("next", next);
            out.put("title", "历史");
            if (items.length() == 0) out.put("note", "暂无历史");
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject following(int page) {
        if (!cookies.loggedIn()) return needLogin("登录后查看关注动态");
        JSONObject out = new JSONObject();
        try {
            JSONObject json = fetch("https://api.bilibili.com/x/polymer/web-dynamic/v1/feed/all?type=video&page="
                + Math.max(1, page) + "&features=itemOpusStyle");
            int code = json.optInt("code", -1);
            if (code == -101) return needLogin("登录后查看关注动态");
            if (code != 0) return apiFailure(code, json.optString("message", "关注接口不可用"));
            JSONObject data = json.optJSONObject("data");
            JSONArray list = data == null ? null : data.optJSONArray("items");
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item == null) continue;
                    JSONObject modules = item.optJSONObject("modules");
                    JSONObject dynamic = modules == null ? null : modules.optJSONObject("module_dynamic");
                    JSONObject major = dynamic == null ? null : dynamic.optJSONObject("major");
                    JSONObject archive = major == null ? null : major.optJSONObject("archive");
                    if (archive != null) items.put(dynamicVideo(item, archive));
                }
            }
            out.put("ok", true);
            out.put("loggedIn", true);
            out.put("items", items);
            out.put("page", Math.max(1, page));
            out.put("hasMore", list != null && list.length() >= 20);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject dynamicFeed(int page, String filter) {
        if (!cookies.loggedIn()) return needLogin("登录后查看动态");
        JSONObject out = new JSONObject();
        try {
            JSONObject json = fetch("https://api.bilibili.com/x/polymer/web-dynamic/v1/feed/all?type=all&page="
                + Math.max(1, page) + "&features=itemOpusStyle");
            int code = json.optInt("code", -1);
            if (code == -101) return needLogin("登录后查看动态");
            if (code != 0) return apiFailure(code, json.optString("message", "动态接口不可用"));
            JSONObject data = json.optJSONObject("data");
            JSONArray list = data == null ? null : data.optJSONArray("items");
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item == null) continue;
                    JSONObject row = dynamicRow(item);
                    if (row == null) continue;
                    String kind = row.optString("kind", "");
                    if ("video".equals(filter) && !"video".equals(kind)) continue;
                    if ("image".equals(filter) && "video".equals(kind)) continue;
                    items.put(row);
                }
            }
            out.put("ok", true);
            out.put("loggedIn", true);
            out.put("items", items);
            out.put("page", Math.max(1, page));
            out.put("hasMore", list != null && list.length() >= 20);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject messages(int page, String filter) {
        if (!cookies.loggedIn()) return needLogin("登录后查看消息");
        JSONObject out = new JSONObject();
        try {
            String kind = "reply";
            if ("at".equals(filter)) kind = "at";
            else if ("like".equals(filter)) kind = "like";
            JSONObject json = fetch("https://api.bilibili.com/x/msgfeed/" + kind
                + "?pn=" + Math.max(1, page) + "&ps=20");
            int code = json.optInt("code", -1);
            if (code == -101) return needLogin("登录后查看消息");
            if (code != 0) return apiFailure(code, json.optString("message", "消息接口不可用"));
            JSONObject data = json.optJSONObject("data");
            JSONArray list = data == null ? null : data.optJSONArray("items");
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item == null) continue;
                    JSONObject user = item.optJSONObject("user");
                    if (user == null) {
                        JSONArray users = item.optJSONArray("users");
                        if (users != null && users.length() > 0) user = users.optJSONObject(0);
                    }
                    JSONObject source = item.optJSONObject("item");
                    String text = "";
                    if (source != null) {
                        text = source.optString("source_content", "");
                        if (text.isEmpty()) text = source.optString("target_reply_content", "");
                        if (text.isEmpty()) text = source.optString("title", "");
                    }
                    if ("like".equals(kind)) {
                        int count = item.optInt("count", 0);
                        String name = user == null ? "有人" : user.optString("uname", "有人");
                        text = name + (count > 1 ? " 等 " + count + " 人" : "") + " 赞了你的评论";
                    }
                    JSONObject row = new JSONObject();
                    row.put("user", user == null ? "用户" : user.optString("uname", "用户"));
                    row.put("avatar", https(user == null ? "" : user.optString("avatar", "")));
                    row.put("mid", user == null ? 0 : user.optLong("mid", 0));
                    row.put("text", strip(text));
                    row.put("kind", kind);
                    row.put("unread", item.optInt("is_read", 1) == 0);
                    long time = item.optLong("reply_time",
                        item.optLong("at_time", item.optLong("like_time", 0)));
                    row.put("time", time);
                    items.put(row);
                }
            }
            out.put("ok", true);
            out.put("loggedIn", true);
            out.put("items", items);
            out.put("page", Math.max(1, page));
            out.put("kind", kind);
            out.put("hasMore", list != null && list.length() >= 20);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject comments(long aid, int page, int sort) {
        JSONObject out = new JSONObject();
        try {
            int order = sort == 0 ? 0 : 2;
            String raw = cookies.request("https://api.bilibili.com/x/v2/reply?type=1&oid=" + aid
                + "&pn=" + Math.max(1, page) + "&sort=" + order, null, null);
            JSONObject data = new JSONObject(raw).optJSONObject("data");
            JSONArray replies = data == null ? null : data.optJSONArray("replies");
            JSONArray items = new JSONArray();
            if (replies != null) {
                for (int i = 0; i < replies.length(); i += 1) {
                    JSONObject reply = replies.optJSONObject(i);
                    if (reply != null) items.put(replyRow(reply));
                }
            }
            out.put("ok", true);
            out.put("items", items);
            JSONObject pageInfo = data == null ? null : data.optJSONObject("page");
            out.put("count", pageInfo == null ? items.length() : pageInfo.optInt("count", items.length()));
            out.put("page", Math.max(1, page));
            out.put("hasMore", replies != null && replies.length() >= 20);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject commentsReplies(long aid, long root, int page) {
        JSONObject out = new JSONObject();
        try {
            JSONObject json = fetch("https://api.bilibili.com/x/v2/reply/reply?type=1&oid=" + aid
                + "&root=" + root + "&pn=" + Math.max(1, page) + "&ps=20");
            int code = json.optInt("code", -1);
            if (code != 0) return apiFailure(code, json.optString("message", "回复加载失败"));
            JSONObject data = json.optJSONObject("data");
            JSONArray replies = data == null ? null : data.optJSONArray("replies");
            JSONArray items = new JSONArray();
            if (replies != null) {
                for (int i = 0; i < replies.length(); i += 1) {
                    JSONObject reply = replies.optJSONObject(i);
                    if (reply != null) items.put(replyRow(reply));
                }
            }
            JSONObject pageInfo = data == null ? null : data.optJSONObject("page");
            out.put("ok", true);
            out.put("items", items);
            out.put("count", pageInfo == null ? items.length() : pageInfo.optInt("count", items.length()));
            out.put("page", Math.max(1, page));
            out.put("hasMore", replies != null && replies.length() >= 20);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    private JSONObject replyRow(JSONObject reply) {
        JSONObject row = new JSONObject();
        try {
            JSONObject member = reply.optJSONObject("member");
            JSONObject content = reply.optJSONObject("content");
            row.put("rpid", reply.optLong("rpid", 0));
            row.put("root", reply.optLong("root", 0));
            row.put("parent", reply.optLong("parent", 0));
            row.put("rcount", reply.optInt("rcount", 0));
            row.put("user", member == null ? "用户" : member.optString("uname", "用户"));
            row.put("avatar", member == null ? "" : https(member.optString("avatar", "")));
            row.put("message", content == null ? "" : content.optString("message", ""));
            row.put("like", reply.optInt("like", 0));
            row.put("time", reply.optLong("ctime", 0));
        } catch (Throwable ignored) {}
        return row;
    }

    /* ---------- UP space ---------- */

    JSONObject space(long mid, int page, String order) {
        JSONObject out = new JSONObject();
        try {
            if (mid <= 0) return apiFailure(-1, "缺少 UP 主 UID");
            int pn = Math.max(1, page);
            int ps = 20;
            String sort = "click".equals(order) ? "click" : "pubdate";
            Map<String, String> headers = new HashMap<>();
            headers.put("Referer", "https://space.bilibili.com/" + mid + "/video");
            headers.put("Origin", "https://space.bilibili.com");
            headers.put("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8");
            JSONObject json = null;
            try {
                json = fetch("https://api.bilibili.com/x/space/arc/search?mid=" + mid
                    + "&pn=" + pn + "&ps=" + ps + "&tid=0&keyword=&order=" + sort
                    + "&order_avoided=true&jsonp=jsonp", headers);
            } catch (Throwable ignored) {
            }
            JSONObject oldData = json == null ? null : json.optJSONObject("data");
            JSONObject oldList = oldData == null ? null : oldData.optJSONObject("list");
            JSONArray oldVlist = oldList == null ? null : oldList.optJSONArray("vlist");
            JSONObject oldPage = oldData == null ? null : oldData.optJSONObject("page");
            int oldCount = oldPage == null ? 0 : oldPage.optInt("count", 0);
            boolean usable = json != null && json.optInt("code", -1) == 0 && oldData != null
                && (oldCount == 0 || (oldVlist != null && oldVlist.length() > 0));
            if (!usable) {
                String key = wbiKey();
                if (!key.isEmpty()) {
                    Map<String, String> params = new HashMap<>();
                    params.put("mid", String.valueOf(mid));
                    params.put("pn", String.valueOf(pn));
                    params.put("ps", String.valueOf(ps));
                    params.put("tid", "0");
                    params.put("keyword", "");
                    params.put("order", sort);
                    params.put("platform", "web");
                    params.put("web_location", "1550101");
                    params.put("order_avoided", "true");
                    params.put("space_login_group", "2");
                    params.put("dm_img_list", "[]");
                    params.put("dm_img_str", "V2ViR0wgMS");
                    params.put("dm_cover_img_str", "SW50ZWwoUikgSEQgR3JhcGhpY3NJbnRlbA");
                    params.put("dm_img_inter", "{\"ds\":[],\"wh\":[0,0,0],\"of\":[0,0,0]}");
                    String query = wbiSign(params, key);
                    json = fetch("https://api.bilibili.com/x/space/wbi/arc/search?" + query, headers);
                }
            }
            int code = json == null ? -1 : json.optInt("code", -1);
            JSONObject data = json == null ? null : json.optJSONObject("data");
            if (code != 0 || data == null) {
                return apiFailure(code, json == null ? "space unavailable" : json.optString("message", "UP 主空间加载失败"));
            }
            JSONObject list = data.optJSONObject("list");
            JSONArray vlist = list == null ? null : list.optJSONArray("vlist");
            JSONObject pageInfo = data.optJSONObject("page");
            int total = pageInfo == null ? 0 : pageInfo.optInt("count", 0);
            JSONArray items = new JSONArray();
            if (vlist != null) {
                for (int index = 0; index < vlist.length(); index += 1) {
                    JSONObject video = vlist.optJSONObject(index);
                    if (video == null) continue;
                    String durationText = video.optString("duration", "");
                    int durationSec = durationSeconds(durationText);
                    JSONObject row = new JSONObject();
                    row.put("bvid", video.optString("bvid", ""));
                    row.put("aid", video.optLong("aid", 0));
                    row.put("cid", video.optLong("cid", 0));
                    row.put("title", strip(video.optString("title", "")));
                    row.put("pic", https(video.optString("pic", "")));
                    row.put("owner", strip(video.optString("author", "")));
                    row.put("mid", video.optLong("mid", mid));
                    row.put("duration", durationText);
                    row.put("durationSec", durationSec);
                    row.put("pubdate", video.optLong("pubdate", 0));
                    row.put("play", video.optLong("play", 0));
                    row.put("desc", strip(video.optString("description", "")));
                    row.put("meta", strip(video.optString("author", "")) + " · " + count(video.optLong("play", 0)) + " 播放");
                    items.put(row);
                }
            }
            out.put("ok", true);
            out.put("items", items);
            out.put("total", total);
            out.put("page", pn);
            out.put("hasMore", total > pn * ps || (total == 0 && items.length() >= ps));
            try {
                JSONObject cardJson = fetch("https://api.bilibili.com/x/web-interface/card?mid=" + mid + "&photo=true", headers);
                JSONObject cardData = cardJson.optJSONObject("data");
                JSONObject card = cardData == null ? null : cardData.optJSONObject("card");
                if (card != null) {
                    out.put("name", strip(card.optString("name", "")));
                    out.put("face", https(card.optString("face", "")));
                    out.put("sign", strip(card.optString("sign", "")));
                    out.put("follower", card.optLong("fans", 0));
                }
            } catch (Throwable ignored) {
            }
            try {
                JSONObject relation = fetch("https://api.bilibili.com/x/relation/stat?mid=" + mid);
                JSONObject stats = relation.optJSONObject("data");
                if (stats != null) {
                    out.put("follower", stats.optLong("follower", 0));
                    out.put("following", stats.optLong("following", 0));
                }
            } catch (Throwable ignored) {
            }
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    private String wbiKey() throws Exception {
        long now = System.currentTimeMillis();
        if (!cachedWbiKey.isEmpty() && now - cachedWbiAt < 6 * 60 * 60 * 1000L) {
            return cachedWbiKey;
        }
        JSONObject json = fetch("https://api.bilibili.com/x/web-interface/nav");
        JSONObject data = json.optJSONObject("data");
        JSONObject wbi = data == null ? null : data.optJSONObject("wbi_img");
        String img = wbi == null ? "" : wbiFileKey(wbi.optString("img_url", ""));
        String sub = wbi == null ? "" : wbiFileKey(wbi.optString("sub_url", ""));
        if (img.isEmpty() || sub.isEmpty()) return "";
        String raw = img + sub;
        StringBuilder mixed = new StringBuilder();
        for (int index : WBI_MIXIN_KEY) {
            if (index < raw.length()) mixed.append(raw.charAt(index));
        }
        cachedWbiKey = mixed.substring(0, Math.min(32, mixed.length()));
        cachedWbiAt = now;
        return cachedWbiKey;
    }

    private String wbiSign(Map<String, String> params, String key) throws Exception {
        TreeMap<String, String> sorted = new TreeMap<>(params);
        StringBuilder query = new StringBuilder();
        for (Map.Entry<String, String> entry : sorted.entrySet()) {
            if (entry.getValue() == null) continue;
            if (query.length() > 0) query.append('&');
            query.append(wbiEncode(entry.getKey())).append('=').append(wbiEncode(entry.getValue()));
        }
        long wts = System.currentTimeMillis() / 1000L;
        query.append("&wts=").append(wts);
        String wRid = md5(query.toString() + key);
        return query.append("&w_rid=").append(wRid).toString();
    }

    private static String wbiEncode(String value) throws Exception {
        return URLEncoder.encode(value, "UTF-8")
            .replace("+", "%20")
            .replace("*", "%2A")
            .replace("%7E", "~");
    }

    private static String wbiFileKey(String url) {
        if (url == null || url.isEmpty()) return "";
        int slash = url.lastIndexOf('/');
        String name = slash >= 0 ? url.substring(slash + 1) : url;
        int dot = name.indexOf('.');
        return dot > 0 ? name.substring(0, dot) : name;
    }

    private static String md5(String text) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("MD5");
        byte[] bytes = digest.digest(text.getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder(bytes.length * 2);
        for (byte value : bytes) hex.append(String.format(Locale.US, "%02x", value & 0xff));
        return hex.toString();
    }

    private static int durationSeconds(String text) {
        if (text == null || text.isEmpty()) return 0;
        String[] parts = text.split(":");
        int total = 0;
        for (String part : parts) {
            try {
                total = total * 60 + Integer.parseInt(part.trim());
            } catch (Exception ignored) {
            }
        }
        return total;
    }

    /* ---------- discovery ---------- */

    JSONObject ranking(int page) {
        JSONObject out = new JSONObject();
        try {
            JSONObject data = fetch("https://api.bilibili.com/x/web-interface/ranking/v2?rid=0&type=all")
                .optJSONObject("data");
            JSONArray list = data == null ? null : data.optJSONArray("list");
            JSONArray items = new JSONArray();
            int pn = Math.max(1, page);
            int start = (pn - 1) * 20;
            int total = list == null ? 0 : list.length();
            for (int i = start; i < Math.min(total, start + 20); i += 1) {
                JSONObject item = list.optJSONObject(i);
                if (item != null) items.put(video(item));
            }
            out.put("ok", true);
            out.put("items", items);
            out.put("page", pn);
            out.put("total", total);
            out.put("hasMore", start + 20 < total);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject bangumi(int page, int seasonType) {
        JSONObject out = new JSONObject();
        try {
            int type = seasonType <= 0 ? 1 : seasonType;
            JSONObject data = fetch("https://api.bilibili.com/pgc/season/index/result?season_type=" + type
                + "&page=" + Math.max(1, page) + "&pagesize=20&order=3&st=1&sort=0&type=1")
                .optJSONObject("data");
            JSONArray list = data == null ? null : data.optJSONArray("list");
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item == null) continue;
                    JSONObject row = new JSONObject();
                    row.put("kind", "season");
                    row.put("seasonId", item.optLong("season_id", 0));
                    row.put("title", strip(item.optString("title", "番剧")));
                    row.put("pic", https(item.optString("cover", "")));
                    row.put("owner", "番剧");
                    row.put("duration", "");
                    row.put("bvid", "");
                    row.put("aid", 0);
                    row.put("cid", 0);
                    String meta = strip(item.optString("index_show", ""));
                    double rating = item.optDouble("rating", 0);
                    if (rating > 0) meta += (meta.isEmpty() ? "" : " · ")
                        + String.format(Locale.CHINA, "%.1f 分", rating);
                    row.put("meta", meta);
                    row.put("badge", item.optString("badge", ""));
                    items.put(row);
                }
            }
            out.put("ok", true);
            out.put("items", items);
            out.put("page", Math.max(1, page));
            out.put("hasMore", list != null && list.length() >= 20);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject season(long seasonId) {
        JSONObject out = new JSONObject();
        try {
            JSONObject result = fetch("https://api.bilibili.com/pgc/view/web/season?season_id=" + seasonId)
                .optJSONObject("result");
            if (result == null) throw new IllegalStateException("season unavailable");
            JSONArray episodes = result.optJSONArray("episodes");
            JSONArray items = new JSONArray();
            if (episodes != null) {
                for (int i = 0; i < episodes.length(); i += 1) {
                    JSONObject episode = episodes.optJSONObject(i);
                    if (episode == null) continue;
                    JSONObject row = new JSONObject();
                    long epId = episode.optLong("id", episode.optLong("ep_id", 0));
                    row.put("epId", epId);
                    row.put("bvid", episode.optString("bvid", ""));
                    row.put("cid", episode.optLong("cid", 0));
                    row.put("aid", episode.optLong("aid", 0));
                    row.put("title", strip(episode.optString("long_title",
                        episode.optString("title", "第 " + (i + 1) + " 集"))));
                    row.put("duration", episode.optString("duration", ""));
                    row.put("pic", https(episode.optString("cover", "")));
                    items.put(row);
                }
            }
            out.put("ok", true);
            out.put("seasonId", seasonId);
            out.put("title", strip(result.optString("title", "番剧")));
            out.put("cover", https(result.optString("cover", "")));
            out.put("evaluate", strip(result.optString("evaluate", "")));
            out.put("episodes", items);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject playPgc(long epId, String bvid, long cid, int qn) {
        try {
            if (bvid != null && !bvid.isEmpty() && cid > 0) {
                JSONObject normal = api.playQns(bvid, cid, BiliApi.qualityLadder(qn));
                if (normal.optBoolean("ok")) return normal;
            }
            JSONObject json = fetch("https://api.bilibili.com/pgc/player/web/playurl?ep_id=" + epId
                + "&qn=" + (qn <= 0 ? 64 : qn) + "&fnval=1&fourk=0");
            int code = json.optInt("code", -1);
            JSONObject result = json.optJSONObject("result");
            if (code != 0 || result == null) {
                return apiFailure(code, json.optString("message", "番剧播放不可用"));
            }
            JSONArray durl = result.optJSONArray("durl");
            if (durl == null || durl.length() == 0) throw new IllegalStateException("pgc durl unavailable");
            JSONObject first = durl.optJSONObject(0);
            String remote = first.optString("url", "");
            if (remote.isEmpty()) throw new IllegalStateException("pgc url empty");
            JSONObject out = new JSONObject();
            int quality = result.optInt("quality", 16);
            String backup = "";
            if (first.optJSONArray("backup_url") != null && first.getJSONArray("backup_url").length() > 0) {
                backup = first.getJSONArray("backup_url").getString(0);
            }
            out.put("ok", true);
            out.put("cid", cid);
            out.put("url", remote);
            out.put("remote", remote);
            if (!backup.isEmpty()) {
                out.put("backup", backup);
                out.put("backupRemote", backup);
            }
            out.put("quality", quality);
            out.put("qualityLabel", qualityLabel(quality));
            JSONArray available = new JSONArray();
            JSONArray accept = result.optJSONArray("accept_quality");
            if (accept != null) {
                for (int i = 0; i < accept.length(); i += 1) {
                    int availableQn = accept.optInt(i, 0);
                    if (availableQn <= 0) continue;
                    String label = qualityLabel(availableQn);
                    if (!label.isEmpty()) available.put(label);
                }
            }
            if (available.length() == 0) available.put(qualityLabel(quality));
            out.put("available", available);
            out.put("format", result.optString("format", "mp4"));
            out.put("pgc", true);
            return out;
        } catch (Throwable error) {
            return error(error);
        }
    }

    JSONObject live(int page) {
        JSONObject out = new JSONObject();
        try {
            JSONObject json = fetch("https://api.live.bilibili.com/room/v1/room/get_user_recommend?page="
                + Math.max(1, page) + "&page_size=20");
            JSONArray list = json.optJSONArray("data");
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item == null) continue;
                    long roomId = item.optLong("roomid", 0);
                    if (roomId <= 0) continue;
                    JSONObject row = new JSONObject();
                    long online = item.optLong("online", 0);
                    String owner = strip(item.optString("uname", "主播"));
                    row.put("kind", "live");
                    row.put("live", true);
                    row.put("roomId", roomId);
                    row.put("title", strip(item.optString("title", "直播")));
                    row.put("pic", https(item.optString("user_cover",
                        item.optString("system_cover", item.optString("keyframe", "")))));
                    row.put("owner", owner);
                    row.put("mid", item.optLong("uid", 0));
                    row.put("duration", "LIVE");
                    row.put("online", online);
                    row.put("meta", owner + " · " + count(online) + " 人气");
                    row.put("area", strip(item.optString("areaName", "")));
                    items.put(row);
                }
            }
            out.put("ok", true);
            out.put("items", items);
            out.put("page", Math.max(1, page));
            out.put("hasMore", list != null && list.length() >= 20);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject liveDanmuInfo(long roomId) {
        JSONObject out = new JSONObject();
        try {
            Map<String, String> headers = new HashMap<>();
            headers.put("Referer", "https://live.bilibili.com/" + roomId);
            headers.put("Origin", "https://live.bilibili.com");
            Map<String, String> params = new HashMap<>();
            params.put("id", String.valueOf(roomId));
            params.put("type", "0");
            params.put("web_location", "444.8");
            String key = wbiKey();
            String query = key.isEmpty()
                ? "id=" + roomId + "&type=0&web_location=444.8"
                : wbiSign(params, key);
            JSONObject json = new JSONObject(cookies.request(
                "https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo?" + query,
                headers, null));
            int code = json.optInt("code", -1);
            if (code != 0) return apiFailure(code, json.optString("message", "直播弹幕信息不可用"));
            JSONObject data = json.optJSONObject("data");
            if (data == null) throw new IllegalStateException("直播弹幕信息为空");
            JSONArray hosts = data.optJSONArray("host_list");
            String host = "broadcastlv.chat.bilibili.com";
            int wssPort = 443;
            if (hosts != null && hosts.length() > 0) {
                JSONObject first = hosts.optJSONObject(0);
                if (first != null) {
                    host = first.optString("host", host);
                    wssPort = first.optInt("wss_port", 443);
                }
            }
            out.put("ok", true);
            out.put("token", data.optString("token", ""));
            out.put("host", host);
            out.put("wssPort", wssPort);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject liveRoom(long roomId) {
        JSONObject out = new JSONObject();
        try {
            Map<String, String> headers = new HashMap<>();
            headers.put("Referer", "https://live.bilibili.com/" + roomId);
            headers.put("Origin", "https://live.bilibili.com");
            JSONObject json = new JSONObject(cookies.request(
                "https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo?room_id=" + roomId
                    + "&protocol=0,1&format=0,1,2&codec=0,1&qn=10000&platform=web&ptype=8",
                headers, null));
            JSONObject data = json.optJSONObject("data");
            if (data == null) throw new IllegalStateException("live room unavailable");
            JSONObject playInfo = data.optJSONObject("playurl_info");
            JSONObject playurl = playInfo == null ? null : playInfo.optJSONObject("playurl");
            JSONArray streams = playurl == null ? null : playurl.optJSONArray("stream");
            String hls = "";
            String flv = "";
            if (streams != null) {
                for (int i = 0; i < streams.length(); i += 1) {
                    JSONObject stream = streams.optJSONObject(i);
                    if (stream == null) continue;
                    String protocol = stream.optString("protocol_name", "");
                    JSONArray formats = stream.optJSONArray("format");
                    if (formats == null) continue;
                    for (int j = 0; j < formats.length(); j += 1) {
                        JSONObject format = formats.optJSONObject(j);
                        if (format == null) continue;
                        JSONArray codecs = format.optJSONArray("codec");
                        if (codecs == null) continue;
                        for (int k = 0; k < codecs.length(); k += 1) {
                            JSONObject codec = codecs.optJSONObject(k);
                            if (codec == null || !"avc".equalsIgnoreCase(codec.optString("codec_name", ""))) continue;
                            String built = liveUrl(codec);
                            if (built.isEmpty()) continue;
                            String formatName = format.optString("format_name", "");
                            if ("http_hls".equals(protocol)) hls = built;
                            else if ("http_stream".equals(protocol) && "flv".equals(formatName)) flv = built;
                        }
                    }
                }
            }
            out.put("ok", true);
            out.put("roomId", roomId);
            out.put("liveStatus", data.optInt("live_status", 0));
            out.put("url", !flv.isEmpty() ? flv : hls);
            out.put("format", !flv.isEmpty() ? "flv" : "hls");
            out.put("title", strip(data.optString("title", "")));
            out.put("owner", strip(data.optString("uname", "")));
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject liveHistory(long roomId) {
        JSONObject out = new JSONObject();
        try {
            Map<String, String> headers = new HashMap<>();
            headers.put("Referer", "https://live.bilibili.com/" + roomId);
            headers.put("Origin", "https://live.bilibili.com");
            JSONObject json = new JSONObject(cookies.request(
                "https://api.live.bilibili.com/xlive/web-room/v1/dM/gethistory?roomid=" + roomId
                    + "&room_type=0",
                headers, null));
            JSONObject data = json.optJSONObject("data");
            JSONArray room = data == null ? null : data.optJSONArray("room");
            JSONArray items = new JSONArray();
            if (room != null) {
                for (int i = Math.max(0, room.length() - 20); i < room.length(); i += 1) {
                    JSONObject row = room.optJSONObject(i);
                    if (row == null) continue;
                    String text = row.optString("text", "");
                    if (text.isEmpty()) continue;
                    String name = row.optString("nickname", "");
                    if (name.isEmpty()) {
                        JSONObject user = row.optJSONObject("user");
                        JSONObject base = user == null ? null : user.optJSONObject("base");
                        name = base == null ? "" : base.optString("name", "");
                    }
                    items.put(new JSONObject()
                        .put("user", name.isEmpty() ? "观众" : name)
                        .put("text", text)
                        .put("time", row.optString("timeline", "")));
                }
            }
            out.put("ok", true);
            out.put("items", items);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    private String liveUrl(JSONObject codec) {
        try {
            String base = codec.optString("base_url", "");
            JSONArray infos = codec.optJSONArray("url_info");
            if (infos == null || infos.length() == 0) return "";
            JSONObject info = infos.optJSONObject(0);
            if (info == null) return "";
            String host = info.optString("host", "");
            String extra = info.optString("extra", "");
            if (host.isEmpty() || base.isEmpty()) return "";
            String url = host + base;
            if (!extra.isEmpty()) url += (base.endsWith("?") || base.endsWith("&") ? "" : "&") + extra;
            return url;
        } catch (Throwable ignored) {
            return "";
        }
    }

    JSONObject zone(int rid, int page) {
        JSONObject out = new JSONObject();
        try {
            int area = rid <= 0 ? 1 : rid;
            JSONObject data = fetch("https://api.bilibili.com/x/web-interface/newlist?rid=" + area
                + "&pn=" + Math.max(1, page) + "&ps=20").optJSONObject("data");
            JSONArray archives = data == null ? null : data.optJSONArray("archives");
            JSONArray items = new JSONArray();
            if (archives != null) {
                for (int i = 0; i < archives.length(); i += 1) {
                    JSONObject item = archives.optJSONObject(i);
                    if (item != null) items.put(video(item));
                }
            }
            out.put("ok", true);
            out.put("items", items);
            out.put("page", Math.max(1, page));
            out.put("rid", area);
            out.put("title", data == null ? "分区" : strip(data.optString("name", "分区")));
            out.put("hasMore", archives != null && archives.length() >= 20);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject videoInfo(String bvid) {
        JSONObject out = new JSONObject();
        try {
            JSONObject data = fetch("https://api.bilibili.com/x/web-interface/view?bvid=" + bvid)
                .optJSONObject("data");
            if (data == null) throw new IllegalStateException("video unavailable");
            JSONObject owner = data.optJSONObject("owner");
            JSONObject stat = data.optJSONObject("stat");
            JSONArray pages = data.optJSONArray("pages");
            JSONObject row = new JSONObject();
            row.put("ok", true);
            row.put("bvid", data.optString("bvid", bvid));
            row.put("aid", data.optLong("aid", 0));
            row.put("cid", data.optLong("cid", 0));
            row.put("title", strip(data.optString("title", "")));
            row.put("desc", strip(data.optString("desc", "")));
            row.put("pic", https(data.optString("pic", "")));
            row.put("pubdate", data.optLong("pubdate", 0));
            row.put("duration", duration(data.optInt("duration", 0)));
            row.put("durationSec", data.optInt("duration", 0));
            row.put("seasonId", data.optLong("season_id", 0));
            if (owner != null) {
                row.put("mid", owner.optLong("mid", 0));
                row.put("owner", strip(owner.optString("name", "UP 主")));
                row.put("ownerFace", https(owner.optString("face", "")));
            }
            if (stat != null) {
                JSONObject s = new JSONObject();
                s.put("view", stat.optLong("view", 0));
                s.put("danmaku", stat.optLong("danmaku", 0));
                s.put("reply", stat.optLong("reply", 0));
                s.put("favorite", stat.optLong("favorite", 0));
                s.put("coin", stat.optLong("coin", 0));
                s.put("share", stat.optLong("share", 0));
                s.put("like", stat.optLong("like", 0));
                row.put("stat", s);
            }
            JSONArray pageItems = new JSONArray();
            if (pages != null) {
                for (int i = 0; i < pages.length(); i += 1) {
                    JSONObject page = pages.optJSONObject(i);
                    if (page == null) continue;
                    JSONObject p = new JSONObject();
                    p.put("cid", page.optLong("cid", 0));
                    p.put("page", page.optInt("page", i + 1));
                    p.put("title", strip(page.optString("part", "")));
                    p.put("duration", page.optInt("duration", 0));
                    pageItems.put(p);
                }
            }
            row.put("pages", pageItems);
            if (cookies.loggedIn()) {
                try {
                    JSONObject relation = fetch("https://api.bilibili.com/x/web-interface/archive/relation?bvid=" + bvid)
                        .optJSONObject("data");
                    if (relation != null && relation.optJSONObject("relation") != null) {
                        relation = relation.optJSONObject("relation");
                    }
                    if (relation != null) {
                        row.put("liked", relation.optBoolean("like", false));
                        row.put("coined", relation.optInt("coin", 0));
                        row.put("faved", relation.optBoolean("favorite", false));
                        row.put("followed", relation.optBoolean("attention", false));
                    }
                } catch (Throwable ignored) {}
            }
            out = row;
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    JSONObject related(String bvid) {
        JSONObject out = new JSONObject();
        try {
            String id = bvid == null ? "" : bvid.trim();
            if (id.isEmpty()) throw new IllegalArgumentException("missing bvid");
            JSONObject json = fetch("https://api.bilibili.com/x/web-interface/archive/related?bvid=" + id);
            int code = json.optInt("code", 0);
            JSONArray list = json.optJSONArray("data");
            if (code != 0) {
                out.put("ok", false);
                out.put("error", json.optString("message", "相关推荐加载失败"));
                return out;
            }
            JSONArray items = new JSONArray();
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject item = list.optJSONObject(i);
                    if (item != null) items.put(video(item));
                }
            }
            out.put("ok", true);
            out.put("bvid", id);
            out.put("items", items);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    /* ---------- writes ---------- */

    JSONObject like(long aid, boolean on) {
        if (!canWrite()) return needLogin("请先登录");
        try {
            JSONObject json = post("https://api.bilibili.com/x/web-interface/archive/like",
                form("aid", String.valueOf(aid), "like", on ? "1" : "0", "csrf", csrf()));
            return writeResult(json, "liked", on);
        } catch (Throwable error) {
            return error(error);
        }
    }

    JSONObject coin(long aid, int count, boolean likeAlso) {
        if (!canWrite()) return needLogin("请先登录");
        try {
            JSONObject json = post("https://api.bilibili.com/x/web-interface/coin/add",
                form("aid", String.valueOf(aid), "multiply", String.valueOf(Math.max(1, Math.min(2, count))),
                    "select_like", likeAlso ? "1" : "0", "csrf", csrf()));
            JSONObject out = writeResult(json, "coined", true);
            if (out.optBoolean("ok")) out.put("count", Math.max(1, Math.min(2, count)));
            return out;
        } catch (Throwable error) {
            return error(error);
        }
    }

    JSONObject favorite(long aid, boolean on) {
        if (!canWrite()) return needLogin("请先登录");
        try {
            long folder = defaultFolderId();
            if (folder <= 0) return apiFailure(-1, "没有可用的收藏夹");
            String body = form(
                "rid", String.valueOf(aid),
                "type", "2",
                "add_media_ids", on ? String.valueOf(folder) : "",
                "del_media_ids", on ? "" : String.valueOf(folder),
                "csrf", csrf()
            );
            JSONObject json = post("https://api.bilibili.com/x/v3/fav/resource/deal", body);
            return writeResult(json, "faved", on);
        } catch (Throwable error) {
            return error(error);
        }
    }

    JSONObject follow(long mid, boolean on) {
        if (!canWrite()) return needLogin("请先登录");
        try {
            JSONObject json = post("https://api.bilibili.com/x/relation/modify",
                form("fid", String.valueOf(mid), "act", on ? "1" : "2",
                    "re_src", "11", "csrf", csrf()));
            return writeResult(json, "followed", on);
        } catch (Throwable error) {
            return error(error);
        }
    }

    JSONObject sendComment(long aid, String message) {
        if (!canWrite()) return needLogin("请先登录");
        try {
            JSONObject json = post("https://api.bilibili.com/x/v2/reply/add",
                form("oid", String.valueOf(aid), "type", "1", "message", message, "csrf", csrf()));
            JSONObject out = writeResult(json, "sent", true);
            if (out.optBoolean("ok")) {
                JSONObject data = json.optJSONObject("data");
                out.put("rpid", data == null ? 0 : data.optLong("rpid", 0));
            }
            return out;
        } catch (Throwable error) {
            return error(error);
        }
    }

    JSONObject sendDanmaku(long cid, String message, long progressMs) {
        if (!canWrite()) return needLogin("请先登录");
        try {
            JSONObject json = post("https://api.bilibili.com/x/v2/dm/post",
                form("type", "1", "oid", String.valueOf(cid), "msg", message,
                    "progress", String.valueOf(Math.max(0, progressMs)),
                    "color", "16777215", "fontsize", "25", "pool", "0",
                    "mode", "1", "plat", "1", "csrf", csrf()));
            return writeResult(json, "sent", true);
        } catch (Throwable error) {
            return error(error);
        }
    }

    /* ---------- DASH ---------- */

    JSONObject dash(String bvid, long cid, int qn) {
        JSONObject out = new JSONObject();
        try {
            if (cid <= 0) cid = api.resolveCid(bvid);
            if (cid <= 0) throw new IllegalStateException("cid not found");
            if (qn <= 0) qn = 120;
            String url = "https://api.bilibili.com/x/player/playurl?bvid=" + bvid + "&cid=" + cid
                + "&qn=" + qn + "&fnval=4048&fourk=1";
            JSONObject json = fetch(url);
            int code = json.optInt("code", -1);
            JSONObject data = json.optJSONObject("data");
            if (code != 0 || data == null) return apiFailure(code, json.optString("message", "DASH 播放不可用"));
            JSONObject dash = data.optJSONObject("dash");
            if (dash == null) return apiFailure(-1, "当前视频没有 DASH 流");
            JSONArray videos = dash.optJSONArray("video");
            JSONArray audios = dash.optJSONArray("audio");
            JSONArray videoRows = new JSONArray();
            JSONArray audioRows = new JSONArray();
            if (videos != null) {
                for (int i = 0; i < videos.length(); i += 1) {
                    JSONObject track = videos.optJSONObject(i);
                    if (track == null || (track.optInt("codecid", 0) != 7 && track.optInt("codecid", 0) != 12 && track.optInt("codecid", 0) != 13)) continue;
                    JSONObject row = dashTrack(track);
                    if (row != null) videoRows.put(row);
                }
            }
            if (audios != null) {
                for (int i = 0; i < audios.length(); i += 1) {
                    JSONObject track = audios.optJSONObject(i);
                    if (track == null) continue;
                    JSONObject row = dashTrack(track);
                    if (row != null) audioRows.put(row);
                }
            }
            if (videoRows.length() == 0 || audioRows.length() == 0) {
                return apiFailure(-1, "当前清晰度没有可用的 DASH 轨道");
            }
            out.put("ok", true);
            out.put("quality", data.optInt("quality", 0));
            out.put("qualityLabel", qualityLabel(data.optInt("quality", 0)));
            out.put("acceptQuality", data.optJSONArray("accept_quality"));
            out.put("video", videoRows);
            out.put("audio", audioRows);
            out.put("dur", data.optLong("timelength", 0));
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    private JSONObject dashTrack(JSONObject track) {
        try {
            String base = track.optString("baseUrl", track.optString("base_url", ""));
            if (base.isEmpty()) return null;
            JSONObject row = new JSONObject();
            row.put("qn", track.optInt("id", 0));
            row.put("codecid", track.optInt("codecid", 0));
            row.put("bandwidth", track.optLong("bandwidth", 0));
            row.put("mime", track.optString("mimeType", "video/mp4"));
            row.put("codecs", track.optString("codecs", ""));
            row.put("width", track.optInt("width", 0));
            row.put("height", track.optInt("height", 0));
            row.put("frameRate", track.optString("frameRate", track.optString("frame_rate", "")));
            row.put("remote", base);
            JSONArray backups = track.optJSONArray("backupUrl");
            if (backups == null) backups = track.optJSONArray("backup_url");
            String backup = backups != null && backups.length() > 0 ? backups.optString(0, "") : "";
            row.put("url", base);
            if (!backup.isEmpty()) {
                row.put("backupRemote", backup);
                row.put("backup", backup);
            }
            return row;
        } catch (Throwable ignored) {
            return null;
        }
    }


    JSONObject memberCenter() {
        if (!cookies.loggedIn()) return needLogin("登录后查看会员中心");
        JSONObject out = new JSONObject();
        try {
            JSONObject reward = fetch("https://api.bilibili.com/x/member/web/exp/reward");
            int code = reward.optInt("code", -1);
            if (code == -101) return needLogin("登录后查看会员中心");
            JSONObject data = reward.optJSONObject("data");
            JSONArray tasks = new JSONArray();
            tasks.put(task("login", "每日登录", data != null && data.optBoolean("login", false), 5));
            tasks.put(task("watch", "每日观看", data != null && data.optBoolean("watch", false), 5));
            tasks.put(task("share", "每日分享", data != null && data.optBoolean("share", false), 5));
            int coins = data == null ? 0 : data.optInt("coins", 0);
            JSONObject coinTask = task("coins", "每日投币", coins >= 50, 50);
            coinTask.put("detail", "已获得 " + coins + " / 50 经验");
            tasks.put(coinTask);
            out.put("ok", true);
            out.put("tasks", tasks);
            out.put("exp", data == null ? 0 : data.optInt("coins", 0));
            try {
                JSONObject vip = fetch("https://api.bilibili.com/x/vip/web/user/info").optJSONObject("data");
                out.put("vip", vip != null && vip.optInt("vip_status", 0) == 1);
                out.put("vipType", vip == null ? 0 : vip.optInt("vip_type", 0));
                out.put("vipDue", vip == null ? 0 : vip.optLong("vip_due_date", 0));
            } catch (Throwable ignored) {}
            try {
                JSONObject log = fetch("https://api.bilibili.com/x/member/web/exp/log").optJSONObject("data");
                JSONArray source = log == null ? null : log.optJSONArray("list");
                JSONArray rows = new JSONArray();
                if (source != null) {
                    for (int i = 0; i < Math.min(8, source.length()); i += 1) {
                        JSONObject row = source.optJSONObject(i);
                        if (row == null) continue;
                        rows.put(new JSONObject()
                            .put("delta", row.optInt("delta", 0))
                            .put("reason", strip(row.optString("reason", "")))
                            .put("time", row.optString("time", "")));
                    }
                }
                out.put("log", rows);
            } catch (Throwable ignored) {}
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    private JSONObject task(String key, String label, boolean done, int reward) throws Exception {
        return new JSONObject().put("key", key).put("label", label).put("done", done).put("reward", reward);
    }

    /* ---------- AI (OpenAI-compatible) ---------- */

    JSONObject aiChat(String endpoint, String apiKey, String model, String prompt) {
        JSONObject out = new JSONObject();
        try {
            if (endpoint == null || endpoint.isEmpty()) throw new IllegalStateException("API 地址为空");
            if (apiKey == null || apiKey.isEmpty()) {
                out.put("ok", false);
                out.put("needKey", true);
                out.put("error", "需要先填写 API Key");
                return out;
            }
            if (prompt == null || prompt.trim().isEmpty()) throw new IllegalStateException("请先输入内容");
            JSONObject payload = new JSONObject();
            payload.put("model", model == null || model.isEmpty() ? "deepseek-chat" : model);
            payload.put("stream", false);
            JSONArray messages = new JSONArray();
            messages.put(new JSONObject().put("role", "user").put("content", prompt));
            payload.put("messages", messages);
            byte[] body = payload.toString().getBytes(StandardCharsets.UTF_8);
            java.net.HttpURLConnection connection = (java.net.HttpURLConnection) new java.net.URL(endpoint).openConnection();
            connection.setConnectTimeout(15000);
            connection.setReadTimeout(60000);
            connection.setRequestMethod("POST");
            connection.setDoOutput(true);
            connection.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            connection.setRequestProperty("Authorization", "Bearer " + apiKey);
            connection.setFixedLengthStreamingMode(body.length);
            try (java.io.OutputStream output = connection.getOutputStream()) {
                output.write(body);
            }
            int code = connection.getResponseCode();
            java.io.InputStream stream = code >= 400 ? connection.getErrorStream() : connection.getInputStream();
            String raw = "";
            if (stream != null) {
                try (java.io.ByteArrayOutputStream buffer = new java.io.ByteArrayOutputStream()) {
                    byte[] chunk = new byte[8192];
                    int read;
                    while ((read = stream.read(chunk)) >= 0) buffer.write(chunk, 0, read);
                    raw = buffer.toString("UTF-8");
                }
            }
            if (code < 200 || code >= 300) {
                out.put("ok", false);
                out.put("error", "HTTP " + code + " · " + (raw.isEmpty() ? "接口无响应" : raw.substring(0, Math.min(240, raw.length()))));
                return out;
            }
            JSONObject json = new JSONObject(raw);
            JSONArray choices = json.optJSONArray("choices");
            String text = "";
            if (choices != null && choices.length() > 0) {
                JSONObject choice = choices.optJSONObject(0);
                JSONObject message = choice == null ? null : choice.optJSONObject("message");
                if (message != null) text = message.optString("content", "");
                if (text.isEmpty()) text = choice == null ? "" : choice.optString("text", "");
            }
            if (text.isEmpty() && json.optJSONObject("error") != null) {
                out.put("ok", false);
                out.put("error", json.getJSONObject("error").optString("message", "AI 返回错误"));
                return out;
            }
            out.put("ok", true);
            out.put("text", text);
            out.put("model", json.optString("model", model));
            JSONObject usage = json.optJSONObject("usage");
            if (usage != null) out.put("usage", usage);
        } catch (Throwable error) {
            out = error(error);
        }
        return out;
    }

    /* ---------- helpers ---------- */

    private JSONObject writeResult(JSONObject json, String key, boolean value) {
        JSONObject out = new JSONObject();
        try {
            int code = json.optInt("code", -1);
            out.put("ok", code == 0);
            out.put("code", code);
            out.put("error", code == 0 ? "" : json.optString("message", "操作失败"));
            out.put(key, value);
            if (code == -101 || code == -400) out.put("needLogin", true);
        } catch (Throwable ignored) {}
        return out;
    }

    private JSONObject needLogin(String message) {
        JSONObject out = new JSONObject();
        try {
            out.put("ok", false);
            out.put("needLogin", true);
            out.put("error", message);
        } catch (Throwable ignored) {}
        return out;
    }

    private JSONObject apiFailure(int code, String message) {
        JSONObject out = new JSONObject();
        try {
            out.put("ok", false);
            out.put("code", code);
            out.put("error", message == null || message.isEmpty() ? "操作失败" : message);
            if (code == -101 || code == -400) out.put("needLogin", true);
        } catch (Throwable ignored) {}
        return out;
    }

    private JSONObject navData() throws Exception {
        return fetch("https://api.bilibili.com/x/web-interface/nav").optJSONObject("data");
    }

    private long accountMid() {
        if (cachedMid > 0) return cachedMid;
        try {
            JSONObject data = navData();
            if (data != null) cachedMid = data.optLong("mid", 0);
        } catch (Throwable ignored) {}
        if (cachedMid <= 0) {
            try {
                cachedMid = Long.parseLong(cookies.get("DedeUserID"));
            } catch (Throwable ignored) {}
        }
        return cachedMid;
    }

    private long defaultFolderId() {
        if (cachedFolderId > 0) return cachedFolderId;
        long mid = accountMid();
        if (mid <= 0) return 0;
        try {
            JSONObject data = fetch("https://api.bilibili.com/x/v3/fav/folder/created/list-all?up_mid=" + mid)
                .optJSONObject("data");
            JSONArray list = data == null ? null : data.optJSONArray("list");
            long first = 0;
            if (list != null) {
                for (int i = 0; i < list.length(); i += 1) {
                    JSONObject folder = list.optJSONObject(i);
                    if (folder == null) continue;
                    long id = folder.optLong("id", 0);
                    if (id <= 0) continue;
                    if (first == 0) first = id;
                    if (folder.optInt("media_count", 0) > 0) { first = id; break; }
                }
            }
            cachedFolderId = first;
        } catch (Throwable ignored) {}
        return cachedFolderId;
    }

    private String csrf() {
        String token = cookies.get("bili_jct");
        return token == null ? "" : token;
    }

    private boolean canWrite() {
        return cookies.loggedIn() && !csrf().isEmpty();
    }

    private JSONObject fetch(String url) throws Exception {
        return new JSONObject(cookies.request(url, null, null));
    }

    private JSONObject fetch(String url, Map<String, String> headers) throws Exception {
        return new JSONObject(cookies.request(url, headers, null));
    }

    private JSONObject post(String url, String body) throws Exception {
        Map<String, String> headers = new HashMap<>();
        headers.put("Origin", "https://www.bilibili.com");
        headers.put("Referer", "https://www.bilibili.com/");
        return new JSONObject(cookies.request(url, headers, "POST", body));
    }

    private String form(String... pairs) throws Exception {
        StringBuilder body = new StringBuilder();
        for (int i = 0; i + 1 < pairs.length; i += 2) {
            if (body.length() > 0) body.append('&');
            body.append(URLEncoder.encode(pairs[i], "UTF-8"));
            body.append('=');
            body.append(URLEncoder.encode(pairs[i + 1] == null ? "" : pairs[i + 1], "UTF-8"));
        }
        return body.toString();
    }

    private JSONObject video(JSONObject item) {
        JSONObject out = new JSONObject();
        try {
            JSONObject owner = item.optJSONObject("owner");
            JSONObject stat = item.optJSONObject("stat");
            String name = owner == null ? strip(item.optString("author", "UP 主"))
                : strip(owner.optString("name", "UP 主"));
            long play = stat == null ? 0 : stat.optLong("view", 0);
            out.put("bvid", item.optString("bvid", ""));
            out.put("aid", item.optLong("aid", 0));
            out.put("cid", item.optLong("cid", 0));
            out.put("mid", owner == null ? 0 : owner.optLong("mid", 0));
            out.put("title", strip(item.optString("title", "视频")));
            out.put("pic", https(item.optString("pic", item.optString("cover", ""))));
            out.put("owner", name);
            out.put("duration", duration(item.optInt("duration", 0)));
            out.put("durationSec", item.optInt("duration", 0));
            out.put("pubdate", item.optLong("pubdate", 0));
            out.put("play", play);
            out.put("playText", count(play));
            out.put("desc", strip(item.optString("desc", "")));
            out.put("meta", name + " · " + count(play) + " 播放");
        } catch (Throwable ignored) {}
        return out;
    }

    private JSONObject mediaVideo(JSONObject media) {
        JSONObject out = new JSONObject();
        try {
            JSONObject upper = media.optJSONObject("upper");
            JSONObject cnt = media.optJSONObject("cnt_info");
            long play = cnt == null ? 0 : cnt.optLong("play", 0);
            String name = upper == null ? "UP 主" : strip(upper.optString("name", "UP 主"));
            out.put("bvid", media.optString("bvid", ""));
            out.put("aid", media.optLong("id", 0));
            out.put("cid", media.optLong("cid", 0));
            out.put("mid", upper == null ? 0 : upper.optLong("mid", 0));
            out.put("title", strip(media.optString("title", "视频")));
            out.put("pic", https(media.optString("cover", media.optString("pic", ""))));
            out.put("owner", name);
            out.put("duration", duration(media.optInt("duration", 0)));
            out.put("durationSec", media.optInt("duration", 0));
            out.put("play", play);
            out.put("playText", count(play));
            out.put("desc", strip(media.optString("intro", "")));
            out.put("meta", name + " · " + count(play) + " 播放");
        } catch (Throwable ignored) {}
        return out;
    }

    private JSONObject dynamicVideo(JSONObject item, JSONObject archive) {
        JSONObject out = new JSONObject();
        try {
            JSONObject modules = item.optJSONObject("modules");
            JSONObject author = modules == null ? null : modules.optJSONObject("module_author");
            JSONObject stat = archive.optJSONObject("stat");
            String name = author == null ? "UP 主" : strip(author.optString("name", "UP 主"));
            long play = stat == null ? 0 : stat.optLong("play", 0);
            String durationText = archive.optString("duration_text", "");
            out.put("bvid", archive.optString("bvid", ""));
            out.put("aid", archive.optLong("aid", 0));
            out.put("cid", archive.optLong("cid", 0));
            out.put("mid", author == null ? 0 : author.optLong("mid", 0));
            out.put("title", strip(archive.optString("title", "视频")));
            out.put("pic", https(archive.optString("cover", "")));
            out.put("owner", name);
            out.put("duration", durationText.isEmpty() ? "00:00" : durationText);
            out.put("durationSec", parseDuration(durationText));
            out.put("play", play);
            out.put("playText", count(play));
            out.put("meta", name + " · " + count(play) + " 播放");
        } catch (Throwable ignored) {}
        return out;
    }

    private JSONObject dynamicRow(JSONObject item) {
        try {
            JSONObject modules = item.optJSONObject("modules");
            if (modules == null) return null;
            JSONObject author = modules.optJSONObject("module_author");
            JSONObject dynamic = modules.optJSONObject("module_dynamic");
            JSONObject desc = dynamic == null ? null : dynamic.optJSONObject("desc");
            JSONObject major = dynamic == null ? null : dynamic.optJSONObject("major");
            JSONObject row = new JSONObject();
            row.put("id", item.optString("id_str", ""));
            row.put("type", item.optString("type", ""));
            row.put("author", author == null ? "用户" : strip(author.optString("name", "用户")));
            row.put("avatar", https(author == null ? "" : author.optString("face", "")));
            row.put("mid", author == null ? 0 : author.optLong("mid", 0));
            row.put("time", author == null ? 0 : author.optLong("pub_ts", 0));
            String text = desc == null ? "" : strip(desc.optString("text", ""));
            JSONArray images = new JSONArray();
            JSONObject archive = major == null ? null : major.optJSONObject("archive");
            if (archive != null) {
                row.put("kind", "video");
                row.put("video", dynamicVideo(item, archive));
            } else {
                JSONObject draw = major == null ? null : major.optJSONObject("draw");
                if (draw != null) {
                    JSONArray pictures = draw.optJSONArray("items");
                    if (pictures != null) {
                        for (int i = 0; i < Math.min(9, pictures.length()); i += 1) {
                            JSONObject picture = pictures.optJSONObject(i);
                            if (picture != null) images.put(https(picture.optString("src", "")));
                        }
                    }
                }
                JSONObject opus = major == null ? null : major.optJSONObject("opus");
                if (opus != null) {
                    JSONArray pictures = opus.optJSONArray("pics");
                    if (pictures != null) {
                        for (int i = 0; i < Math.min(9, pictures.length()); i += 1) {
                            JSONObject picture = pictures.optJSONObject(i);
                            if (picture != null) images.put(https(picture.optString("url", "")));
                        }
                    }
                    JSONObject summary = opus.optJSONObject("summary");
                    if (text.isEmpty() && summary != null) text = strip(summary.optString("text", ""));
                }
                row.put("kind", images.length() > 0 ? "image" : "text");
            }
            row.put("text", text);
            row.put("images", images);
            JSONObject stat = modules.optJSONObject("module_stat");
            JSONObject like = stat == null ? null : stat.optJSONObject("like");
            JSONObject comment = stat == null ? null : stat.optJSONObject("comment");
            row.put("likes", like == null ? 0 : like.optInt("count", 0));
            row.put("comments", comment == null ? 0 : comment.optInt("count", 0));
            return row;
        } catch (Throwable ignored) {
            return null;
        }
    }

    private static int parseDuration(String text) {
        if (text == null || text.isEmpty()) return 0;
        String[] parts = text.split(":");
        int total = 0;
        try {
            for (String part : parts) total = total * 60 + Integer.parseInt(part.trim());
        } catch (Throwable ignored) {
            return 0;
        }
        return total;
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

    private static String qualityLabel(int quality) {
        switch (quality) {
            case 120: return "4K";
            case 116: return "1080P60";
            case 112: return "1080P+";
            case 80: return "1080P";
            case 74: return "720P60";
            case 64: return "720P";
            case 32: return "480P";
            case 16: return "360P";
            default: return quality + "P";
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
            out.put("error", error == null ? "unknown"
                : (error.getMessage() == null ? error.getClass().getSimpleName() : error.getMessage()));
        } catch (Throwable ignored) {}
        return out;
    }
}
