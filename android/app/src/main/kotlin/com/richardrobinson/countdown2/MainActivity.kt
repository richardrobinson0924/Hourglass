package com.richardrobinson.countdown2

import android.content.Intent
import android.os.Bundle

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  private var selectedEventIndex: Int = 0

  companion object {
    const val INDEX_ACTION: String = "com.richardrobinson.countdown2.shared.data"
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    if (intent.type != null) {
      selectedEventIndex = intent.getIntExtra(EventWidget.EXTRA_ID, 0)
    }

    MethodChannel(flutterView, INDEX_ACTION)
            .setMethodCallHandler { call, result ->
      if (call.method!!.contentEquals("getEventID")) {
        result.success(selectedEventIndex)
      }
    }
  }
}
