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
    id 'com.android.application' version '8.5.2' apply false
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
        <service android:name=".GazeScrollService" android:foregroundServiceType="camera" />
        <service android:name=".ScrollAccessibilityService" android:exported="true" android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter><action android:name="android.accessibilityservice.AccessibilityService" /></intent-filter>
            <meta-data android:name="android.accessibilityservice" android:resource="@xml/accessibility_service_config" />
        </service>
    </application>
</manifest>
EOF

mkdir -p "$RES/xml" "$RES/layout"
cat > "$RES/xml/accessibility_service_config.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android" android:accessibilityEventTypes="typeAllMask" android:canPerformGestures="true" android:canRetrieveWindowContent="true" android:description="Service" />
EOF

cat > "$RES/layout/activity_main.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:layout_width="match_parent" android:layout_height="match_parent" android:orientation="vertical" android:padding="24dp" android:gravity="center">
    <Button android:id="@+id/btn_start" android:layout_width="match_parent" android:layout_height="wrap_content" android:text="Start" />
</LinearLayout>
EOF

cat > "$JAVA/MainActivity.kt" <<'EOF'
package com.example.gazescroll

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Button
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat

class MainActivity : AppCompatActivity() {
    private val permLauncher = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { result ->
        if (result[Manifest.permission.CAMERA] == true) {
            ContextCompat.startForegroundService(this, Intent(this, GazeScrollService::class.java))
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        findViewById<Button>(R.id.btn_start).setOnClickListener {
            val need = mutableListOf(Manifest.permission.CAMERA)
            if (Build.VERSION.SDK_INT >= 33) need.add(Manifest.permission.POST_NOTIFICATIONS)
            val missing = need.filter { ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED }
            if (missing.isNotEmpty()) permLauncher.launch(missing.toTypedArray()) else ContextCompat.startForegroundService(this, Intent(this, GazeScrollService::class.java))
        }
    }
}
EOF

cat > "$JAVA/GazeScrollService.kt" <<'EOF'
package com.example.gazescroll
import android.app.*
import android.content.Intent
import android.os.IBinder
import androidx.lifecycle.LifecycleService

class GazeScrollService : LifecycleService() {
    override fun onCreate() {
        super.onCreate()
        val channel = NotificationChannel("gaze", "Gaze", NotificationManager.IMPORTANCE_LOW)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        val notif = Notification.Builder(this, "gaze").setContentTitle("Running").setSmallIcon(android.R.drawable.ic_menu_camera).build()
        startForeground(1, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
    }
    override fun onBind(intent: Intent): IBinder? { super.onBind(intent); return null }
}
EOF

cat > "$JAVA/ScrollAccessibilityService.kt" <<'EOF'
package com.example.gazescroll
import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class ScrollAccessibilityService : AccessibilityService() {
    override fun onServiceConnected() { super.onServiceConnected() }
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}
EOF
