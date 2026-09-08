package com.jdbs.iptv.easy_chromecast_plugin

import android.app.Activity
import android.content.Context
import android.view.ContextThemeWrapper
import androidx.annotation.NonNull
import androidx.fragment.app.FragmentActivity
import androidx.mediarouter.app.MediaRouteChooserDialogFragment
import androidx.mediarouter.media.MediaRouteSelector
import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.framework.CastContext
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class EasyChromecastPlugin : FlutterPlugin, ChromecastHostApi, ActivityAware {

    private lateinit var context: Context
    private var activity: Activity? = null // Houd hier de actieve Activity bij
    private var castContext: CastContext? = null

    private val currentSession
        get() = castContext?.sessionManager?.currentCastSession

    // --- 1. Flutter Plugin Lifecycle ---

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        ChromecastHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        ChromecastHostApi.setUp(binding.binaryMessenger, null)
    }

    // --- 2. Activity Lifecycle Management (ActivityAware) ---

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity // Hier vangen we de echte Activity context op
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        this.activity = null
    }

    // --- 3. Implementatie van de API ---

    override fun initializeCast() {
        castContext = try {
            CastContext.getSharedInstance(context)
        } catch (e: Exception) {
            null
        }
    }

    override fun isConnected(): Boolean {
        return currentSession?.isConnected ?: false
    }

    override fun showCastDialog() {
        val castCtx = castContext ?: return
        val currentActivity = activity ?: return

        val selectorBundle = castCtx.mergedSelector?.asBundle()
        val mediaRouteSelector = MediaRouteSelector.fromBundle(selectorBundle)

        (currentActivity as? FragmentActivity)?.let { fragmentActivity ->
            if (mediaRouteSelector != null) {
                // We gebruiken nu weer de standaard, ingebouwde AndroidX klasse!
                val dialog = MediaRouteChooserDialogFragment()
                dialog.routeSelector = mediaRouteSelector

                // Toon de dialoog via de FragmentManager
                dialog.show(fragmentActivity.supportFragmentManager, "CastDialog")
            }
        }
    }

    override fun playMedia(request: CastMediaRequest) {
        val session = currentSession ?: return
        if (!session.isConnected) return

        val videoUrl = request.url

        // 1. Bepaal dynamisch de juiste MIME-type op basis van je IPTV extensie
        val mimeType = when {
            videoUrl.contains(
                ".ts",
                ignoreCase = true
            ) -> "video/mp2t"       // Essentieel voor IPTV streams!
            videoUrl.contains(".mkv", ignoreCase = true) -> "video/x-matroska" // Voor MKV bestanden
            videoUrl.contains(".m3u8", ignoreCase = true) -> "application/x-mpegURL" // Voor HLS
            else -> "video/mp4" // Default fallback
        }

        val movieMetadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE).apply {
            putString(MediaMetadata.KEY_TITLE, request.title)
            putString(MediaMetadata.KEY_SUBTITLE, "IPTV Easy Stream")
        }

        val mediaInfo = MediaInfo.Builder(videoUrl)
            // 2. Gebruik STREAM_TYPE_LIVE voor .ts streams (IPTV) en STREAM_TYPE_BUFFERED voor losse bestanden (.mp4/.mkv)
            .setStreamType(
                if (videoUrl.contains(".ts") || videoUrl.contains(".m3u8")) {
                    MediaInfo.STREAM_TYPE_LIVE
                } else {
                    MediaInfo.STREAM_TYPE_BUFFERED
                }
            )
            .setContentType(mimeType) // Injecteer de dynamische MIME-type
            .setMetadata(movieMetadata)
            .build()

        val loadRequestData = MediaLoadRequestData.Builder()
            .setMediaInfo(mediaInfo)
            .setAutoplay(true)
            .build()

        android.os.Handler(android.os.Looper.getMainLooper()).post {
            session.remoteMediaClient?.load(loadRequestData)
        }
    }

    override fun pauseMedia() {
        // Vraag de remoteMediaClient op van de actieve sessie en trigger pause
        currentSession?.remoteMediaClient?.pause()
    }

    override fun resumeMedia() {
        // Hervat het afspelen op de KPN Box
        currentSession?.remoteMediaClient?.play()
    }

    override fun seekMedia(positionInSeconds: Long) {
        // Converteer seconden naar milliseconden (wat de Cast SDK verwacht)
        val positionInMs = positionInSeconds * 1000

        // Stuur het spoor-commando naar de Chromecast hardware
        currentSession?.remoteMediaClient?.seek(positionInMs)
    }

    override fun stopMedia() {
        currentSession?.remoteMediaClient?.stop()
    }
}

/**
 * Een benoemde, publieke top-level klasse.
 * Dit is de Kotlin-equivalent van een "public static class" in Java.
 * Android kan deze klasse probleemloos hercreëren zonder IllegalStateException.
 */
class FixedMediaRouteChooserDialogFragment : MediaRouteChooserDialogFragment() {

    private var customThemeId: Int = 0

    override fun getContext(): Context? {
        val baseContext = super.getContext() ?: return null

        // Haal het thema ID op uit de arguments bundle als het object hercreëerd wordt
        if (customThemeId == 0) {
            customThemeId = arguments?.getInt(ARG_THEME_ID) ?: 0
        }

        return if (customThemeId != 0) {
            ContextThemeWrapper(baseContext, customThemeId)
        } else {
            baseContext
        }
    }

    // Companion object is de plek in Kotlin voor static functies en constanten
    companion object {
        private const val ARG_THEME_ID = "theme_res_id"

        fun newInstance(themeResId: Int): FixedMediaRouteChooserDialogFragment {
            val fragment = FixedMediaRouteChooserDialogFragment()
            val args = android.os.Bundle().apply {
                putInt(ARG_THEME_ID, themeResId)
            }
            fragment.arguments = args
            return fragment
        }
    }
}
