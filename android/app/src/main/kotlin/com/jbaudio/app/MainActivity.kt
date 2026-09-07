package com.jbaudio.app

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceFragmentActivity() {
    private val dynamicsManager = DynamicsProcessingManager()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.devid.musly/dynamics").setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val sessionId = call.argument<Int>("sessionId")
                    if (sessionId != null) {
                        dynamicsManager.initialize(sessionId)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "sessionId is null", null)
                    }
                }
                "setEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    dynamicsManager.setEnabled(enabled)
                    result.success(null)
                }
                "setPreamp" -> {
                    val gain = call.argument<Double>("gain")?.toFloat() ?: 0f
                    dynamicsManager.setPreamp(gain)
                    result.success(null)
                }
                "setBandGains" -> {
                    val gainsList = call.argument<List<Double>>("gains")
                    if (gainsList != null) {
                        dynamicsManager.setBandGains(gainsList.map { it.toFloat() }.toFloatArray())
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "gains is null", null)
                    }
                }
                "reset" -> {
                    dynamicsManager.reset()
                    result.success(null)
                }
                "release" -> {
                    dynamicsManager.release()
                    result.success(null)
                }
                "getApiLevel" -> {
                    result.success(android.os.Build.VERSION.SDK_INT)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        dynamicsManager.release()
        super.onDestroy()
    }
}
