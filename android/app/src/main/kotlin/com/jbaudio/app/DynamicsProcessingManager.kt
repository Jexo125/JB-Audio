package com.jbaudio.app

import android.media.audiofx.DynamicsProcessing
import android.util.Log

class DynamicsProcessingManager {
    private var dynamicsProcessing: DynamicsProcessing? = null
    private var isEnabled = false
    private var currentSessionId: Int = -1
    
    // State storage to restore when effect is recreated
    private var currentPreampGain: Float = 0f
    private var currentBandGains: FloatArray = FloatArray(5) { 0f }

    companion object {
        private const val TAG = "DynamicsManager"
        private const val CHANNEL_COUNT = 2 // Stereo
        
        // Crossover frequencies (Cutoff frequencies)
        private val CUTOFF_FREQUENCIES = floatArrayOf(
            100f,   // Band 0: 0-100 Hz (Sub-bass)
            300f,   // Band 1: 100-300 Hz (Bass/Low-mids)
            1000f,  // Band 2: 300-1000 Hz (Mids)
            4000f,  // Band 3: 1000-4000 Hz (High-mids)
            20000f  // Band 4: 4000-20000 Hz (Highs)
        )
    }

    fun initialize(sessionId: Int) {
        if (sessionId <= 0) {
            Log.w(TAG, "Invalid session ID: $sessionId")
            return
        }
        
        if (currentSessionId == sessionId && dynamicsProcessing != null) return

        Log.d(TAG, "Updating sessionId to $sessionId")
        val wasEnabled = isEnabled
        
        // If session changed, we must recreate the effect
        if (currentSessionId != sessionId) {
            release()
            currentSessionId = sessionId
        }
        
        // Only create the effect if it should be enabled
        // This is the safest way to ensure NO sound interference when OFF
        if (wasEnabled) {
            createEffect()
        }
    }

    private fun createEffect() {
        if (dynamicsProcessing != null || currentSessionId <= 0) return
        
        try {
            Log.d(TAG, "Creating DynamicsProcessing for session $currentSessionId")
            val builder = DynamicsProcessing.Config.Builder(
                DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                CHANNEL_COUNT,
                true, CUTOFF_FREQUENCIES.size, // Pre-EQ
                false, 0,                      // MBC (Disabled)
                false, 0,                      // Post-EQ (Disabled)
                true                           // Limiter
            )

            // Setup Pre-EQ stage
            val preEq = DynamicsProcessing.Eq(true, true, CUTOFF_FREQUENCIES.size)
            for (b in CUTOFF_FREQUENCIES.indices) {
                // Initialize with stored gains
                val eqBand = DynamicsProcessing.EqBand(true, CUTOFF_FREQUENCIES[b], currentBandGains[b])
                preEq.setBand(b, eqBand)
            }
            builder.setPreEqAllChannelsTo(preEq)

            // Configure Limiter for safety (transparent protection)
            val limiter = DynamicsProcessing.Limiter(
                true,  // inUse
                true,  // enabled
                0,     // linkGroup
                1f,    // attackTime (ms)
                100f,  // releaseTime (ms)
                10f,   // ratio (10:1)
                -0.1f, // threshold (dBFS)
                0f     // postGain (dB)
            )
            builder.setLimiterAllChannelsTo(limiter)
            builder.setInputGainAllChannelsTo(currentPreampGain)

            dynamicsProcessing = DynamicsProcessing(0, currentSessionId, builder.build())
            dynamicsProcessing?.enabled = true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create DynamicsProcessing effect", e)
            dynamicsProcessing = null
        }
    }

    fun setEnabled(enabled: Boolean) {
        if (isEnabled == enabled && (enabled == (dynamicsProcessing != null))) return
        
        isEnabled = enabled
        if (enabled) {
            if (dynamicsProcessing == null) {
                createEffect()
            } else {
                dynamicsProcessing?.enabled = true
            }
        } else {
            // Completely release the effect when disabled
            // This guarantees no audio session blocking on buggy drivers (Samsung)
            releaseEffectOnly()
        }
    }

    fun setPreamp(gain: Float) {
        currentPreampGain = gain
        dynamicsProcessing?.let { dp ->
            try {
                dp.setInputGainAllChannelsTo(gain)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update input gain", e)
            }
        }
    }

    fun setBandGains(gains: FloatArray) {
        // Store the gains
        for (i in gains.indices) {
            if (i < currentBandGains.size) {
                currentBandGains[i] = gains[i]
            }
        }
        
        dynamicsProcessing?.let { dp ->
            try {
                for (b in gains.indices) {
                    if (b < CUTOFF_FREQUENCIES.size) {
                        val eqBand = DynamicsProcessing.EqBand(true, CUTOFF_FREQUENCIES[b], gains[b])
                        dp.setPreEqBandAllChannelsTo(b, eqBand)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update band gains", e)
            }
        }
    }

    fun reset() {
        currentPreampGain = 0f
        currentBandGains = FloatArray(CUTOFF_FREQUENCIES.size) { 0f }
        
        if (dynamicsProcessing != null) {
            setPreamp(0f)
            setBandGains(currentBandGains)
        }
    }

    private fun releaseEffectOnly() {
        try {
            dynamicsProcessing?.enabled = false
            dynamicsProcessing?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing effect", e)
        } finally {
            dynamicsProcessing = null
        }
    }

    fun release() {
        releaseEffectOnly()
        currentSessionId = -1
    }
}
