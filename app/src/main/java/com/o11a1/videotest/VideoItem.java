package com.o11a1.videotest;

import org.json.JSONObject;

final class VideoItem {
    String bvid = "";
    long aid = 0;
    long cid = 0;
    long mid = 0;
    String title = "";
    String pic = "";
    String owner = "UP 主";
    String ownerFace = "";
    String duration = "00:00";
    int durationSec = 0;
    long play = 0;
    String playText = "0";
    long pubdate = 0;
    String desc = "";
    long roomId = 0;
    long epId = 0;
    boolean live = false;
    int progressSec = 0;

    static VideoItem from(JSONObject json) {
        VideoItem item = new VideoItem();
        if (json == null) return item;
        item.bvid = json.optString("bvid", "");
        item.aid = json.optLong("aid", 0);
        item.cid = json.optLong("cid", 0);
        item.mid = json.optLong("mid", 0);
        item.title = json.optString("title", "视频");
        item.pic = https(json.optString("pic", ""));
        item.owner = json.optString("owner", "UP 主");
        item.ownerFace = https(json.optString("ownerFace", ""));
        item.duration = json.optString("duration", "00:00");
        item.durationSec = json.optInt("durationSec", 0);
        item.play = json.optLong("play", 0);
        item.playText = json.optString("playText", String.valueOf(item.play));
        item.pubdate = json.optLong("pubdate", 0);
        item.desc = json.optString("desc", "");
        item.progressSec = json.optInt("progress", 0);
        if (item.title.isEmpty()) item.title = "视频";
        if (item.owner.isEmpty()) item.owner = "UP 主";
        if (item.duration.isEmpty()) item.duration = "00:00";
        return item;
    }

    static String https(String url) {
        if (url == null) return "";
        if (url.startsWith("//")) return "https:" + url;
        return url;
    }
}
