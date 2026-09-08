package com.jdbs.iptv.easy_chromecast_plugin

import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.CastMediaControlIntent

class CastOptionsProvider : OptionsProvider {

    override fun getCastOptions(context: Context): CastOptions {
        // We gebruiken hier het standaard Google Media Receiver ID.
        // Dit ID ondersteunt vrijwel alle standaard MP4/HLS videostreams.
        val defaultReceiverId = CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID

        return CastOptions.Builder()
            .setReceiverApplicationId(defaultReceiverId)
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
        return null
    }
}
