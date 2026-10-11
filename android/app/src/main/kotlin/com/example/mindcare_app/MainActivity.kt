package com.example.mindcare_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var oauthChannel: MethodChannel? = null
    private var pendingOAuthUri: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        oauthChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mindcare.app/oauth"
        ).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getPendingOAuthRedirect") {
                    result.success(pendingOAuthUri)
                    pendingOAuthUri = null
                } else {
                    result.notImplemented()
                }
            }
        }
        handleOAuthIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleOAuthIntent(intent)
    }

    private fun handleOAuthIntent(intent: Intent?) {
        val data = intent?.data ?: return
        if (data.scheme == "com.googleusercontent.apps.384910835517-8inlm7mueqpbtv6v53isj8tltcb3r7hh") {
            val uriString = data.toString()
            pendingOAuthUri = uriString
            oauthChannel?.invokeMethod("onOAuthRedirect", uriString)
        }
    }
}
