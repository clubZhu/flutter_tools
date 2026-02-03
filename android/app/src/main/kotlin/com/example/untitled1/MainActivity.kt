package com.example.untitled1

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.untitled1/foreground_service"
    private var startServiceIntent: Intent? = null
    private var stopServiceIntent: Intent? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 设置透明导航栏，让背景延伸到导航栏下方
        window.setFlags(
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    startForegroundService()
                    result.success(null)
                }
                "stopForegroundService" -> {
                    stopForegroundService()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startForegroundService() {
        if (startServiceIntent == null) {
            startServiceIntent = Intent(this, ForegroundService::class.java)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(startServiceIntent)
        } else {
            startService(startServiceIntent)
        }
    }

    private fun stopForegroundService() {
        if (stopServiceIntent == null) {
            stopServiceIntent = Intent(this, ForegroundService::class.java)
        }
        stopService(stopServiceIntent)
    }
}
