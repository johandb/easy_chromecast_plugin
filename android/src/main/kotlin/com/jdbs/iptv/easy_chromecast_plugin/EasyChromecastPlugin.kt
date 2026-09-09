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
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManagerListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class EasyChromecastPlugin : FlutterPlugin, ChromecastHostApi, ActivityAware {

    private lateinit var context: Context
    private var activity: Activity? = null 
    private var castContext: CastContext? = null
    private var flutterApi: ChromecastFlutterApi? = null

    private val currentSession
        get() = castContext?.sessionManager?.currentCastSession

    // --- 1. Flutter Plugin Lifecycle ---

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        // Setup de Pigeon API's met de juiste klassenamen uit je nieuwe pigeon bestand
        ChromecastHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        flutterApi = ChromecastFlutterApi(flutterPluginBinding.binaryMessenger)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        ChromecastHostApi.setUp(binding.binaryMessenger, null)
        castContext?.sessionManager?.removeSessionManagerListener(castSessionListener, CastSession::class.java)
        flutterApi = null
    }

    // --- 2. Activity Lifecycle Management (ActivityAware) ---

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity 
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

    // --- 3. Implementatie van de ChromecastHostApi ---

    override fun initializeCast() {
        // Zorg dat de initialisatie en listener registratie veilig gebeurt
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            try {
                castContext = CastContext.getSharedInstance(context)
                castContext?.sessionManager?.addSessionManagerListener(castSessionListener, CastSession::class.java)
            } catch (e: Exception) {
                castContext = null
            }
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
                val dialog = MediaRouteChooserDialogFragment()
                dialog.routeSelector = mediaRouteSelector
                dialog.show(fragmentActivity.supportFragmentManager, "CastDialog")
            }
        }
    }

    override fun playMedia(request: CastMediaRequest) {
        val session = currentSession ?: return
        if (!session.isConnected) return

        val videoUrl = request.url

        val mimeType = when {
            videoUrl.contains(".ts", ignoreCase = true) -> "video/mp2t"       
            videoUrl.contains(".mkv", ignoreCase = true) -> "video/x-matroska" 
            videoUrl.contains(".m3u8", ignoreCase = true) -> "application/x-mpegURL" 
            else -> "video/mp4" 
        }

        val movieMetadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE).apply {
            putString(MediaMetadata.KEY_TITLE, request.title)
            putString(MediaMetadata.KEY_SUBTITLE, "IPTV Easy Stream")
        }

        val mediaInfo = MediaInfo.Builder(videoUrl)
            .setStreamType(
                if (videoUrl.contains(".ts") || videoUrl.contains(".m3u8")) {
                    MediaInfo.STREAM_TYPE_LIVE
                } else {
                    MediaInfo.STREAM_TYPE_BUFFERED
                }
            )
            .setContentType(mimeType) 
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
        currentSession?.remoteMediaClient?.pause()
    }

    override fun resumeMedia() {
        currentSession?.remoteMediaClient?.play()
    }

    override fun seekMedia(positionInSeconds: Long) {
        val positionInMs = positionInSeconds * 1000
        currentSession?.remoteMediaClient?.seek(positionInMs)
    }

    override fun stopMedia() {
        currentSession?.remoteMediaClient?.stop()
    }
	
	override fun disconnectDevice() {
		android.os.Handler(android.os.Looper.getMainLooper()).post {
			// endSession(true) zorgt ervoor dat de Chromecast-verbinding hard wordt verbroken
			castContext?.sessionManager?.endCurrentSession(true)
		}
	}

    // --- 4. Google Cast Session Listener (Native -> Dart) ---

    private val castSessionListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarted(session: CastSession, sessionId: String) {
			// Wacht heel even op de Main Looper tot de client gereed is
			android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
				if (session.isConnected && session.remoteMediaClient != null) {
					flutterApi?.onConnectionStatusChanged(true) {}
				}
			}, 500)		
        }

        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
            flutterApi?.onConnectionStatusChanged(true) { /* no-op */ }
        }

        override fun onSessionEnded(session: CastSession, error: Int) {
            flutterApi?.onConnectionStatusChanged(false) { /* no-op */ }
        }

        override fun onSessionSuspended(session: CastSession, reason: Int) {
            flutterApi?.onConnectionStatusChanged(false) { /* no-op */ }
        }

        // HIER ZAT DE FOUT: 'sessionId: String' in plaats van 'wasSuspended: Boolean'
        override fun onSessionResuming(session: CastSession, sessionId: String) {}
        
        override fun onSessionStarting(session: CastSession) {}
        override fun onSessionStartFailed(session: CastSession, error: Int) {}
        override fun onSessionResumeFailed(session: CastSession, error: Int) {}
        override fun onSessionEnding(session: CastSession) {}
    }
}

class FixedMediaRouteChooserDialogFragment : MediaRouteChooserDialogFragment() {

    private var customThemeId: Int = 0

    override fun getContext(): Context? {
        val baseContext = super.getContext() ?: return null

        if (customThemeId == 0) {
            customThemeId = arguments?.getInt(ARG_THEME_ID) ?: 0
        }

        return if (customThemeId != 0) {
            ContextThemeWrapper(baseContext, customThemeId)
        } else {
            baseContext
        }
    }

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
