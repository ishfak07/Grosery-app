package com.ishi.grocerydelivery

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Explicitly opt in to edge-to-edge before super.onCreate(), matching
        // the official backward-compatible migration path for targetSdk 35+.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }
}
