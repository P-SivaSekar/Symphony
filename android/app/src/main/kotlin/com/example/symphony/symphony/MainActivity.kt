package com.example.symphony.symphony

import com.ryanheise.audioservice.AudioServiceActivity

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val TAG = "SymphonyRefreshRate"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setWindowToHighestRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        window.decorView.postDelayed({
            setWindowToHighestRefreshRate()
        }, 500)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            window.decorView.postDelayed({
                setWindowToHighestRefreshRate()
            }, 500)
        }
    }

    private fun setWindowToHighestRefreshRate() {
        try {
            val window = window
            val layoutParams = window.attributes

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val display = context.display
                val supportedModes = display?.supportedModes
                if (supportedModes != null && supportedModes.isNotEmpty()) {
                    val highestMode = supportedModes
                        .filter { it.refreshRate >= 60f }
                        .maxByOrNull { it.refreshRate }
                    
                    if (highestMode != null) {
                        layoutParams.preferredDisplayModeId = highestMode.modeId
                        layoutParams.preferredRefreshRate = highestMode.refreshRate
                        Log.d(TAG, "Natively set highest mode: ID ${highestMode.modeId}, Hz ${highestMode.refreshRate}")
                    }
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                layoutParams.preferredRefreshRate = 120f
                Log.d(TAG, "Natively set preferredRefreshRate to 120Hz")
            }

            window.attributes = layoutParams
        } catch (e: Exception) {
            Log.e(TAG, "Error setting highest refresh rate: ${e.message}", e)
        }
    }
}
