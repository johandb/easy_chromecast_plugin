# easy_chromecast_plugin

A modern, type-safe, and high-performance Flutter plugin for Google Chromecast. Powered by **Kotlin** and **Pigeon**, this plugin provides a robust bridge to the native Google Play Services Cast Framework on Android.

Perfect for building IPTV apps, video streaming clients, and media players that need seamless casting capabilities.

## Features

- ⚡ **Type-Safe API**: Generated via Google Pigeon, preventing runtime type-casting crashes.
- 📦 **Modern Kotlin Architecture**: Built with Kotlin DSL (`build.gradle.kts`) and lifecycle-aware components.
- 📺 **Wide Format Support**: Optimized for streaming `.mp4`, HLS (`.m3u8`), and `.ts` (MPEG-TS) IPTV streams.
- 🛠️ **DIW7022 (KPN TV+ Box) Compatible**: Hardened against common Android TV contrast/transparency rendering crashes (`#0 translucent background`).

---

## Getting Started

### 1. Android Prerequisites

Because the native Google Cast SDK relies on specific Android Jetpack components and hardware permissions, you need to perform the following configuration steps in your host Android project (`android/`).

#### Change MainActivity to FlutterFragmentActivity
The Chromecast dialog fragments require a `FragmentActivity` context to render properly. Open your `MainActivity.kt` and change its inheritance:

```kotlin
package com.yourcompany.yourapp

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    // Leave this empty
}
```

#### Add Permissions to AndroidManifest.xml
Open your `android/app/src/main/AndroidManifest.xml` and add the following network, local discovery, and Bluetooth permissions (required for Android 12+ device scanning):

```xml
<manifest xmlns:android="http://android.com">
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
    
    <!-- Required for Android 12+ local network discovery -->
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

    <application ...>
        <!-- Configure your application theme to inherit from an opaque AppCompat theme -->
        <!-- This prevents the "background can not be translucent: #0" crash inside the Cast Dialog -->
        <activity
            android:name=".MainActivity"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar"
            ... >
        </activity>
    </application>
</manifest>
```

#### Register the CastOptionsProvider
To prevent the Cast SDK from failing at initialization, add the following `<meta-data>` tag inside the `<application>` block of your host app's `AndroidManifest.xml`:

```xml
<application ...>
    <meta-data
        android:name="com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME"
        android:value="com.jdbs.iptv.easy_chromecast_plugin.CastOptionsProvider" />
</application>
```

---

## Usage

Using the plugin in Dart is completely type-safe and straightforward.

### Initialization & Connection

```dart
import 'package:easy_chromecast_plugin/easy_chromecast_plugin.dart';

final _chromecastPlugin = EasyChromecastPlugin();

@override
void initState() {
  super.initState();
  // Initialize the Google Cast SDK framework early in your app lifecycle
  _chromecastPlugin.initializeCast();
}

// Open the native Google Cast selection dialog to look for nearby devices (e.g. KPN Box)
Future<void> connectToDevice() async {
  await _chromecastPlugin.showCastDialog();
}

// Check if a device is currently connected and an active session is running
Future<void> checkStatus() async {
  bool isConnected = await _chromecastPlugin.isConnected();
  print("Connected to Chromecast: \$isConnected");
}
```

### Streaming Media (VOD & Live IPTV)

The plugin automatically detects the correct streaming type and container based on your input URL. For live IPTV channels (`.ts`), it automatically enforces live network buffering.

```dart
// Stream a regular VOD MP4 movie
void playMovie() {
  _chromecastPlugin.playMedia(
    url: 'https://googleapis.com',
    title: 'Big Buck Bunny Movie',
  );
}

// Stream a Live IPTV channel (.ts stream)
void playLiveChannel() {
  _chromecastPlugin.playMedia(
    url: 'http://your-iptv-provider.com',
    title: 'NPO 1 HD Live',
  );
}

// Stop current stream
void stopCasting() {
  _chromecastPlugin.stopMedia();
}
```

---

## Troubleshooting

### Only the progress bar appears when casting an IPTV `.ts` stream
Standard HTML5 Google Cast receivers on older firmware or specific Android TV boxes do not natively decode rauwe MPEG-TS formats over plain HTTP without explicit server CORS configurations. 
- **Fix**: Try changing the IPTV URL output parameter from `output=ts` to `output=m3u8` or `output=mp4` within your IPTV provider dashboard, or use a custom web receiver.

### The Cast Dialog doesn't open
1. Verify that your phone's **Location Services (GPS)** and **Bluetooth** are turned on.
2. Double-check that your phone and the Chromecast device are connected to the exact same Wi-Fi sub-network (disable AP isolation on your router).

## License
This project is licensed under the MIT License - see the LICENSE file for details.
