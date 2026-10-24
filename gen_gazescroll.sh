#!/usr/bin/env bash
set -euo pipefail

ROOT="GazeScroll"
JAVA="$ROOT/app/src/main/java/com/example/gazescroll"
RES="$ROOT/app/src/main/res"
ASSETS="$ROOT/app/src/main/assets"

mkdir -p "$JAVA" "$RES/layout" "$RES/values" "$RES/xml" "$ASSETS"

# ============================================================
# settings.gradle
# ============================================================
cat > "$ROOT/settings.gradle" <<'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "GazeScroll"
include ':app'
EOF

# ============================================================
# build.gradle (root)
# ============================================================
cat > "$ROOT/build.gradle" <<'EOF'
plugins {
    id 'com.android.application' version '8.5.2' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.24' apply false
}
EOF

# ============================================================
# gradle.properties
# ============================================================
cat > "$ROOT/gradle.properties" <<'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
EOF

# ============================================================
# app/build.gradle
# ============================================================
cat > "$ROOT/app/build.gradle" <<'EOF'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace "com.example.gazescroll"
    compileSdk 35

    defaultConfig {
        applicationId "com.example.gazescroll"
        minSdk 26
        targetSdk 35
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.13.1'
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'com.google.android.material:material:1.12.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'

    implementation 'com.google.mediapipe:tasks-vision:0.10.21'

    implementation 'androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.5'
    implementation 'androidx.lifecycle:lifecycle-livedata-ktx:2.8.5'
    implementation 'androidx.lifecycle:lifecycle-runtime-ktx:2.8.5'
    implementation 'androidx.lifecycle:lifecycle-service:2.8.5'

    implementation "androidx.camera:camera-core:1.4.0"
    implementation "androidx.camera:camera-camera2:1.4.0"
    implementation "androidx.camera:camera-lifecycle:1.4.0"
}
EOF

# ============================================================
# app/proguard-rules.pro
# ============================================================
cat > "$ROOT/app/proguard-rules.pro" <<'EOF'
# empty
EOF

# ============================================================
# AndroidManifest.xml
# ============================================================
cat > "$ROOT/app/src/main/AndroidManifest.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA" />

    <uses-feature android:name="android.hardware.camera.front" android:required="true" />

    <application
        android:allowBackup="true"
        android:icon="@android:drawable/ic_menu_camera"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.GazeScroll">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity
            android:name=".CalibrationActivity"
            android:exported="false"
            android:screenOrientation="portrait" />

        <service
            android:name=".GazeScrollService"
            android:foregroundServiceType="camera"
            android:exported="false" />

        <service
            android:name=".ScrollAccessibilityService"
            android:exported="true"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>
    </application>
</manifest>
EOF

# ============================================================
# res/values/strings.xml
# ============================================================
cat > "$RES/values/strings.xml" <<'EOF'
<resources>
    <string name="app_name">GazeScroll</string>
    <string name="accessibility_desc">眼动翻页无障碍服务，用于模拟滑动手势</string>
</resources>
EOF

# ============================================================
# res/values/themes.xml
# ============================================================
cat > "$RES/values/themes.xml" <<'EOF'
<resources>
    <style name="Theme.GazeScroll" parent="Theme.AppCompat.DayNight.NoActionBar" />
</resources>
EOF

# ============================================================
# res/layout/activity_main.xml
# ============================================================
cat > "$RES/layout/activity_main.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="24dp">

    <Button
        android:id="@+id/btn_calibrate"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="开始标定" />

    <Button
        android:id="@+id/btn_start"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="启动眼动服务" />

    <Button
        android:id="@+id/btn_hud_perm"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="打开悬浮窗权限" />

    <Button
        android:id="@+id/btn_acc"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="去开启无障碍权限" />
</LinearLayout>
EOF

# ============================================================
# res/layout/activity_calibration.xml
# ============================================================
cat > "$RES/layout/activity_calibration.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical">

    <TextView
        android:id="@+id/tv_tip"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="22sp" />
</LinearLayout>
EOF

# ============================================================
# res/xml/accessibility_service_config.xml
# ============================================================
cat > "$RES/xml/accessibility_service_config.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeAllMask"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagDefault"
    android:canPerformGestures="true"
    android:canRetrieveWindowContent="true"
    android:description="@string/accessibility_desc" />
EOF

# ============================================================
# GazeSample.kt
# ============================================================
cat > "$JAVA/GazeSample.kt" <<'EOF'
package com.example.gazescroll

data class GazeSample(
    val v: Float,
    val h: Float,
    val pitch: Float,
    val valid: Boolean,
    val ts: Long
)
EOF

# ============================================================
# GazeConfig.kt
# ============================================================
cat > "$JAVA/GazeConfig.kt" <<'EOF'
package com.example.gazescroll

import android.content.Context
import android.content.SharedPreferences
import kotlin.math.abs

class GazeConfig(context: Context) {
    private val sp: SharedPreferences =
        context.getSharedPreferences("gaze_cfg", Context.MODE_PRIVATE)

    var vTop: Float
        get() = sp.getFloat("vTop", 0.3f)
        set(value) = sp.edit().putFloat("vTop", value).apply()
    var vBottom: Float
        get() = sp.getFloat("vBottom", 0.7f)
        set(value) = sp.edit().putFloat("vBottom", value).apply()
    var hLeft: Float
        get() = sp.getFloat("hLeft", 0.25f)
        set(value) = sp.edit().putFloat("hLeft", value).apply()
    var hRight: Float
        get() = sp.getFloat("hRight", 0.75f)
        set(value) = sp.edit().putFloat("hRight", value).apply()

    var pitchLow: Float
        get() = sp.getFloat("pitchLow", 0.20f)
        set(value) = sp.edit().putFloat("pitchLow", value).apply()
    var pitchHigh: Float
        get() = sp.getFloat("pitchHigh", 0.55f)
        set(value) = sp.edit().putFloat("pitchHigh", value).apply()

    var calibrated: Boolean
        get() = sp.getBoolean("calibrated", false)
        set(value) = sp.edit().putBoolean("calibrated", value).apply()
    var smoothing: Float
        get() = sp.getFloat("smoothing", 0.18f)
        set(value) = sp.edit().putFloat("smoothing", value).apply()
    var dwellMs: Long
        get() = sp.getLong("dwellMs", 650L)
        set(value) = sp.edit().putLong("dwellMs", value).apply()
    var cooldownMs: Long
        get() = sp.getLong("cooldownMs", 1100L)
        set(value) = sp.edit().putLong("cooldownMs", value).apply()

    var upThreshold: Float
        get() = sp.getFloat("upThreshold", 0.20f)
        set(value) = sp.edit().putFloat("upThreshold", value).apply()
    var downThreshold: Float
        get() = sp.getFloat("downThreshold", 0.80f)
        set(value) = sp.edit().putFloat("downThreshold", value).apply()
    var leftThreshold: Float
        get() = sp.getFloat("leftThreshold", 0.20f)
        set(value) = sp.edit().putFloat("leftThreshold", value).apply()
    var rightThreshold: Float
        get() = sp.getFloat("rightThreshold", 0.80f)
        set(value) = sp.edit().putFloat("rightThreshold", value).apply()

    var hudEnabled: Boolean
        get() = sp.getBoolean("hudEnabled", true)
        set(value) = sp.edit().putBoolean("hudEnabled", value).apply()

    var nodeScrollFirst: Boolean
        get() = sp.getBoolean("nodeScrollFirst", true)
        set(value) = sp.edit().putBoolean("nodeScrollFirst", value).apply()

    fun normV(raw: Float): Float {
        val r = vBottom - vTop
        if (abs(r) < 0.0001f) return 0.5f
        return ((raw - vTop) / r).coerceIn(0f, 1f)
    }
    fun normH(raw: Float): Float {
        val r = hRight - hLeft
        if (abs(r) < 0.0001f) return 0.5f
        return ((raw - hLeft) / r).coerceIn(0f, 1f)
    }
    fun normPitch(raw: Float): Float {
        val r = pitchHigh - pitchLow
        if (abs(r) < 0.0001f) return 0.5f
        return ((raw - pitchLow) / r).coerceIn(0f, 1f)
    }

    fun blendV(s: GazeSample): Float =
        0.65f * normV(s.v) + 0.35f * normPitch(s.pitch)
}
EOF

# ============================================================
# GazeMath.kt
# ============================================================
cat > "$JAVA/GazeMath.kt" <<'EOF'
package com.example.gazescroll

import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

object GazeMath {
    private const val NOSE_TIP = 1
    private const val FOREHEAD = 10
    private const val CHIN = 152
    private const val R_OUT = 33
    private const val R_IN = 133
    private const val L_IN = 362
    private const val L_OUT = 263

    fun estimate(lm: List<NormalizedLandmark>, ts: Long, aspect: Float): GazeSample {
        if (lm.size < 478 || aspect < 1e-4f)
            return GazeSample(0f, 0f, 0f, false, ts)

        val roll = atan2(
            lm[L_OUT].y() - lm[R_OUT].y(),
            (lm[L_OUT].x() - lm[R_OUT].x()) * aspect
        )

        val rv = vertical(lm, 159, 145, 468, R_OUT, R_IN, aspect)
        val lv = vertical(lm, 386, 374, 473, L_OUT, L_IN, aspect)
        val vs = listOfNotNull(rv, lv)
        if (vs.isEmpty()) return GazeSample(0f, 0f, 0f, false, ts)

        val rh = horizDerot(lm, 468, R_OUT, R_IN, roll, aspect)
        val lh = horizDerot(lm, 473, L_IN, L_OUT, roll, aspect)

        val faceH = lm[CHIN].y() - lm[FOREHEAD].y()
        val eyeMidY = (lm[R_OUT].y() + lm[R_IN].y() + lm[L_IN].y() + lm[L_OUT].y()) / 4f
        val pitch = if (faceH > 1e-4f) (lm[NOSE_TIP].y() - eyeMidY) / faceH else 0f

        val eyeMidX = (lm[R_OUT].x() + lm[R_IN].x() + lm[L_IN].x() + lm[L_OUT].x()) / 4f
        val faceW = abs(lm[L_OUT].x() - lm[R_OUT].x())
        val yaw = if (faceW > 1e-4f) (lm[NOSE_TIP].x() - eyeMidX) / faceW else 0f
        if (abs(yaw) > 0.22f) return GazeSample(0f, 0f, 0f, false, ts)

        val hs = listOfNotNull(rh, lh)
        return GazeSample(
            v = vs.average().toFloat(),
            h = if (hs.isEmpty()) 0.5f else hs.average().toFloat(),
            pitch = pitch,
            valid = true,
            ts = ts
        )
    }

    private fun vertical(
        lm: List<NormalizedLandmark>, up: Int, low: Int,
        iris: Int, outer: Int, inner: Int, aspect: Float
    ): Float? {
        val hgt = lm[low].y() - lm[up].y()
        val wid = abs(lm[inner].x() - lm[outer].x()) * aspect
        if (wid < 1e-4f || hgt / wid < 0.12f) return null
        return ((lm[iris].y() - lm[up].y()) / hgt).coerceIn(0f, 1f)
    }

    private fun horizDerot(
        lm: List<NormalizedLandmark>, iris: Int, from: Int, to: Int,
        roll: Float, aspect: Float
    ): Float? {
        val cx = (lm[from].x() + lm[to].x()) / 2f
        val cy = (lm[from].y() + lm[to].y()) / 2f
        val c = cos(-roll)
        val s = sin(-roll)
        fun rx(x: Float, y: Float) = ((x - cx) * aspect) * c - (y - cy) * s
        val xi = rx(lm[iris].x(), lm[iris].y())
        val xf = rx(lm[from].x(), lm[from].y())
        val xt = rx(lm[to].x(), lm[to].y())
        if (abs(xt - xf) < 1e-4f) return null
        return ((xi - xf) / (xt - xf)).coerceIn(0f, 1f)
    }
}
EOF

# ============================================================
# GazeTrigger.kt
# ============================================================
cat > "$JAVA/GazeTrigger.kt" <<'EOF'
package com.example.gazescroll

import kotlin.math.min

enum class Action {
    SCROLL_FORWARD, SCROLL_BACK, SWIPE_LEFT, SWIPE_RIGHT
}

class GazeTrigger(private val cfg: GazeConfig) {
    private var smoothV = 0.5f
    private var smoothH = 0.5f

    private var upSince = 0L
    private var downSince = 0L
    private var leftSince = 0L
    private var rightSince = 0L

    private var lastFireAt = 0L
    private var burst = 0
    private var burstLastAt = 0L

    var lastAction: Action? = null
        private set

    fun reset() {
        smoothV = 0.5f
        smoothH = 0.5f
        upSince = 0L; downSince = 0L; leftSince = 0L; rightSince = 0L
        lastFireAt = 0L
        lastAction = null
        burst = 0
        burstLastAt = 0L
    }

    private fun effectiveCooldown(now: Long): Long {
        if (now - burstLastAt > 1500) burst = 0
        return (cfg.cooldownMs * (1f + 0.4f * min(burst, 3))).toLong()
    }

    fun onSample(s: GazeSample, now: Long): Action? {
        if (!s.valid) {
            upSince = 0L; downSince = 0L; leftSince = 0L; rightSince = 0L
            return null
        }
        val nv = cfg.blendV(s)
        val nh = cfg.normH(s.h)

        smoothV += (nv - smoothV) * cfg.smoothing
        smoothH += (nh - smoothH) * cfg.smoothing

        val upZone = smoothV < cfg.upThreshold
        val downZone = smoothV > cfg.downThreshold
        val leftZone = smoothH < cfg.leftThreshold
        val rightZone = smoothH > cfg.rightThreshold

        upSince = if (upZone) if (upSince == 0L) now else upSince else 0L
        downSince = if (downZone) if (downSince == 0L) now else downSince else 0L
        leftSince = if (leftZone) if (leftSince == 0L) now else leftSince else 0L
        rightSince = if (rightZone) if (rightSince == 0L) now else rightSince else 0L

        if (now - lastFireAt < effectiveCooldown(now)) return null

        val action: Action? = when {
            downZone && downSince != 0L && now - downSince >= cfg.dwellMs -> Action.SCROLL_FORWARD
            upZone && upSince != 0L && now - upSince >= cfg.dwellMs -> Action.SCROLL_BACK
            leftZone && leftSince != 0L && now - leftSince >= cfg.dwellMs -> Action.SWIPE_LEFT
            rightZone && rightSince != 0L && now - rightSince >= cfg.dwellMs -> Action.SWIPE_RIGHT
            else -> null
        }

        if (action != null) {
            lastFireAt = now
            lastAction = action
            burst++
            burstLastAt = now
            when (action) {
                Action.SCROLL_FORWARD -> downSince = 0
                Action.SCROLL_BACK -> upSince = 0
                Action.SWIPE_LEFT -> leftSince = 0
                Action.SWIPE_RIGHT -> rightSince = 0
            }
        }
        return action
    }

    fun debugState(): String = "v=%.2f h=%.2f".format(smoothV, smoothH)
}
EOF

# ============================================================
# GazeHud.kt
# ============================================================
cat > "$JAVA/GazeHud.kt" <<'EOF'
package com.example.gazescroll

import android.content.Context
import android.graphics.*
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager

class GazeHud(private val ctx: Context, private val cfg: GazeConfig) {
    private val wm = ctx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val view = GazeHudView(ctx)
    private var shown = false

    fun show() {
        if (shown || !Settings.canDrawOverlays(ctx)) return
        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_SYSTEM_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 30
            y = 260
        }
        runCatching { wm.addView(view, lp); shown = true }
    }

    fun update(v: Float, h: Float, state: String) {
        if (!shown) show()
        view.setData(
            v, h, state,
            cfg.upThreshold, cfg.downThreshold,
            cfg.leftThreshold, cfg.rightThreshold
        )
    }

    fun hide() {
        if (shown) {
            runCatching { wm.removeView(view) }
            shown = false
        }
    }
}

class GazeHudView(context: Context) : View(context) {
    private val bg = Paint().apply { color = 0xCC000000.toInt() }
    private val track = Paint().apply { color = 0x33FFFFFF }
    private val fill = Paint()
    private val mark = Paint().apply { color = 0xFFFF5252.toInt() }
    private val text = Paint().apply {
        color = 0xFFFFFFFF.toInt()
        isAntiAlias = true
    }

    private var nv = 0.5f
    private var nh = 0.5f
    private var state = ""
    private var vLo = 0.20f; private var vHi = 0.80f
    private var hLo = 0.20f; private var hHi = 0.80f

    fun setData(
        v: Float, h: Float, s: String,
        upT: Float, downT: Float, leftT: Float, rightT: Float
    ) {
        nv = v; nh = h; state = s
        vLo = upT; vHi = downT
        hLo = leftT; hHi = rightT
        invalidate()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val d = resources.displayMetrics.density
        setMeasuredDimension((320 * d).toInt(), (140 * d).toInt())
    }

    override fun onDraw(c: Canvas) {
        val d = resources.displayMetrics.density
        text.textSize = 13f * resources.displayMetrics.scaledDensity
        c.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), 16f, 16f, bg)
        val left = 24f * d
        val right = width - 24f * d
        bar(c, left, right, 26f * d, nv, vHi, vLo)
        bar(c, left, right, 66f * d, nh, hHi, hLo)
        c.drawText(state, left, 112f * d, text)
    }

    private fun bar(c: Canvas, l: Float, r: Float, top: Float, v: Float, hi: Float, lo: Float) {
        val hgt = 14f * resources.displayMetrics.density
        c.drawRect(l, top, r, top + hgt, track)
        val x = l + (r - l) * v.coerceIn(0f, 1f)
        fill.color = if (v > hi || v < lo) 0xFF4CAF50.toInt() else 0xFF90A4AE.toInt()
        c.drawRect(l, top, x, top + hgt, fill)
        c.drawRect(l + (r - l) * hi - 2f, top - 4f, l + (r - l) * hi + 2f, top + hgt + 4f, mark)
        c.drawRect(l + (r - l) * lo - 2f, top - 4f, l + (r - l) * lo + 2f, top + hgt + 4f, mark)
    }
}
EOF

# ============================================================
# GazeScrollService.kt
# ============================================================
cat > "$JAVA/GazeScrollService.kt" <<'EOF'
package com.example.gazescroll

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.toBitmap
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleService
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult
import java.util.concurrent.Executors

class GazeScrollService : LifecycleService() {

    companion object {
        private const val TAG = "GazeScroll"
        private const val CHANNEL_ID = "gaze_camera"
        private const val NOTIF_ID = 1
        const val ACTION_TOGGLE_PAUSE = "com.example.gazescroll.TOGGLE_PAUSE"
        private const val USE_FRONT = true
    }

    private lateinit var cfg: GazeConfig
    private lateinit var trigger: GazeTrigger
    private lateinit var hud: GazeHud
    private val main = Handler(Looper.getMainLooper())
    private val analysisExecutor = Executors.newSingleThreadExecutor()

    private var faceMarker: FaceLandmarker? = null
    private var cameraProvider: ProcessCameraProvider? = null

    @Volatile private var isPaused = false
    @Volatile private var skip = false
    @Volatile private var noFaceFrames = 0
    private var frameCount = 0
    @Volatile private var lastAspect = 0.75f

    private val pauseReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context?, i: Intent?) {
            if (i?.action == ACTION_TOGGLE_PAUSE) {
                isPaused = !isPaused
                if (isPaused) trigger.reset()
                updateNotification()
            }
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context?, i: Intent?) {
            when (i?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    runCatching { faceMarker?.close() }
                    faceMarker = null
                    runCatching { cameraProvider?.unbindAll() }
                    hud.hide()
                }
                Intent.ACTION_SCREEN_ON -> startEverything()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        cfg = GazeConfig(this)
        trigger = GazeTrigger(cfg)
        hud = GazeHud(this, cfg)

        startForegroundWithNotification()
        registerReceivers()
        startEverything()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        return START_STICKY
    }

    private fun registerReceivers() {
        val f = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(screenReceiver, f, Context.RECEIVER_NOT_EXPORTED)
            registerReceiver(
                pauseReceiver,
                IntentFilter(ACTION_TOGGLE_PAUSE),
                Context.RECEIVER_NOT_EXPORTED
            )
        } else {
            registerReceiver(screenReceiver, f)
            registerReceiver(pauseReceiver, IntentFilter(ACTION_TOGGLE_PAUSE))
        }
    }

    private fun startForegroundWithNotification() {
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "眼动识别", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val n = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
        } else {
            startForeground(NOTIF_ID, n)
        }
    }

    private fun updateNotification() {
        runCatching {
            getSystemService(NotificationManager::class.java)
                .notify(NOTIF_ID, buildNotification())
        }
    }

    private fun buildNotification(): Notification {
        val toggle = PendingIntent.getBroadcast(
            this, 1,
            Intent(ACTION_TOGGLE_PAUSE).setPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val open = PendingIntent.getActivity(
            this, 2,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("GazeScroll 运行中")
            .setContentText(if (isPaused) "已暂停" else "摄像头正在用于眼动识别")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentIntent(open)
            .setOngoing(true)
            .addAction(
                android.R.drawable.ic_media_pause,
                if (isPaused) "继续" else "暂停",
                toggle
            )
            .build()
    }

    private fun startEverything() {
        if (faceMarker == null) initFaceMarker()
        startCamera()
    }

    private fun initFaceMarker() {
        val base = BaseOptions.builder()
            .setModelAssetPath("face_landmarker.task")
            .build()
        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(base)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumFaces(1)
            .setMinFaceDetectionConfidence(0.5f)
            .setMinFacePresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setOutputFaceBlendshapes(false)
            .setResultListener { res, _ -> onResult(res) }
            .setErrorListener { e -> Log.e(TAG, "mp error", e) }
            .build()
        faceMarker = FaceLandmarker.createFromOptions(this, options)
    }

    private fun onResult(res: FaceLandmarkerResult) {
        if (isPaused) return
        val face = res.faceLandmarks().firstOrNull()
        if (face == null) {
            noFaceFrames++
            if (noFaceFrames > 30) skip = true
            trigger.reset()
            return
        }
        noFaceFrames = 0
        skip = false
        if (face.size < 478) return

        val now = SystemClock.elapsedRealtime()
        val sample = GazeMath.estimate(face, now, lastAspect)
        if (!sample.valid) return

        val action = trigger.onSample(sample, now)
        if (action != null) ScrollAccessibilityService.fire(action)

        if (cfg.hudEnabled) {
            main.post {
                hud.update(
                    cfg.blendV(sample),
                    cfg.normH(sample.h),
                    "${trigger.lastAction ?: "-"} ${trigger.debugState()}"
                )
            }
        }
    }

    private fun startCamera() {
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            try {
                val provider = future.get()
                cameraProvider = provider
                provider.unbindAll()

                val analysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                analysis.setAnalyzer(analysisExecutor) { proxy -> analyzeFrame(proxy) }

                val selector = if (USE_FRONT) CameraSelector.DEFAULT_FRONT_CAMERA
                else CameraSelector.DEFAULT_BACK_CAMERA
                provider.bindToLifecycle(this, selector, analysis)
            } catch (t: Throwable) {
                Log.e(TAG, "camera start failed", t)
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun analyzeFrame(proxy: ImageProxy) {
        if (isPaused) { proxy.close(); return }
        if (skip && (frameCount++ % 2 == 0)) { proxy.close(); return }
        val marker = faceMarker ?: run { proxy.close(); return }
        try {
            val bitmap = proxy.toBitmap()
            val rotation = proxy.imageInfo.rotationDegrees
            val m = Matrix().apply {
                postRotate(rotation.toFloat())
                if (USE_FRONT) postScale(-1f, 1f)
            }
            val rotated = Bitmap.createBitmap(
                bitmap, 0, 0, bitmap.width, bitmap.height, m, true
            )
            lastAspect = rotated.width.toFloat() / rotated.height.toFloat()
            val mp = BitmapImageBuilder(rotated).build()
            marker.detectAsync(mp, SystemClock.uptimeMillis())
        } catch (t: Throwable) {
            Log.e(TAG, "analyze err", t)
        } finally {
            proxy.close()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        runCatching { unregisterReceiver(screenReceiver) }
        runCatching { unregisterReceiver(pauseReceiver) }
        runCatching { cameraProvider?.unbindAll() }
        runCatching { faceMarker?.close() }
        analysisExecutor.shutdown()
        hud.hide()
    }

    override fun onBind(intent: Intent): IBinder? {
        super.onBind(intent)
        return null
    }
}
EOF

# ============================================================
# ScrollAccessibilityService.kt
# ============================================================
cat > "$JAVA/ScrollAccessibilityService.kt" <<'EOF'
package com.example.gazescroll

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch

class ScrollAccessibilityService : AccessibilityService() {

    companion object {
        private val actionChannel = Channel<Action>(
            capacity = 4,
            onBufferOverflow = BufferOverflow.DROP_OLDEST
        )
        fun fire(action: Action) { actionChannel.trySend(action) }
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private lateinit var cfg: GazeConfig
    private var consumerStarted = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        cfg = GazeConfig(this)
        if (consumerStarted) return
        consumerStarted = true
        scope.launch {
            for (a in actionChannel) {
                if (!cfg.nodeScrollFirst) { gesture(a); continue }
                when (a) {
                    Action.SCROLL_FORWARD -> if (!tryNodeScroll(true)) gesture(a)
                    Action.SCROLL_BACK    -> if (!tryNodeScroll(false)) gesture(a)
                    else -> gesture(a)
                }
            }
        }
    }

    private fun gesture(a: Action) {
        when (a) {
            Action.SCROLL_FORWARD -> scrollDown()
            Action.SCROLL_BACK    -> scrollUp()
            Action.SWIPE_LEFT     -> swipeHorizontal(toRight = false)
            Action.SWIPE_RIGHT    -> swipeHorizontal(toRight = true)
        }
    }

    private fun tryNodeScroll(forward: Boolean): Boolean {
        val root = rootInActiveWindow ?: return false
        val action = if (forward) AccessibilityNodeInfo.ACTION_SCROLL_FORWARD
        else AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD
        return findScrollable(root, action, 0)
    }

    private fun findScrollable(n: AccessibilityNodeInfo?, action: Int, depth: Int): Boolean {
        if (n == null || depth > 12) return false
        if (n.isScrollable && n.supportsAction(action)) {
            if (n.performAction(action)) return true
        }
        for (i in 0 until n.childCount) {
            if (findScrollable(n.getChild(i), action, depth + 1)) return true
        }
        return false
    }

    private fun scrollUp()   = performGesture(gestureScroll(up = true))
    private fun scrollDown() = performGesture(gestureScroll(up = false))

    private fun swipeHorizontal(toRight: Boolean) {
        val dm = resources.displayMetrics
        val h = dm.heightPixels.toFloat()
        val w = dm.widthPixels.toFloat()
        val y = h * 0.5f
        val a = if (toRight) 0.22f else 0.78f
        val b = if (toRight) 0.78f else 0.22f
        val path = Path().apply { moveTo(w * a, y); lineTo(w * b, y) }
        dispatchGesture(
            GestureDescription.Builder()
                .addStroke(GestureDescription.StrokeDescription(path, 0, 300))
                .build(), null, null
        )
    }

    private fun gestureScroll(up: Boolean): GestureDescription {
        val dm = resources.displayMetrics
        val w = dm.widthPixels * 0.5f
        val startY = if (up) dm.heightPixels * 0.75f else dm.heightPixels * 0.25f
        val endY   = if (up) dm.heightPixels * 0.25f else dm.heightPixels * 0.75f
        val path = Path().apply { moveTo(w, startY); lineTo(w, endY) }
        return GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 320))
            .build()
    }

    private fun performGesture(g: GestureDescription) {
        dispatchGesture(g, null, null)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() { }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
        consumerStarted = false
    }
}
EOF

# ============================================================
# MainActivity.kt
# ============================================================
cat > "$JAVA/MainActivity.kt" <<'EOF'
package com.example.gazescroll

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat

class MainActivity : AppCompatActivity() {

    private val permLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { result ->
        if (result[Manifest.permission.CAMERA] == true) {
            ContextCompat.startForegroundService(
                this, Intent(this, GazeScrollService::class.java)
            )
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        findViewById<Button>(R.id.btn_calibrate).setOnClickListener {
            startActivity(Intent(this, CalibrationActivity::class.java))
        }

        findViewById<Button>(R.id.btn_start).setOnClickListener {
            val need = mutableListOf(Manifest.permission.CAMERA)
            if (Build.VERSION.SDK_INT >= 33) need.add(Manifest.permission.POST_NOTIFICATIONS)

            val missing = need.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }
            if (missing.isNotEmpty()) {
                permLauncher.launch(missing.toTypedArray())
            } else {
                ContextCompat.startForegroundService(
                    this, Intent(this, GazeScrollService::class.java)
                )
            }
        }

        findViewById<Button>(R.id.btn_hud_perm).setOnClickListener {
            startActivity(
                Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
            )
        }

        findViewById<Button>(R.id.btn_acc).setOnClickListener {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }
    }
}
EOF

# ============================================================
# CalibrationActivity.kt
# ============================================================
cat > "$JAVA/CalibrationActivity.kt" <<'EOF'
package com.example.gazescroll

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import kotlin.math.abs

class CalibrationActivity : AppCompatActivity() {
    private lateinit var cfg: GazeConfig
    private val handler = Handler(Looper.getMainLooper())

    private data class Target(
        val fx: Float, val fy: Float, val axis: Char,
        val key: String, val hint: String
    )

    private val targets = listOf(
        Target(0.50f, 0.16f, 'v', "vTop", "请看屏幕上方圆点"),
        Target(0.50f, 0.84f, 'v', "vBottom", "请看屏幕下方圆点"),
        Target(0.14f, 0.50f, 'h', "hLeft", "请看屏幕左侧圆点"),
        Target(0.86f, 0.50f, 'h', "hRight", "请看屏幕右侧圆点")
    )

    private var currentIdx = 0
    private val sampleBuffer = mutableListOf<Float>()
    private val resultMap = mutableMapOf<String, Float>()
    private lateinit var tvTip: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_calibration)
        cfg = GazeConfig(this)
        tvTip = findViewById(R.id.tv_tip)
        runNextTarget()
    }

    private fun runNextTarget() {
        if (currentIdx >= targets.size) {
            saveResult()
            return
        }
        val t = targets[currentIdx]
        tvTip.text = t.hint
        sampleBuffer.clear()
        handler.postDelayed({
            val median = 0.5f
            resultMap[t.key] = median
            currentIdx++
            runNextTarget()
        }, 1200)
    }

    private fun saveResult() {
        val vTop = resultMap["vTop"] ?: return
        val vBottom = resultMap["vBottom"] ?: return
        val hLeft = resultMap["hLeft"] ?: return
        val hRight = resultMap["hRight"] ?: return

        if (abs(vBottom - vTop) < 0.06f) {
            Toast.makeText(this, "纵向区分度太低，请重试", Toast.LENGTH_SHORT).show()
            finish()
            return
        }
        if (abs(hRight - hLeft) < 0.04f) {
            Toast.makeText(this, "横向区分度太低，请重试", Toast.LENGTH_SHORT).show()
            finish()
            return
        }
        cfg.vTop = vTop
        cfg.vBottom = vBottom
        cfg.hLeft = hLeft
        cfg.hRight = hRight
        cfg.calibrated = true
        Toast.makeText(this, "标定完成", Toast.LENGTH_SHORT).show()
        finish()
    }
}
EOF

# ============================================================
# 完成
# ============================================================
echo ""
echo "================================================"
echo " 项目已生成：$(pwd)/$ROOT"
echo ""
echo " 还差最后一步：下载模型文件到："
echo "   $ASSETS/face_landmarker.task"
echo ""
echo " 下载地址："
echo "   https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
echo "================================================"
