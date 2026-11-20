package com.o11a1.videotest;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.hardware.display.DisplayManager;
import android.opengl.GLES11Ext;
import android.opengl.GLES30;
import android.opengl.GLSurfaceView;
import android.util.Log;
import android.view.Display;
import android.view.Surface;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.Locale;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/// MediaCodec -> SurfaceTexture -> GLES3 test renderer.
///
/// The decoder writes straight into the SurfaceTexture (zero copy). Each
/// arrived frame is copied to a normal 2D texture so the renderer owns both
/// `prev` and `curr` and can optionally blend them before the CAS pass.
public final class VideoRenderer implements GLSurfaceView.Renderer,
    SurfaceTexture.OnFrameAvailableListener, VideoDecoder.Listener {

    public interface StatsListener {
        void onStats(String text);
    }

    private static final String TAG = "O11A1VideoTest";

    private static final String VERTEX_SHADER =
        "#version 300 es\n" +
        "layout(location = 0) in vec2 aPos;\n" +
        "layout(location = 1) in vec2 aTex;\n" +
        "uniform mat4 uTexMatrix;\n" +
        "out vec2 vTex;\n" +
        "void main() {\n" +
        "  gl_Position = vec4(aPos, 0.0, 1.0);\n" +
        "  vTex = (uTexMatrix * vec4(aTex, 0.0, 1.0)).xy;\n" +
        "}\n";

    private static final String EXTERNAL_COPY_SHADER =
        "#version 300 es\n" +
        "#extension GL_OES_EGL_image_external_essl3 : require\n" +
        "precision mediump float;\n" +
        "uniform samplerExternalOES uTex;\n" +
        "in vec2 vTex;\n" +
        "out vec4 fragColor;\n" +
        "void main() { fragColor = texture(uTex, vTex); }\n";

    private static final String COPY_2D_SHADER =
        "#version 300 es\n" +
        "precision mediump float;\n" +
        "uniform sampler2D uTex;\n" +
        "in vec2 vTex;\n" +
        "out vec4 fragColor;\n" +
        "void main() { fragColor = texture(uTex, vTex); }\n";

    private static final String BLEND_SHADER =
        "#version 300 es\n" +
        "precision mediump float;\n" +
        "uniform sampler2D uPrev;\n" +
        "uniform sampler2D uCurr;\n" +
        "uniform float uWeight;\n" +
        "in vec2 vTex;\n" +
        "out vec4 fragColor;\n" +
        "void main() {\n" +
        "  fragColor = mix(texture(uPrev, vTex), texture(uCurr, vTex), uWeight);\n" +
        "}\n";

    // A compact CAS-like adaptive sharpen. The neighborhood is the four
    // axial taps; the local min/max drives the amount so flat areas stay
    // clean and edges get a controlled boost. It is deliberately one pass.
    private static final String CAS_SHADER =
        "#version 300 es\n" +
        "precision highp float;\n" +
        "uniform sampler2D uTex;\n" +
        "uniform vec2 uTexel;\n" +
        "uniform float uStrength;\n" +
        "in vec2 vTex;\n" +
        "out vec4 fragColor;\n" +
        "void main() {\n" +
        "  vec3 c = texture(uTex, vTex).rgb;\n" +
        "  vec3 n = texture(uTex, vTex + vec2(0.0, -uTexel.y)).rgb;\n" +
        "  vec3 s = texture(uTex, vTex + vec2(0.0,  uTexel.y)).rgb;\n" +
        "  vec3 e = texture(uTex, vTex + vec2( uTexel.x, 0.0)).rgb;\n" +
        "  vec3 w = texture(uTex, vTex + vec2(-uTexel.x, 0.0)).rgb;\n" +
        "  vec3 mn = min(min(n, s), min(e, w));\n" +
        "  vec3 mx = max(max(n, s), max(e, w));\n" +
        "  vec3 amp = clamp(min(mn, vec3(1.0) - mx) / max(mx, vec3(0.0001)), 0.0, 1.0);\n" +
        "  vec3 blur = (n + s + e + w) * 0.25;\n" +
        "  vec3 sharp = c + (c - blur) * (0.55 + amp * uStrength);\n" +
        "  fragColor = vec4(clamp(sharp, 0.0, 1.0), 1.0);\n" +
        "}\n";

    private final Context context;
    private final String assetName;
    private final StatsListener statsListener;

    private volatile int videoW;
    private volatile int videoH;
    private volatile int pendingW;
    private volatile int pendingH;

    private volatile boolean interpolation = true;
    private volatile boolean enhance = true;
    private volatile boolean frameAvailable;
    private volatile String codecName = "waiting for decoder...";
    private volatile boolean codecHardware;
    private volatile String decoderError = "";

    private SurfaceTexture surfaceTexture;
    private Surface decodeSurface;
    private VideoDecoder decoder;

    private int externalTexture;
    private final int[] frameTextures = new int[2];
    private final int[] frameFbos = new int[2];
    private int blendTexture;
    private int blendFbo;
    private int frameWrite;
    private int currentFrame = -1;
    private int previousFrame = -1;

    private int copyExternalProgram;
    private int copy2dProgram;
    private int blendProgram;
    private int casProgram;

    private int quadVbo;
    private final float[] texMatrix = new float[16];

    private int viewWidth;
    private int viewHeight;

    private long statsAt;
    private int statsFrames;
    private int statsDecoded;
    private int framesDecoded;
    private int framesDrawn;
    private boolean blendHalf;

    public VideoRenderer(Context context, String assetName, int videoW, int videoH,
                         StatsListener statsListener) {
        this.context = context.getApplicationContext();
        this.assetName = assetName;
        this.videoW = Math.max(2, videoW);
        this.videoH = Math.max(2, videoH);
        this.pendingW = this.videoW;
        this.pendingH = this.videoH;
        this.statsListener = statsListener;
        this.statsAt = System.currentTimeMillis();
    }

    public void setInterpolation(boolean enabled) {
        interpolation = enabled;
    }

    public void setEnhance(boolean enabled) {
        enhance = enabled;
    }

    @Override
    public void onSurfaceCreated(GL10 unused, EGLConfig config) {
        GLES30.glClearColor(0f, 0f, 0f, 1f);
        copyExternalProgram = program(VERTEX_SHADER, EXTERNAL_COPY_SHADER, "external copy");
        copy2dProgram = program(VERTEX_SHADER, COPY_2D_SHADER, "2d copy");
        blendProgram = program(VERTEX_SHADER, BLEND_SHADER, "blend");
        casProgram = program(VERTEX_SHADER, CAS_SHADER, "cas");
        if (copyExternalProgram == 0 || copy2dProgram == 0
            || blendProgram == 0 || casProgram == 0) {
            decoderError = "shader compile failed (see logcat)";
            return;
        }

        createQuad();
        createExternalTexture();
        ensureFrameTargets(videoW, videoH);

        if (decoder != null) decoder.stop();
        decoder = new VideoDecoder(context, assetName, decodeSurface, this);
        decoder.start();
        statsAt = System.currentTimeMillis();
        statsFrames = framesDrawn;
    }

    private void createExternalTexture() {
        int[] textures = new int[1];
        GLES30.glGenTextures(1, textures, 0);
        externalTexture = textures[0];
        GLES30.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, externalTexture);
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_LINEAR);
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_LINEAR);
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES30.GL_TEXTURE_WRAP_S, GLES30.GL_CLAMP_TO_EDGE);
        GLES30.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES30.GL_TEXTURE_WRAP_T, GLES30.GL_CLAMP_TO_EDGE);

        surfaceTexture = new SurfaceTexture(externalTexture);
        surfaceTexture.setDefaultBufferSize(videoW, videoH);
        surfaceTexture.setOnFrameAvailableListener(this);
        decodeSurface = new Surface(surfaceTexture);
    }

    private void ensureFrameTargets(int width, int height) {
        width = Math.max(2, width);
        height = Math.max(2, height);
        if (width == videoW && height == videoH && frameTextures[0] != 0) return;
        videoW = width;
        videoH = height;
        for (int i = 0; i < 2; i++) {
            if (frameTextures[i] != 0) GLES30.glDeleteTextures(1, frameTextures, i);
            if (frameFbos[i] != 0) GLES30.glDeleteFramebuffers(1, frameFbos, i);
            frameTextures[i] = 0;
            frameFbos[i] = 0;
        }
        if (blendTexture != 0) GLES30.glDeleteTextures(1, new int[] {blendTexture}, 0);
        if (blendFbo != 0) GLES30.glDeleteFramebuffers(1, new int[] {blendFbo}, 0);
        blendTexture = 0;
        blendFbo = 0;

        for (int i = 0; i < 2; i++) {
            int[] t = new int[1];
            GLES30.glGenTextures(1, t, 0);
            frameTextures[i] = t[0];
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, frameTextures[i]);
            GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D, 0, GLES30.GL_RGBA8,
                videoW, videoH, 0, GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, null);
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,
                GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_LINEAR);
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,
                GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_LINEAR);
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,
                GLES30.GL_TEXTURE_WRAP_S, GLES30.GL_CLAMP_TO_EDGE);
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,
                GLES30.GL_TEXTURE_WRAP_T, GLES30.GL_CLAMP_TO_EDGE);

            int[] f = new int[1];
            GLES30.glGenFramebuffers(1, f, 0);
            frameFbos[i] = f[0];
            GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, frameFbos[i]);
            GLES30.glFramebufferTexture2D(GLES30.GL_FRAMEBUFFER,
                GLES30.GL_COLOR_ATTACHMENT0, GLES30.GL_TEXTURE_2D,
                frameTextures[i], 0);
        }

        int[] bt = new int[1];
        GLES30.glGenTextures(1, bt, 0);
        blendTexture = bt[0];
        GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, blendTexture);
        GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D, 0, GLES30.GL_RGBA8,
            videoW, videoH, 0, GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, null);
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,
            GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_LINEAR);
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,
            GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_LINEAR);
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,
            GLES30.GL_TEXTURE_WRAP_S, GLES30.GL_CLAMP_TO_EDGE);
        GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,
            GLES30.GL_TEXTURE_WRAP_T, GLES30.GL_CLAMP_TO_EDGE);
        int[] bf = new int[1];
        GLES30.glGenFramebuffers(1, bf, 0);
        blendFbo = bf[0];
        GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, blendFbo);
        GLES30.glFramebufferTexture2D(GLES30.GL_FRAMEBUFFER,
            GLES30.GL_COLOR_ATTACHMENT0, GLES30.GL_TEXTURE_2D, blendTexture, 0);
        GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, 0);
    }

    private void createQuad() {
        float[] data = {
            -1f, -1f, 0f, 0f,
             1f, -1f, 1f, 0f,
            -1f,  1f, 0f, 1f,
             1f,  1f, 1f, 1f
        };
        FloatBuffer buffer = ByteBuffer.allocateDirect(data.length * 4)
            .order(ByteOrder.nativeOrder()).asFloatBuffer();
        buffer.put(data).position(0);
        int[] vbo = new int[1];
        GLES30.glGenBuffers(1, vbo, 0);
        quadVbo = vbo[0];
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, quadVbo);
        GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER, data.length * 4,
            buffer, GLES30.GL_STATIC_DRAW);
    }

    @Override
    public void onSurfaceChanged(GL10 unused, int width, int height) {
        viewWidth = Math.max(1, width);
        viewHeight = Math.max(1, height);
    }

    @Override
    public void onDrawFrame(GL10 unused) {
        if (pendingW != videoW || pendingH != videoH) {
            ensureFrameTargets(pendingW, pendingH);
        }
        if (frameAvailable && surfaceTexture != null && frameTextures[0] != 0) {
            surfaceTexture.updateTexImage();
            surfaceTexture.getTransformMatrix(texMatrix);
            copyExternalFrame();
            frameAvailable = false;
        }
        drawScene();
        framesDrawn++;
        long now = System.currentTimeMillis();
        if (now - statsAt >= 1000) {
            float fps = (framesDrawn - statsFrames) * 1000f / Math.max(1, now - statsAt);
            float decodeFps = (framesDecoded - statsDecoded) * 1000f / Math.max(1, now - statsAt);
            statsAt = now;
            statsFrames = framesDrawn;
            statsDecoded = framesDecoded;
            pushStats(fps, decodeFps);
        }
    }

    private void copyExternalFrame() {
        GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, frameFbos[frameWrite]);
        GLES30.glViewport(0, 0, videoW, videoH);
        GLES30.glDisable(GLES30.GL_BLEND);
        GLES30.glUseProgram(copyExternalProgram);
        GLES30.glActiveTexture(GLES30.GL_TEXTURE0);
        GLES30.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, externalTexture);
        GLES30.glUniform1i(GLES30.glGetUniformLocation(copyExternalProgram, "uTex"), 0);
        GLES30.glUniformMatrix4fv(
            GLES30.glGetUniformLocation(copyExternalProgram, "uTexMatrix"),
            1, false, texMatrix, 0);
        drawQuad();
        GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, 0);

        previousFrame = currentFrame;
        currentFrame = frameWrite;
        frameWrite ^= 1;
        framesDecoded++;
    }

    private void drawScene() {
        GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, 0);
        GLES30.glViewport(0, 0, viewWidth, viewHeight);
        GLES30.glClearColor(0f, 0f, 0f, 1f);
        GLES30.glClear(GLES30.GL_COLOR_BUFFER_BIT);

        if (currentFrame < 0 || viewWidth <= 0 || viewHeight <= 0) return;
        int vw = videoW;
        int vh = videoH;
        float videoAspect = vw / (float) vh;
        float viewAspect = viewWidth / (float) viewHeight;
        int outW;
        int outH;
        if (viewAspect > videoAspect) {
            outH = viewHeight;
            outW = Math.round(outH * videoAspect);
        } else {
            outW = viewWidth;
            outH = Math.round(outW / videoAspect);
        }
        GLES30.glViewport((viewWidth - outW) / 2, (viewHeight - outH) / 2, outW, outH);

        boolean canBlend = interpolation && previousFrame >= 0;
        int source = frameTextures[currentFrame];
        if (canBlend) {
            GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, blendFbo);
            GLES30.glViewport(0, 0, videoW, videoH);
            GLES30.glDisable(GLES30.GL_BLEND);
            GLES30.glUseProgram(blendProgram);
            GLES30.glActiveTexture(GLES30.GL_TEXTURE0);
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, frameTextures[previousFrame]);
            GLES30.glUniform1i(GLES30.glGetUniformLocation(blendProgram, "uPrev"), 0);
            GLES30.glActiveTexture(GLES30.GL_TEXTURE1);
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, frameTextures[currentFrame]);
            GLES30.glUniform1i(GLES30.glGetUniformLocation(blendProgram, "uCurr"), 1);
            GLES30.glUniform1f(GLES30.glGetUniformLocation(blendProgram, "uWeight"),
                blendHalf ? 0.5f : 1.0f);
            blendHalf = !blendHalf;
            drawQuad();
            GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, 0);
            GLES30.glViewport((viewWidth - outW) / 2, (viewHeight - outH) / 2, outW, outH);
            source = blendTexture;
        }

        if (enhance) {
            GLES30.glUseProgram(casProgram);
            GLES30.glActiveTexture(GLES30.GL_TEXTURE0);
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, source);
            GLES30.glUniform1i(GLES30.glGetUniformLocation(casProgram, "uTex"), 0);
            GLES30.glUniform2f(GLES30.glGetUniformLocation(casProgram, "uTexel"),
                1f / videoW, 1f / videoH);
            GLES30.glUniform1f(GLES30.glGetUniformLocation(casProgram, "uStrength"), 0.6f);
        } else {
            GLES30.glUseProgram(copy2dProgram);
            GLES30.glActiveTexture(GLES30.GL_TEXTURE0);
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, source);
            GLES30.glUniform1i(GLES30.glGetUniformLocation(copy2dProgram, "uTex"), 0);
        }
        drawQuad();
    }

    private void drawQuad() {
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, quadVbo);
        GLES30.glEnableVertexAttribArray(0);
        GLES30.glVertexAttribPointer(0, 2, GLES30.GL_FLOAT, false, 16, 0);
        GLES30.glEnableVertexAttribArray(1);
        GLES30.glVertexAttribPointer(1, 2, GLES30.GL_FLOAT, false, 16, 8);
        GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4);
        GLES30.glDisableVertexAttribArray(0);
        GLES30.glDisableVertexAttribArray(1);
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, 0);
    }

    private void pushStats(float fps, float decodeFps) {
        if (statsListener == null) return;
        DisplayManager manager = (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);
        Display display = manager == null ? null : manager.getDisplay(Display.DEFAULT_DISPLAY);
        float hz = display == null ? 0f : display.getRefreshRate();
        String text = String.format(Locale.US,
            "%s  %s\n%d x %d  |  display %.0f Hz\nrender %.1f fps  |  decode %.1f fps  |  blend %s  |  CAS %s%s",
            codecName,
            codecHardware ? "HW" : "SW",
            videoW, videoH, hz, fps, decodeFps,
            interpolation ? "on" : "off",
            enhance ? "on" : "off",
            decoderError.isEmpty() ? "" : "\n" + decoderError);
        statsListener.onStats(text);
    }

    @Override
    public void onFrameAvailable(SurfaceTexture surfaceTexture) {
        frameAvailable = true;
    }

    @Override
    public void onCodec(String name, boolean hardware) {
        codecName = name;
        codecHardware = hardware;
    }

    @Override
    public void onFormat(int width, int height) {
        pendingW = width;
        pendingH = height;
    }

    @Override
    public void onError(String message) {
        decoderError = message;
        Log.e(TAG, "decoder error: " + message);
    }

    public void release() {
        if (decoder != null) {
            decoder.stop();
            decoder = null;
        }
        if (surfaceTexture != null) {
            surfaceTexture.release();
            surfaceTexture = null;
        }
        if (decodeSurface != null) {
            decodeSurface.release();
            decodeSurface = null;
        }
    }

    private static int program(String vertexSource, String fragmentSource, String name) {
        int vertex = shader(GLES30.GL_VERTEX_SHADER, vertexSource, name + " vs");
        int fragment = shader(GLES30.GL_FRAGMENT_SHADER, fragmentSource, name + " fs");
        if (vertex == 0 || fragment == 0) return 0;
        int program = GLES30.glCreateProgram();
        GLES30.glAttachShader(program, vertex);
        GLES30.glAttachShader(program, fragment);
        GLES30.glLinkProgram(program);
        int[] linked = new int[1];
        GLES30.glGetProgramiv(program, GLES30.GL_LINK_STATUS, linked, 0);
        if (linked[0] == 0) {
            Log.e(TAG, "link " + name + ": " + GLES30.glGetProgramInfoLog(program));
            GLES30.glDeleteProgram(program);
            program = 0;
        }
        GLES30.glDeleteShader(vertex);
        GLES30.glDeleteShader(fragment);
        return program;
    }

    private static int shader(int type, String source, String name) {
        int shader = GLES30.glCreateShader(type);
        GLES30.glShaderSource(shader, source);
        GLES30.glCompileShader(shader);
        int[] compiled = new int[1];
        GLES30.glGetShaderiv(shader, GLES30.GL_COMPILE_STATUS, compiled, 0);
        if (compiled[0] == 0) {
            Log.e(TAG, "compile " + name + ": " + GLES30.glGetShaderInfoLog(shader));
            GLES30.glDeleteShader(shader);
            return 0;
        }
        return shader;
    }
}

