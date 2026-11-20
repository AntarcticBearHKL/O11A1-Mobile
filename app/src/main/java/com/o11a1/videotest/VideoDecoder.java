package com.o11a1.videotest;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.media.MediaCodec;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.util.Log;
import android.view.Surface;

import java.nio.ByteBuffer;

/// Decodes a bundled video track straight into the GL Surface. No audio and
/// no frame readback: this is the smallest path that exercises the same
/// hardware decode contract as a real phone player.
public final class VideoDecoder implements Runnable {
    public interface Listener {
        void onCodec(String name, boolean hardware);
        void onFormat(int width, int height);
        void onError(String message);
    }

    private static final String TAG = "O11A1VideoTest";

    private final Context context;
    private final String assetName;
    private final Surface surface;
    private final Listener listener;

    private volatile boolean running = true;
    private Thread thread;
    private MediaExtractor extractor;
    private MediaCodec codec;

    public VideoDecoder(Context context, String assetName, Surface surface, Listener listener) {
        this.context = context.getApplicationContext();
        this.assetName = assetName;
        this.surface = surface;
        this.listener = listener;
    }

    public void start() {
        thread = new Thread(this, "o11a1-video-decode");
        thread.start();
    }

    public void stop() {
        running = false;
        if (thread != null) {
            thread.interrupt();
            try {
                thread.join(1200);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            }
            thread = null;
        }
        release();
    }

    @Override
    public void run() {
        try {
            extractor = new MediaExtractor();
            try (AssetFileDescriptor afd = context.getAssets().openFd(assetName)) {
                extractor.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            }

            int track = -1;
            MediaFormat format = null;
            for (int i = 0; i < extractor.getTrackCount(); i++) {
                MediaFormat candidate = extractor.getTrackFormat(i);
                String mime = candidate.getString(MediaFormat.KEY_MIME);
                if (mime != null && mime.startsWith("video/")) {
                    track = i;
                    format = candidate;
                    break;
                }
            }
            if (track < 0 || format == null) {
                fail("test movie has no video track");
                return;
            }
            extractor.selectTrack(track);

            String mime = format.getString(MediaFormat.KEY_MIME);
            String decoderName = CodecProbe.bestDecoder(mime);
            codec = decoderName != null
                ? MediaCodec.createByCodecName(decoderName)
                : MediaCodec.createDecoderByType(mime);
            codec.configure(format, surface, null, 0);
            codec.start();

            int width = format.containsKey(MediaFormat.KEY_WIDTH)
                ? format.getInteger(MediaFormat.KEY_WIDTH) : 0;
            int height = format.containsKey(MediaFormat.KEY_HEIGHT)
                ? format.getInteger(MediaFormat.KEY_HEIGHT) : 0;
            boolean hw = CodecProbe.hardware(codec.getName());
            Log.i(TAG, "decoder=" + codec.getName() + " hw=" + hw
                + " " + width + "x" + height + " mime=" + mime);
            listener.onCodec(codec.getName(), hw);
            if (width > 0 && height > 0) listener.onFormat(width, height);

            MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();
            boolean inputDone = false;
            long firstPtsUs = -1;
            long firstFrameNs = 0;
            while (running) {
                if (!inputDone) {
                    int input = codec.dequeueInputBuffer(10_000);
                    if (input >= 0) {
                        ByteBuffer buffer = codec.getInputBuffer(input);
                        int size = buffer == null ? -1 : extractor.readSampleData(buffer, 0);
                        if (size < 0) {
                            codec.queueInputBuffer(input, 0, 0, 0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM);
                            inputDone = true;
                        } else {
                            codec.queueInputBuffer(input, 0, size, extractor.getSampleTime(), 0);
                            extractor.advance();
                        }
                    }
                }

                int output = codec.dequeueOutputBuffer(info, 10_000);
                if (output >= 0) {
                    if (firstPtsUs < 0) {
                        firstPtsUs = info.presentationTimeUs;
                        firstFrameNs = System.nanoTime();
                    }
                    long dueNs = firstFrameNs + (info.presentationTimeUs - firstPtsUs) * 1000L;
                    long waitNs = dueNs - System.nanoTime();
                    if (waitNs > 0) {
                        try {
                            Thread.sleep(waitNs / 1_000_000L);
                        } catch (InterruptedException ignored) {
                            Thread.currentThread().interrupt();
                        }
                    }
                    // `true` hands the buffer to the SurfaceTexture. This is
                    // the zero-copy handoff; the renderer reads it as an
                    // external OES texture.
                    codec.releaseOutputBuffer(output, true);
                    if ((info.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        extractor.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC);
                        codec.flush();
                        inputDone = false;
                        firstPtsUs = -1;
                    }
                } else if (output == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    MediaFormat changed = codec.getOutputFormat();
                    int w = changed.containsKey(MediaFormat.KEY_WIDTH)
                        ? changed.getInteger(MediaFormat.KEY_WIDTH) : width;
                    int h = changed.containsKey(MediaFormat.KEY_HEIGHT)
                        ? changed.getInteger(MediaFormat.KEY_HEIGHT) : height;
                    if (w > 0 && h > 0) listener.onFormat(w, h);
                }
            }
        } catch (Throwable error) {
            if (running) {
                Log.e(TAG, "decode failed", error);
                fail(error.getClass().getSimpleName() + ": " + error.getMessage());
            }
        } finally {
            release();
        }
    }

    private void fail(String message) {
        if (listener != null) listener.onError(message);
    }

    private void release() {
        if (codec != null) {
            try {
                codec.stop();
            } catch (Throwable ignored) {
                // Decoder may already be in an error state.
            }
            try {
                codec.release();
            } catch (Throwable ignored) {
                // Nothing else to release.
            }
            codec = null;
        }
        if (extractor != null) {
            try {
                extractor.release();
            } catch (Throwable ignored) {
                // Nothing else to release.
            }
            extractor = null;
        }
    }
}
