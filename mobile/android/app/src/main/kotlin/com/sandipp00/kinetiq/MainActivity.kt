package com.sandipp00.kinetiq

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var launchChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets Dart see whether Health Connect opened the app to show the privacy policy.
        launchChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kinetiq/launch").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getLaunchAction") result.success(intent?.action) else result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.action?.let { launchChannel?.invokeMethod("onNewAction", it) }
    }
}
