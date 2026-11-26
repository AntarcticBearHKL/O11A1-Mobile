package com.o11a1.videotest;

import org.json.JSONObject;

final class PlayRequest {
    String bvid = "";
    String title = "";
    String owner = "";
    String pic = "";
    String duration = "";
    long aid = 0;
    long cid = 0;
    long mid = 0;
    long epId = 0;
    long roomId = 0;
    int progressSec = 0;
    boolean live = false;
    boolean pgc = false;

    static PlayRequest from(VideoItem item) {
        PlayRequest request = new PlayRequest();
        request.bvid = item.bvid;
        request.title = item.title;
        request.owner = item.owner;
        request.pic = item.pic;
        request.duration = item.duration;
        request.aid = item.aid;
        request.cid = item.cid;
        request.mid = item.mid;
        return request;
    }
}

final class ModuleItem {
    enum Kind { VIDEO, SEASON, LIVE, MESSAGE, EPISODE }

    Kind kind = Kind.VIDEO;
    String bvid = "";
    String title = "";
    String pic = "";
    String owner = "";
    String meta = "";
    String duration = "";
    String badge = "";
    String user = "";
    String avatar = "";
    String text = "";
    long aid = 0;
    long cid = 0;
    long mid = 0;
    long seasonId = 0;
    long epId = 0;
    long roomId = 0;
    long time = 0;
    long play = 0;
    String playText = "";
    int progressSec = 0;

    static ModuleItem fromVideo(JSONObject json) {
        ModuleItem item = new ModuleItem();
        item.kind = Kind.VIDEO;
        item.bvid = json.optString("bvid", "");
        item.aid = json.optLong("aid", 0);
        item.cid = json.optLong("cid", 0);
        item.mid = json.optLong("mid", 0);
        item.title = json.optString("title", "视频");
        item.pic = json.optString("pic", "");
        item.owner = json.optString("owner", "UP 主");
        item.meta = json.optString("meta", item.owner);
        item.duration = json.optString("duration", "00:00");
        item.play = json.optLong("play", 0);
        item.playText = json.optString("playText", "");
        item.progressSec = json.optInt("progress", 0);
        return item;
    }

    static ModuleItem fromSeason(JSONObject json) {
        ModuleItem item = new ModuleItem();
        item.kind = Kind.SEASON;
        item.seasonId = json.optLong("seasonId", 0);
        item.title = json.optString("title", "番剧");
        item.pic = json.optString("pic", "");
        item.owner = "番剧";
        item.meta = json.optString("meta", "");
        item.badge = json.optString("badge", "");
        return item;
    }

    static ModuleItem fromLive(JSONObject json) {
        ModuleItem item = new ModuleItem();
        item.kind = Kind.LIVE;
        item.roomId = json.optLong("roomId", 0);
        item.title = json.optString("title", "直播");
        item.pic = json.optString("pic", "");
        item.owner = json.optString("owner", "主播");
        item.meta = json.optString("meta", item.owner);
        item.duration = "LIVE";
        item.badge = json.optString("area", "");
        return item;
    }

    static ModuleItem fromMessage(JSONObject json) {
        ModuleItem item = new ModuleItem();
        item.kind = Kind.MESSAGE;
        item.user = json.optString("user", "用户");
        item.avatar = json.optString("avatar", "");
        item.text = json.optString("text", "");
        item.time = json.optLong("time", 0);
        item.mid = json.optLong("mid", 0);
        return item;
    }

    static ModuleItem fromEpisode(JSONObject json) {
        ModuleItem item = new ModuleItem();
        item.kind = Kind.EPISODE;
        item.epId = json.optLong("epId", 0);
        item.bvid = json.optString("bvid", "");
        item.cid = json.optLong("cid", 0);
        item.aid = json.optLong("aid", 0);
        item.title = json.optString("title", "选集");
        item.pic = json.optString("pic", "");
        item.duration = formatEpisodeDuration(json.optString("duration", ""));
        return item;
    }

    private static String formatEpisodeDuration(String raw) {
        if (raw == null || raw.isEmpty()) return "";
        try {
            long value = Long.parseLong(raw);
            if (value > 10000) {
                long total = value / 1000;
                long hours = total / 3600;
                long minutes = (total % 3600) / 60;
                long seconds = total % 60;
                if (hours > 0) {
                    return String.format(java.util.Locale.CHINA, "%d:%02d:%02d", hours, minutes, seconds);
                }
                return String.format(java.util.Locale.CHINA, "%02d:%02d", minutes, seconds);
            }
        } catch (Throwable ignored) {
        }
        return raw;
    }

    VideoItem toVideo() {
        VideoItem video = new VideoItem();
        video.bvid = bvid;
        video.aid = aid;
        video.cid = cid;
        video.mid = mid;
        video.title = title;
        video.pic = pic;
        video.owner = owner;
        video.duration = duration;
        video.play = play;
        video.playText = playText;
        video.roomId = roomId;
        video.epId = epId;
        video.live = kind == Kind.LIVE;
        video.progressSec = progressSec;
        return video;
    }

    PlayRequest toPlay() {
        PlayRequest request = new PlayRequest();
        request.bvid = bvid;
        request.title = title;
        request.owner = owner;
        request.pic = pic;
        request.duration = duration;
        request.aid = aid;
        request.cid = cid;
        request.mid = mid;
        request.epId = epId;
        request.roomId = roomId;
        request.progressSec = progressSec;
        request.live = kind == Kind.LIVE;
        request.pgc = kind == Kind.EPISODE;
        return request;
    }
}
