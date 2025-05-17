package com.example.software_graduation_project

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up notification channel for heads-up display
        NotificationUtil(applicationContext).setupNotificationChannel()
        
        // Register platform channel
        NotificationUtil.configureChannel(flutterEngine, applicationContext)
    }
}
