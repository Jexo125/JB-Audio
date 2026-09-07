package com.jbaudio.app

import android.media.audiofx.DynamicsProcessing
import android.util.Log

class DynamicsProcessingManager {
    private var dynamicsProcessing: DynamicsProcessing? = null
    private var isEnabled = false
    private var currentSessionId: Int = -1

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
        if (currentSessionId == sessionId && dynamicsProcessing != null) return

        Log.d(TAG, "Initializing DynamicsProcessing for session $sessionId")
        release()
        
        try {
            val builder = DynamicsProcessing.Config.Builder(
                DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                CHANNEL_COUNT,
                true, CUTOFF_FREQUENCIES.size, // Pre-EQ
                false, 0,                      // MBC (Disabled)
                false, 0,                      // Post-EQ (Disabled)
                true                           // Limiter
            )

            // Setup Pre-EQ stage (applied to all channels for consistency)
            val preEq = DynamicsProcessing.Eq(true, true, CUTOFF_FREQUENCIES.size)
            for (b in CUTOFF_FREQUENCIES.indices) {
                val eqBand = DynamicsProcessing.EqBand(true, CUTOFF_FREQUENCIES[b], 0f)
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
            builder.setInputGainAllChannelsTo(0f)

            dynamicsProcessing = DynamicsProcessing(0, sessionId, builder.build())
            dynamicsProcessing?.enabled = isEnabled
            currentSessionId = sessionId
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create DynamicsProcessing", e)
        }
    }

    fun setEnabled(enabled: Boolean) {
        isEnabled = enabled
        dynamicsProcessing?.enabled = enabled
    }

    fun setPreamp(gain: Float) {
        dynamicsProcessing?.let { dp ->
            try {
                dp.setInputGainAllChannelsTo(gain)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to set input gain", e)
            }
        }
    }

    fun setBandGains(gains: FloatArray) {
        dynamicsProcessing?.let { dp ->
            try {
                for (b in gains.indices) {
                    if (b < CUTOFF_FREQUENCIES.size) {
                        val eqBand = DynamicsProcessing.EqBand(true, CUTOFF_FREQUENCIES[b], gains[b])
                        dp.setPreEqBandAllChannelsTo(b, eqBand)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to set band gains", e)
            }
        }
    }

    fun reset() {
        setPreamp(0f)
        val flatGains = FloatArray(CUTOFF_FREQUENCIES.size) { 0f }
        setBandGains(flatGains)
    }

    fun release() {
        dynamicsProcessing?.release()
        dynamicsProcessing = null
        currentSessionId = -1
    }
}
