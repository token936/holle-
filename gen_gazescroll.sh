#!/usr/bin/env bash
set -euo pipefail

ROOT="GazeScroll"
JAVA="$ROOT/app/src/main/java/com/example/gazescroll"
RES="$ROOT/app/src/main/res"
ASSETS="$ROOT/app/src/main/assets"

mkdir -p "$JAVA" "$RES/layout" "$RES/values" "$RES/xml" "$ASSETS"

cat > "$ROOT/settings.gradle" <<'EOF'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral() } }
rootProject.name = "GazeScroll"
include ':app'
EOF

cat > "$ROOT/build.gradle" <<'EOF'
plugins {
    id 'com.android.application' version '8.4.2' apply false
    id 'org.jetbrains.kotlin.android' version '1.9.24' apply false
}
EOF

cat > "$ROOT/gradle.properties" <<'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
EOF

cat > "$ROOT/app/build.gradle" <<'EOF'
plugins { id 'com.android.application'; id 'org.jetbrains.kotlin.android' }
android {
    namespace "com.example.gazescroll"
    compileSdk 35
    defaultConfig { applicationId "com.example.gazescroll"; minSdk 26; targetSdk 35; versionCode 1; versionName "1.0" }
    compileOptions { sourceCompatibility JavaVersion.VERSION_1_8; targetCompatibility JavaVersion.VERSION_1_8 }
    kotlinOptions { jvmTarget = '1.8' }
}
dependencies {
    implementation 'androidx.core:core-ktx:1.13.1'
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'com.google.android.material:material:1.12.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.google.mediapipe:tasks-vision:0.10.21'
    implementation 'androidx.lifecycle:lifecycle-service:2.8.5'
    implementation "androidx.lifecycle:lifecycle-runtime-ktx:2.8.5"
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1'
    implementation "androidx.camera:camera-core:1.4.0"
    implementation "androidx.camera:camera-camera2:1.4.0"
    implementation "androidx.camera:camera-lifecycle:1.4.0"
}
EOF

cat > "$ROOT/app/src/main/AndroidManifest.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA" />
    <application android:label="GazeScroll" android:theme="@style/Theme.AppCompat.DayNight.NoActionBar">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter>
        </activity>
        <activity android:name=".CalibrationActivity" android:exported="false" android:screenOrientation="portrait" />
        <service android:name=".GazeScrollService" android:foregroundServiceType="camera" />
        <service android:name=".ScrollAccessibilityService" android:exported="true" android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter><action android:name="android.accessibilityservice.AccessibilityService" /></intent-filter>
            <meta-data android:name="android.accessibilityservice" android:resource="@xml/accessibility_service_config" />
        </service>
    </application>
</manifest>
EOF

cat > "$RES/values/strings.xml" <<'EOF'
<resources><string name="app_name">GazeScroll</string></resources>
EOF

cat > "$RES/xml/accessibility_service_config.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeAllMask"
    android:canPerformGestures="true"
    android:canRetrieveWindowContent="true"
    android:description="@string/app_name" />
EOF

cat > "$RES/layout/activity_main.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="24dp">
    <Button android:id="@+id/btn_calibrate"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Calibrate" />
    <Button android:id="@+id/btn_start"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Start Service" />
    <Button android:id="@+id/btn_hud_perm"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="HUD Permission" />
    <Button android:id="@+id/btn_acc"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Accessibility Settings" />
</LinearLayout>
EOF

cat > "$RES/layout/activity_calibration.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical">
    <TextView android:id="@+id/tv_tip"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="22sp" />
</LinearLayout>
EOF

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
    private val permLauncher = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { result ->
        if (result[Manifest.permission.CAMERA] == true) ContextCompat.startForegroundService(this, Intent(this, GazeScrollService::class.java))
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        findViewById<Button>(R.id.btn_calibrate).setOnClickListener { startActivity(Intent(this, CalibrationActivity::class.java)) }
        findViewById<Button>(R.id.btn_start).setOnClickListener {
            val need = mutableListOf(Manifest.permission.CAMERA)
            if (Build.VERSION.SDK_INT >= 33) need.add(Manifest.permission.POST_NOTIFICATIONS)
            val missing = need.filter { ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED }
            if (missing.isNotEmpty()) permLauncher.launch(missing.toTypedArray()) else ContextCompat.startForegroundService(this, Intent(this, GazeScrollService::class.java))
        }
        findViewById<Button>(R.id.btn_hud_perm).setOnClickListener { startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))) }
        findViewById<Button>(R.id.btn_acc).setOnClickListener { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }
    }
}
EOF

cat > "$JAVA/GazeSample.kt" <<'EOF'
package com.example.gazescroll
data class GazeSample(val v: Float, val h: Float, val pitch: Float, val valid: Boolean, val ts: Long)
EOF

cat > "$JAVA/GazeConfig.kt" <<'EOF'
package com.example.gazescroll
import android.content.Context
import android.content.SharedPreferences
import kotlin.math.abs

class GazeConfig(context: Context) {
    private val sp = context.getSharedPreferences("cfg", Context.MODE_PRIVATE)
    var vTop get() = sp.getFloat("vTop", 0.3f); set(value) = sp.edit().putFloat("vTop", value).apply()
    var vBottom get() = sp.getFloat("vBottom", 0.7f); set(value) = sp.edit().putFloat("vBottom", value).apply()
    var hLeft get() = sp.getFloat("hLeft", 0.25f); set(value) = sp.edit().putFloat("hLeft", value).apply()
    var hRight get() = sp.getFloat("hRight", 0.75f); set(value) = sp.edit().putFloat("hRight", value).apply()
    var pitchLow get() = sp.getFloat("pitchLow", 0.20f); set(value) = sp.edit().putFloat("pitchLow", value).apply()
    var pitchHigh get() = sp.getFloat("pitchHigh", 0.55f); set(value) = sp.edit().putFloat("pitchHigh", value).apply()
    var smoothing get() = sp.getFloat("smoothing", 0.18f); set(value) = sp.edit().putFloat("smoothing", value).apply()
    var dwellMs get() = sp.getLong("dwellMs", 650L); set(value) = sp.edit().putLong("dwellMs", value).apply()
    var cooldownMs get() = sp.getLong("cooldownMs", 1100L); set(value) = sp.edit().putLong("cooldownMs", value).apply()
    var upT get() = sp.getFloat("upT", 0.20f); set(value) = sp.edit().putFloat("upT", value).apply()
    var downT get() = sp.getFloat("downT", 0.80f); set(value) = sp.edit().putFloat("downT", value).apply()
    var leftT get() = sp.getFloat("leftT", 0.20f); set(value) = sp.edit().putFloat("leftT", value).apply()
    var rightT get() = sp.getFloat("rightT", 0.80f); set(value) = sp.edit().putFloat("rightT", value).apply()
    fun normV(raw: Float): Float { val r = vBottom - vTop; if (abs(r) < 0.0001f) return 0.5f; return ((raw - vTop) / r).coerceIn(0f, 1f) }
    fun normH(raw: Float): Float { val r = hRight - hLeft; if (abs(r) < 0.0001f) return 0.5f; return ((raw - hLeft) / r).coerceIn(0f, 1f) }
    fun normPitch(raw: Float): Float { val r = pitchHigh - pitchLow; if (abs(r) < 0.0001f) return 0.5f; return ((raw - pitchLow) / r).coerceIn(0f, 1f) }
    fun blendV(s: GazeSample): Float = 0.65f * normV(s.v) + 0.35f * normPitch(s.pitch)
}
EOF

cat > "$JAVA/GazeMath.kt" <<'EOF'
package com.example.gazescroll
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

object GazeMath {
    fun estimate(lm: List<NormalizedLandmark>, ts: Long, aspect: Float): GazeSample {
        if (lm.size < 478 || aspect < 1e-4f) return GazeSample(0f, 0f, 0f, false, ts)
        val roll = atan2(lm[263].y() - lm[33].y(), (lm[263].x() - lm[33].x()) * aspect)
        val rv = vert(lm, 159, 145, 468, 33, 133, aspect); val lv = vert(lm, 386, 374, 473, 263, 362, aspect)
        val vs = listOfNotNull(rv, lv); if (vs.isEmpty()) return GazeSample(0f, 0f, 0f, false, ts)
        val rh = horiz(lm, 468, 33, 133, roll, aspect); val lh = horiz(lm, 473, 362, 263, roll, aspect)
        val faceH = lm[152].y() - lm[10].y()
        val eyeMidY = (lm[33].y() + lm[133].y() + lm[362].y() + lm[263].y()) / 4f
        val pitch = if (faceH > 1e-4f) (lm[1].y() - eyeMidY) / faceH else 0f
        val eyeMidX = (lm[33].x() + lm[133].x() + lm[362].x() + lm[263].x()) / 4f
        val faceW = abs(lm[263].x() - lm[33].x())
        val yaw = if (faceW > 1e-4f) (lm[1].x() - eyeMidX) / faceW else 0f
        if (abs(yaw) > 0.22f) return GazeSample(0f, 0f, 0f, false, ts)
        val hs = listOfNotNull(rh, lh)
        return GazeSample(vs.average().toFloat(), if (hs.isEmpty()) 0.5f else hs.average().toFloat(), pitch, true, ts)
    }
    private fun vert(lm: List<NormalizedLandmark>, up: Int, low: Int, iris: Int, outer: Int, inner: Int, aspect: Float): Float? {
        val hgt = lm[low].y() - lm[up].y(); val wid = abs(lm[inner].x() - lm[outer].x()) * aspect
        if (wid < 1e-4f || hgt / wid < 0.12f) return null
        return ((lm[iris].y() - lm[up].y()) / hgt).coerceIn(0f, 1f)
    }
    private fun horiz(lm: List<NormalizedLandmark>, iris: Int, from: Int, to: Int, roll: Float, aspect: Float): Float? {
        val cx = (lm[from].x() + lm[to].x()) / 2f; val cy = (lm[from].y() + lm[to].y()) / 2f
        val c = cos(-roll); val s = sin(-roll)
        fun rx(x: Float, y: Float) = ((x - cx) * aspect) * c - (y - cy) * s
        val xi = rx(lm[iris].x(), lm[iris].y()); val xf = rx(lm[from].x(), lm[from].y()); val xt = rx(lm[to].x(), lm[to].y())
        if (abs(xt - xf) < 1e-4f) return null
        return ((xi - xf) / (xt - xf)).coerceIn(0f, 1f)
    }
}
EOF

cat > "$JAVA/GazeTrigger.kt" <<'EOF'
package com.example.gazescroll
import kotlin.math.min
enum class Action { SCROLL_FORWARD, SCROLL_BACK, SWIPE_LEFT, SWIPE_RIGHT }
class GazeTrigger(private val cfg: GazeConfig) {
    private var smoothV = 0.5f; private var smoothH = 0.5f
    private var upSince = 0L; private var downSince = 0L; private var leftSince = 0L; private var rightSince = 0L
    private var lastFireAt = 0L; private var burst = 0; private var burstLastAt = 0L
    var lastAction: Action? = null; private set
    fun reset() { smoothV = 0.5f; smoothH = 0.5f; upSince = 0L; downSince = 0L; leftSince = 0L; rightSince = 0L; lastFireAt = 0L; lastAction = null; burst = 0; burstLastAt = 0L }
    private fun cool(now: Long): Long { if (now - burstLastAt > 1500) burst = 0; return (cfg.cooldownMs * (1f + 0.4f * min(burst, 3))).toLong() }
    fun onSample(s: GazeSample, now: Long): Action? {
        if (!s.valid) { upSince = 0L; downSince = 0L; leftSince = 0L; rightSince = 0L; return null }
        smoothV += (cfg.blendV(s) - smoothV) * cfg.smoothing; smoothH += (cfg.normH(s.h) - smoothH) * cfg.smoothing
        val upZone = smoothV < cfg.upT; val downZone = smoothV > cfg.downT; val leftZone = smoothH < cfg.leftT; val rightZone = smoothH > cfg.rightT
        upSince = if (upZone) if (upSince == 0L) now else upSince else 0L; downSince = if (downZone) if (downSince == 0L) now else downSince else 0L
        leftSince = if (leftZone) if (leftSince == 0L) now else leftSince else 0L; rightSince = if (rightZone) if (rightSince == 0L) now else rightSince else 0L
        if (now - lastFireAt < cool(now)) return null
        val action = when { downZone && downSince != 0L && now - downSince >= cfg.dwellMs -> Action.SCROLL_FORWARD; upZone && upSince != 0L && now - upSince >= cfg.dwellMs -> Action.SCROLL_BACK; leftZone && leftSince != 0L && now - leftSince >= cfg.dwellMs -> Action.SWIPE_LEFT; rightZone && rightSince != 0L && now - rightSince >= cfg.dwellMs -> Action.SWIPE_RIGHT; else -> null }
        if (action != null) { lastFireAt = now; lastAction = action; burst++; burstLastAt = now; when(action) { Action.SCROLL_FORWARD -> downSince = 0; Action.SCROLL_BACK -> upSince = 0; Action.SWIPE_LEFT -> leftSince = 0; Action.SWIPE_RIGHT -> rightSince = 0 } }
        return action
    }
    fun debugState(): String = "v=%.2f h=%.2f".format(smoothV, smoothH)
}
EOF

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
        val lp = WindowManager.LayoutParams(WindowManager.LayoutParams.WRAP_CONTENT, WindowManager.LayoutParams.WRAP_CONTENT, if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_SYSTEM_OVERLAY, WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE, PixelFormat.TRANSLUCENT).apply { gravity = Gravity.TOP or Gravity.START; x = 30; y = 260 }
        runCatching { wm.addView(view, lp); shown = true }
    }
    fun update(v: Float, h: Float, state: String) { if (!shown) show(); view.setData(v, h, state, cfg.upT, cfg.downT, cfg.leftT, cfg.rightT) }
    fun hide() { if (shown) { runCatching { wm.removeView(view) }; shown = false } }
}
class GazeHudView(context: Context) : View(context) {
    private val bg = Paint().apply { color = 0xCC000000.toInt() }; private val track = Paint().apply { color = 0x33FFFFFF }; private val fill = Paint(); private val mark = Paint().apply { color = 0xFFFF5252.toInt() }
    private val text = Paint().apply { color = 0xFFFFFFFF.toInt(); isAntiAlias = true }
    private var nv = 0.5f; private var nh = 0.5f; private var state = ""; private var vLo = 0.20f; private var vHi = 0.80f; private var hLo = 0.20f; private var hHi = 0.80f
    fun setData(v: Float, h: Float, s: String, upT: Float, downT: Float, leftT: Float, rightT: Float) { nv = v; nh = h; state = s; vLo = upT; vHi = downT; hLo = leftT; hHi = rightT; invalidate() }
    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) { val d = resources.displayMetrics.density; setMeasuredDimension((320 * d).toInt(), (140 * d).toInt()) }
    override fun onDraw(c: Canvas) { val d = resources.displayMetrics.density; text.textSize = 13f * resources.displayMetrics.scaledDensity; c.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), 16f, 16f, bg); val left = 24f * d; val right = width - 24f * d; bar(c, left, right, 26f * d, nv, vHi, vLo); bar(c, left, right, 66f * d, nh, hHi, hLo); c.drawText(state, left, 112f * d, text) }
    private fun bar(c: Canvas, l: Float, r: Float, top: Float, v: Float, hi: Float, lo: Float) { val hgt = 14f * resources.displayMetrics.density; c.drawRect(l, top, r, top + hgt, track); val x = l + (r - l) * v.coerceIn(0f, 1f); fill.color = if (v > hi || v < lo) 0xFF4CAF50.toInt() else 0xFF90A4AE.toInt(); c.drawRect(l, top, x, top + hgt, fill); c.drawRect(l + (r - l) * hi - 2f, top - 4f, l + (r - l) * hi + 2f, top + hgt + 4f, mark); c.drawRect(l + (r - l) * lo - 2f, top - 4f, l + (r - l) * lo + 2f, top + hgt + 4f, mark) }
}
EOF

cat > "$JAVA/GazeScrollService.kt" <<'EOF'
package com.example.gazescroll
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
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
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleService
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors

class GazeScrollService : LifecycleService() {
    private var faceMarker: FaceLandmarker? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var lastAspect = 0.75f
    private lateinit var cfg: GazeConfig
    private lateinit var trigger: GazeTrigger
    private lateinit var hud: GazeHud

    private fun imageProxyToBitmap(proxy: ImageProxy): Bitmap? {
        return try {
            val img = proxy.image ?: return null
            val plane = img.planes[0]
            val buffer: ByteBuffer = plane.buffer
            buffer.order(ByteOrder.LITTLE_ENDIAN)
            val pixelStride = plane.pixelStride
            val rowStride = plane.rowStride
            val rowPadding = rowStride - pixelStride * proxy.width
            val bitmap = Bitmap.createBitmap(proxy.width + rowPadding / pixelStride, proxy.height, Bitmap.Config.ARGB_8888)
            bitmap.copyPixelsFromBuffer(buffer)
            bitmap
        } catch (e: Exception) {
            Log.e("Gaze", "convert image error", e)
            null
        }
    }

    override fun onCreate() {
        super.onCreate()
        cfg = GazeConfig(this); trigger = GazeTrigger(cfg); hud = GazeHud(this, cfg)
        val channel = NotificationChannel("gaze", "Gaze", NotificationManager.IMPORTANCE_LOW)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        val notif = Notification.Builder(this, "gaze").setContentTitle("Running").setSmallIcon(android.R.drawable.ic_menu_camera).build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) startForeground(1, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA) else startForeground(1, notif)
        
        val base = BaseOptions.builder().setModelAssetPath("face_landmarker.task").build()
        val options = FaceLandmarker.FaceLandmarkerOptions.builder().setBaseOptions(base).setRunningMode(RunningMode.LIVE_STREAM).setNumFaces(1)
            .setResultListener { res, _ ->
                val face = res.faceLandmarks().firstOrNull() ?: return@setResultListener
                if (face.size < 478) return@setResultListener
                val now = SystemClock.elapsedRealtime()
                val sample = GazeMath.estimate(face, now, lastAspect)
                val action = trigger.onSample(sample, now)
                if (action != null) ScrollAccessibilityService.fire(action)
                main.post { hud.update(cfg.blendV(sample), cfg.normH(sample.h), "${trigger.lastAction ?: "-"} ${trigger.debugState()}") }
            }.build()
        faceMarker = FaceLandmarker.createFromOptions(this, options)

        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            val provider = future.get(); cameraProvider = provider
            val analysis = ImageAnalysis.Builder().setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST).build()
            analysis.setAnalyzer(executor) { proxy ->
                if (faceMarker == null) { proxy.close(); return@setAnalyzer }
                val bitmap = imageProxyToBitmap(proxy)
                if(bitmap == null) { proxy.close(); return@setAnalyzer }
                try {
                    val m = Matrix().apply { postRotate(proxy.imageInfo.rotationDegrees.toFloat()); postScale(-1f, 1f) }
                    val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, m, true)
                    lastAspect = rotated.width.toFloat() / rotated.height.toFloat()
                    faceMarker?.detectAsync(BitmapImageBuilder(rotated).build(), SystemClock.uptimeMillis())
                } catch (t: Throwable) { Log.e("Gaze", "err", t) } finally { proxy.close() }
            }
            provider.bindToLifecycle(this, CameraSelector.DEFAULT_FRONT_CAMERA, analysis)
        }, ContextCompat.getMainExecutor(this))
    }
    override fun onDestroy() { super.onDestroy(); cameraProvider?.unbindAll(); faceMarker?.close(); executor.shutdown(); hud.hide() }
    override fun onBind(intent: Intent): IBinder? { super.onBind(intent); return null }
}
EOF

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
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch

class ScrollAccessibilityService : AccessibilityService() {
    companion object { private val actionChannel = Channel<Action>(capacity = 4, onBufferOverflow = BufferOverflow.DROP_OLDEST); fun fire(action: Action) { actionChannel.trySend(action) } }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate); private var started = false
    override fun onServiceConnected() {
        super.onServiceConnected(); if (started) return; started = true
        scope.launch {
            for (a in actionChannel) {
                when (a) {
                    Action.SCROLL_FORWARD -> if (!tryNodeScroll(true)) gestureScroll(false)
                    Action.SCROLL_BACK -> if (!tryNodeScroll(false)) gestureScroll(true)
                    Action.SWIPE_LEFT -> gestureHorizontal(false)
                    Action.SWIPE_RIGHT -> gestureHorizontal(true)
                }
            }
        }
    }
    private fun tryNodeScroll(forward: Boolean): Boolean { val root = rootInActiveWindow ?: return false; val action = if (forward) AccessibilityNodeInfo.ACTION_SCROLL_FORWARD else AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD; return findScrollable(root, action, 0) }
    private fun findScrollable(n: AccessibilityNodeInfo?, action: Int, depth: Int): Boolean { if (n == null || depth > 12) return false; if (n.isScrollable && n.supportsAction(action) && n.performAction(action)) return true; for (i in 0 until n.childCount) { if (findScrollable(n.getChild(i), action, depth + 1)) return true }; return false }
    private fun gestureScroll(up: Boolean) { val dm = resources.displayMetrics; val path = Path().apply { moveTo(dm.widthPixels * 0.5f, if (up) dm.heightPixels * 0.75f else dm.heightPixels * 0.25f); lineTo(dm.widthPixels * 0.5f, if (up) dm.heightPixels * 0.25f else dm.heightPixels * 0.75f) }; dispatchGesture(GestureDescription.Builder().addStroke(GestureDescription.StrokeDescription(path, 0, 320)).build(), null, null) }
    private fun gestureHorizontal(right: Boolean) { val dm = resources.displayMetrics; val path = Path().apply { moveTo(if (right) dm.widthPixels * 0.22f else dm.widthPixels * 0.78f, dm.heightPixels * 0.5f); lineTo(if (right) dm.widthPixels * 0.78f else dm.widthPixels * 0.22f, dm.heightPixels * 0.5f) }; dispatchGesture(GestureDescription.Builder().addStroke(GestureDescription.StrokeDescription(path, 0, 300)).build(), null, null) }
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}
EOF

cat > "$JAVA/CalibrationActivity.kt" <<'EOF'
package com.example.gazescroll
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
class CalibrationActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState); setContentView(R.layout.activity_calibration)
        val tv = findViewById<TextView>(R.id.tv_tip); tv.text = "Calibrating..."
        Handler(Looper.getMainLooper()).postDelayed({ finish() }, 2000)
    }
}
EOF

echo "================================================"
echo " DONE "
echo "================================================"
