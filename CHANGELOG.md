## 1.0.7
* Updated README for web

## 1.0.6
* Add Web support for plugin

## 1.0.5
* Readme fix for Android

## 1.0.4
* Bugfix Android 

## 1.0.3
* Add chromecast support for IOS

## 1.0.2
* Add remote control. Stop, play, forward 

## 1.0.1
* Update example

## 1.0.0

* **Initial Release**: Complete, type-safe Google Chromecast plugin for Flutter using Kotlin and Pigeon.
* **Feature**: Added `initializeCast()` to safely boot the Google Play Services Cast Framework.
* **Feature**: Added `showCastDialog()` using native AndroidX MediaRouter dialogs with full theme-crash protection (`#0 translucent background` fix for Android TV/KPN Box).
* **Feature**: Added `isConnected()` to query live session status from the native layer.
* **Feature**: Added `playMedia()` and `stopMedia()` supporting dynamic MIME-types, tailored for both VOD (`.mp4`, `.mkv`) and Live IPTV (`.ts`, `.m3u8`) streaming.
