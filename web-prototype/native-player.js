/*
 * Native media shim.
 *
 * The page keeps its existing <video> driven state machine, but decode and
 * network IO are handled by ExoPlayer (Android) / AVPlayer (iOS).  Each shimmed
 * element is only a layout anchor; its pixels are drawn by a native surface
 * placed underneath the WebView.  No localhost proxy is involved.
 */
(function () {
  'use strict';

  const bridge = window.O11A1Native;
  const root = window.O11A1NativePlayer;
  const canNative = Boolean(bridge
    && typeof bridge.nativePlayerLoad === 'function'
    && typeof bridge.nativePlayerRect === 'function'
    && typeof bridge.nativePlayerControl === 'function'
    && typeof bridge.nativePlayerRelease === 'function');
  if (!canNative) return;

  const IOS = /iPhone|iPad|iPod/i.test(navigator.userAgent);
  const bySlot = new Map();
  const previewSlots = ['preview', 'preload', 'preview3'];
  const previewSlotUsed = new Set();
  const attached = new Set();
  let raf = 0;
  let dpr = window.devicePixelRatio || 1;
  let lastFrameAt = 0;
  let slotSeq = 0;

  document.documentElement.classList.add('native-media');
  if (document.body) document.body.classList.add('native-media');

  function now() {
    return window.performance && performance.now ? performance.now() : Date.now();
  }

  function evalBridge(name, args) {
    try {
      const fn = bridge[name];
      if (typeof fn !== 'function') return null;
      const raw = fn.apply(bridge, args);
      return typeof raw === 'string' ? JSON.parse(raw) : raw;
    } catch (_) {
      return null;
    }
  }

  function acquirePreviewSlot() {
    for (const slot of previewSlots) {
      if (!previewSlotUsed.has(slot)) {
        previewSlotUsed.add(slot);
        return slot;
      }
    }
    const extra = 'preview-' + (++slotSeq);
    previewSlotUsed.add(extra);
    return extra;
  }

  function releaseSlot(slot) {
    previewSlotUsed.delete(slot);
  }

  function thumbFor(rec) {
    const thumb = rec.el.closest && rec.el.closest('.row-thumb');
    return thumb || null;
  }

  function markThumb(rec) {
    const thumb = thumbFor(rec);
    if (!thumb) return;
    if (rec.el.classList.contains('preview-preload')) return;
    thumb.classList.add('native-preview-active');
    rec.thumb = thumb;
  }

  function clearThumb(rec) {
    if (rec.thumb) rec.thumb.classList.remove('native-preview-active');
    const thumb = thumbFor(rec);
    if (thumb) thumb.classList.remove('native-preview-active');
    rec.thumb = null;
  }

  function bodyReady(ready) {
    const value = Boolean(ready);
    document.documentElement.classList.toggle('native-player-ready', value);
    if (document.body.classList.contains('native-player-ready') === value) return;
    document.body.classList.toggle('native-player-ready', value);
  }

  function dispatch(rec, type, detail) {
    try {
      const event = detail && typeof CustomEvent === 'function'
        ? new CustomEvent(type, { detail })
        : new Event(type);
      rec.el.dispatchEvent(event);
    } catch (_) {
      try { rec.el.dispatchEvent(new Event(type)); } catch (_) {}
    }
  }

  function updateFromPayload(rec, data) {
    if (!data) return;
    const seq = Number(data.seq || 0);
    if (seq && rec.seq && seq !== rec.seq) return false;
    if (data.position != null) rec.position = Math.max(0, Number(data.position) || 0);
    if (data.duration != null) {
      const duration = Number(data.duration) || 0;
      if (duration > 0) rec.duration = duration;
    }
    if (data.buffered != null) rec.buffered = Math.max(0, Number(data.buffered) || 0);
    if (data.videoWidth != null) rec.width = Number(data.videoWidth) || 0;
    if (data.videoHeight != null) rec.height = Number(data.videoHeight) || 0;
    if (data.playing != null) rec.paused = !data.playing;
    return true;
  }

  function onEvent(slot, type, json) {
    const rec = bySlot.get(slot);
    if (!rec) return;
    let data = json;
    try {
      if (typeof data === 'string') data = JSON.parse(data);
    } catch (_) {
      data = null;
    }
    if (!updateFromPayload(rec, data)) return;

    if (type === 'loadstart') {
      rec.readyState = 1;
      rec.gotFirstFrame = false;
      rec.ended = false;
      clearThumb(rec);
      if (rec.slot === 'main') bodyReady(false);
      dispatch(rec, 'loadstart');
      return;
    }
    if (type === 'loadedmetadata') {
      rec.readyState = 3;
      rec.paused = rec.paused !== false;
      dispatch(rec, 'loadedmetadata');
      dispatch(rec, 'durationchange');
      return;
    }
    if (type === 'firstframe') {
      rec.gotFirstFrame = true;
      rec.readyState = 4;
      rec.paused = false;
      markThumb(rec);
      if (rec.el.closest && rec.el.closest('#playerVideo') && playerOpen()) bodyReady(true);
      dispatch(rec, 'nativefirstframe');
      dispatch(rec, 'canplay');
      return;
    }
    if (type === 'canplay') {
      rec.readyState = Math.max(rec.readyState, 3);
      dispatch(rec, 'canplay');
      return;
    }
    if (type === 'playing') {
      rec.paused = false;
      rec.ended = false;
      rec.readyState = 4;
      if (rec.el.closest && rec.el.closest('#playerVideo') && rec.gotFirstFrame && playerOpen()) {
        bodyReady(true);
      }
      dispatch(rec, 'play');
      dispatch(rec, 'playing');
      return;
    }
    if (type === 'pause') {
      rec.paused = true;
      dispatch(rec, 'pause');
      return;
    }
    if (type === 'ended') {
      rec.paused = true;
      rec.ended = true;
      dispatch(rec, 'ended');
      return;
    }
    if (type === 'error') {
      rec.error = { code: 4, message: String((data && data.error) || 'media error') };
      rec.paused = true;
      clearThumb(rec);
      if (rec.slot === 'main') bodyReady(false);
      dispatch(rec, 'error');
      return;
    }
    if (type === 'timeupdate' || type === 'progress') {
      rec.readyState = Math.max(rec.readyState, 3);
      if (type === 'timeupdate') {
        dispatch(rec, 'timeupdate');
        dispatch(rec, 'progress');
      } else {
        dispatch(rec, 'progress');
      }
      return;
    }
    if (type === 'seeking') {
      dispatch(rec, 'seeking');
      return;
    }
    if (type === 'ratechange' || type === 'volumechange' || type === 'resize') {
      dispatch(rec, type);
    }
  }

  function playerOpen() {
    const player = document.getElementById('player');
    return Boolean(player && player.classList.contains('open'));
  }

  function rectVisible(rect) {
    return rect.width > 2 && rect.height > 2
      && rect.bottom > 0 && rect.right > 0
      && rect.top < (window.innerHeight || 1)
      && rect.left < (window.innerWidth || 1);
  }

  function tick() {
    raf = 0;
    dpr = window.devicePixelRatio || 1;
    const at = now();
    let ready = false;
    let delay = 40;
    for (const rec of attached) {
      if (!rec.active) continue;
      const el = rec.el;
      if (!el.isConnected) continue;
      const rect = el.getBoundingClientRect();
      const isPreload = el.classList.contains('preview-preload');
      const inPlayer = Boolean(el.closest && el.closest('#playerVideo'));
      const playerEl = document.getElementById('player');
      const landscape = Boolean(inPlayer && playerEl && playerEl.classList.contains('landscape'));
      let rx = rect.left;
      let ry = rect.top;
      let rw = rect.width;
      let rh = rect.height;
      let rotation = 0;
      if (landscape) {
        const vw = window.innerWidth || 1;
        const vh = window.innerHeight || 1;
        rotation = playerEl.classList.contains('landscape-right') ? 90 : -90;
        rw = vh;
        rh = vw;
        rx = (vw - rw) / 2;
        ry = (vh - rh) / 2;
      }
      const shouldBackground = inPlayer && playerOpen();
      if (shouldBackground !== Boolean(rec.background)) {
        rec.background = shouldBackground;
        if (!IOS) evalBridge('nativePlayerLayer', [rec.slot, shouldBackground]);
      }
      const visible = rectVisible(rect) && !isPreload;
      if (rec.gotFirstFrame && !isPreload) {
        if (inPlayer && playerOpen()) {
          ready = true;
        } else if (thumbFor(rec)) {
          markThumb(rec);
        }
      }
      const minGap = inPlayer ? (IOS ? 32 : 16) : (IOS ? 60 : 40);
      if (visible && at - rec.lastRectAt >= minGap) {
        const scale = IOS ? 1 : dpr;
        const x = rx * scale;
        const y = ry * scale;
        const w = rw * scale;
        const h = rh * scale;
        if (!rec.lastRect || Math.abs(rec.lastRect.x - x) > 0.75
          || Math.abs(rec.lastRect.y - y) > 0.75
          || Math.abs(rec.lastRect.w - w) > 0.75
          || Math.abs(rec.lastRect.h - h) > 0.75
          || rec.lastRotate !== rotation
          || rec.lastVisible !== true) {
          evalBridge('nativePlayerRect', [rec.slot, x, y, w, h, true, rotation]);
          rec.lastRect = { x, y, w, h };
          rec.lastRotate = rotation;
          rec.lastVisible = true;
          rec.lastRectAt = at;
        }
      } else if (!visible && rec.lastVisible !== false) {
        evalBridge('nativePlayerRect', [rec.slot, 0, 0, 0, 0, false, 0]);
        rec.lastVisible = false;
        rec.lastRect = null;
        rec.lastRectAt = at;
      }
      if (inPlayer) delay = IOS ? 32 : 16;
    }
    bodyReady(ready);
    if (attached.size) raf = window.setTimeout(tick, delay);
  }

  function schedule() {
    if (raf) return;
    raf = window.setTimeout(tick, 16);
  }

  function attach(el, slot) {
    if (!el) return null;
    if (el.__o11a1Native) return el.__o11a1Native;
    const rec = {
      el,
      slot: slot || '',
      fixedSlot: slot || '',
      seq: 0,
      active: false,
      src: '',
      kind: 'file',
      audioUrl: '',
      backupUrl: '',
      backupAudioUrl: '',
      startMs: 0,
      loop: false,
      rate: 1,
      volume: 1,
      muted: Boolean(el.muted),
      paused: true,
      ended: false,
      duration: 0,
      position: 0,
      buffered: 0,
      width: 0,
      height: 0,
      readyState: 0,
      error: null,
      gotFirstFrame: false,
      lastRect: null,
      lastVisible: null,
      lastRectAt: 0,
      thumb: null,
    };
    el.__o11a1Native = rec;
    const props = {
      src: {
        get() { return rec.src; },
        set(value) {
          const url = value == null ? '' : String(value);
          rec.src = url;
          if (!url) {
            stop(rec);
            return;
          }
          rec.kind = /\.m3u8(\?|$)/i.test(url) ? 'hls' : 'file';
          load(rec, { videoUrl: url, kind: rec.kind });
        },
      },
      currentSrc: { get() { return rec.src; } },
      currentTime: {
        get() { return rec.position / 1000; },
        set(value) {
          const ms = Math.max(0, Number(value) * 1000 || 0);
          rec.position = ms;
          evalBridge('nativePlayerControl', [rec.slot, 'seek', ms]);
          dispatch(rec, 'seeking');
          setTimeout(() => dispatch(rec, 'seeked'), 90);
        },
      },
      duration: { get() { return rec.duration > 0 ? rec.duration / 1000 : NaN; } },
      paused: { get() { return rec.paused; } },
      ended: { get() { return rec.ended; } },
      readyState: { get() { return rec.readyState; } },
      seeking: { get() { return false; } },
      videoWidth: { get() { return rec.width; } },
      videoHeight: { get() { return rec.height; } },
      error: { get() { return rec.error; } },
      buffered: {
        get() {
          return {
            length: rec.buffered > 0 ? 1 : 0,
            start: () => 0,
            end: () => rec.buffered / 1000,
          };
        },
      },
      seekable: {
        get() {
          return {
            length: rec.duration > 0 ? 1 : 0,
            start: () => 0,
            end: () => rec.duration / 1000,
          };
        },
      },
      volume: {
        get() { return rec.volume; },
        set(value) {
          rec.volume = Math.max(0, Math.min(1, Number(value) || 0));
          evalBridge('nativePlayerControl', [rec.slot, 'volume', rec.volume]);
          dispatch(rec, 'volumechange');
        },
      },
      muted: {
        get() { return rec.muted; },
        set(value) {
          rec.muted = Boolean(value);
          evalBridge('nativePlayerControl', [rec.slot, 'mute', rec.muted ? 1 : 0]);
          dispatch(rec, 'volumechange');
        },
      },
      playbackRate: {
        get() { return rec.rate; },
        set(value) {
          rec.rate = Math.max(0.1, Math.min(4, Number(value) || 1));
          evalBridge('nativePlayerControl', [rec.slot, 'rate', rec.rate]);
          dispatch(rec, 'ratechange');
        },
      },
      loop: {
        get() { return rec.loop; },
        set(value) { rec.loop = Boolean(value); },
      },
    };
    try {
      Object.defineProperties(el, props);
    } catch (_) {}

    el.play = function () {
      if (!rec.src) return Promise.resolve();
      rec.paused = false;
      evalBridge('nativePlayerControl', [rec.slot, 'play', 0]);
      return Promise.resolve();
    };
    el.pause = function () {
      rec.paused = true;
      evalBridge('nativePlayerControl', [rec.slot, 'pause', 0]);
    };
    el.load = function () {
      if (!rec.src) return;
      if (!rec.active) nativeLoad(rec, {});
    };
    el.canPlayType = function (type) {
      if (!type) return '';
      const value = String(type).toLowerCase();
      if (value.indexOf('mpegurl') >= 0) return 'probably';
      if (value.indexOf('mp4') >= 0) return 'probably';
      return '';
    };
    const removeAttribute = el.removeAttribute ? el.removeAttribute.bind(el) : null;
    el.removeAttribute = function (name) {
      if (name === 'src') {
        rec.src = '';
        stop(rec);
        return;
      }
      if (removeAttribute) removeAttribute(name);
    };
    el.__nativeLoad = function (options) {
      load(rec, options || {});
    };
    el.__nativeRelease = function () {
      stop(rec);
    };

    function load(target, options) {
      const videoUrl = String(options.videoUrl || options.url || target.src || '');
      if (!videoUrl) {
        stop(target);
        return;
      }
      if (!target.slot) {
        target.slot = target.fixedSlot || acquirePreviewSlot();
      }
      bySlot.set(target.slot, target);
      attached.add(target);
      const seq = Date.now() * 1000 + (++slotSeq);
      target.seq = seq;
      target.src = String(options.marker || videoUrl);
      target.kind = options.kind || (/\.m3u8(\?|$)/i.test(videoUrl) ? 'hls' : 'file');
      target.audioUrl = options.audioUrl || '';
      target.backupUrl = options.backupUrl || '';
      target.backupAudioUrl = options.backupAudioUrl || '';
      target.startMs = Math.max(0, Number(options.startMs) || 0);
      target.loop = Boolean(options.loop != null ? options.loop : target.loop);
      target.rate = Math.max(0.1, Math.min(4, Number(options.rate) || target.rate || 1));
      target.volume = Math.max(0, Math.min(1, Number(options.volume) || target.volume));
      target.muted = Boolean(options.muted != null ? options.muted : target.muted);
      target.position = target.startMs;
      target.duration = 0;
      target.buffered = 0;
      target.ended = false;
      target.paused = !options.autoplay;
      target.readyState = 1;
      target.error = null;
      target.active = true;
      target.gotFirstFrame = false;
      clearThumb(target);
      if (target.slot === 'main') bodyReady(false);
      evalBridge('nativePlayerLoad', [target.slot, JSON.stringify({
        videoUrl,
        audioUrl: target.audioUrl,
        backupUrl: target.backupUrl,
        backupAudioUrl: target.backupAudioUrl,
        kind: target.kind,
        startMs: target.startMs,
        autoplay: Boolean(options.autoplay),
        loop: target.loop,
        muted: target.muted,
        volume: target.volume,
        rate: target.rate,
        seq,
      })]);
      schedule();
    }

    function nativeLoad(target, options) {
      load(target, options);
    }

    function stop(target) {
      if (!target.active && !target.src) return;
      target.active = false;
      target.src = '';
      target.paused = true;
      target.readyState = 0;
      target.gotFirstFrame = false;
      target.ended = false;
      clearThumb(target);
      if (target.slot === 'main') bodyReady(false);
      evalBridge('nativePlayerRelease', [target.slot]);
      if (target.slot) bySlot.delete(target.slot);
      attached.delete(target);
      if (target.slot !== 'main' && target.slot) {
        releaseSlot(target.slot);
        target.slot = '';
      }
    }

    schedule();
    return rec;
  }

  window.O11A1NativeMedia = {
    available: true,
    attach,
    onEvent,
  };

  const real = document.getElementById('realVideo');
  if (real) attach(real, 'main');

  // Premature presses on the platform fallback should not start an HTML video.
  const player = document.getElementById('player');
  if (player && !player.__nativeMediaWired) {
    player.__nativeMediaWired = true;
  }
})();
