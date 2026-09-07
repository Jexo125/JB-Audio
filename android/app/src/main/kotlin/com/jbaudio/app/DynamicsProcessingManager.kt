package com.jbaudio.app

import android.media.audiofx.DynamicsProcessing
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder

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

            // Setup Pre-EQ bands for each channel
            for (c in 0 until CHANNEL_COUNT) {
                builder.setInputGainByChannelIndex(c, 0f)
                for (b in CUTOFF_FREQUENCIES.indices) {
                    val eqBand = DynamicsProcessing.EqBand(true, CUTOFF_FREQUENCIES[b], 0f)
                    builder.setPreEqBandByChannelIndex(c, b, eqBand)
                }
                
                // Configure Limiter for safety (transparent protection)
                // Threshold very close to 0 dBFS, high ratio, fast attack.
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
                builder.setLimiterByChannelIndex(c, limiter)
            }

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
            for (c in 0 until CHANNEL_COUNT) {
                dp.setInputGainByChannelIndex(c, gain)
            }
        }
    }

    fun setBandGains(gains: FloatArray) {
        dynamicsProcessing?.let { dp ->
            for (c in 0 until CHANNEL_COUNT) {
                for (b in gains.indices) {
                    if (b < CUTOFF_FREQUENCIES.size) {
                        val band = dp.getPreEqBandByChannelIndex(c, b)
                        band.gain = gains[b]
                        dp.setPreEqBandByChannelIndex(c, b, band)
                    }
                }
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
