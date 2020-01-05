package com.richardrobinson.countdown2

import android.annotation.TargetApi
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.view.FlutterView
import kotlin.time.ExperimentalTime

class MainActivity: FlutterActivity() {
  private var selectedEventIndex: Int = -1

  @TargetApi(Build.VERSION_CODES.CUPCAKE)
  @ExperimentalTime
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    val channel = MethodChannel(flutterView, FLUTTER_CHANNEL)

    if (intent.action == EventWidget.OPEN_EVENT_INTENT) {
      selectedEventIndex = intent.getIntExtra(EventWidget.EXTRA_ID, -1)

      channel.invokeMethod("update", selectedEventIndex)
    }

    if (intent.action == Intent.ACTION_VIEW) {
      channel.invokeMethod("addEvent", null)
    }


    channel.setMethodCallHandler { call, result ->
      when (call.method) {
        "getEventID" -> result.success(selectedEventIndex)

        "updateWidget" -> {
          val ids = AppWidgetManager.getInstance(applicationContext)
                  .getAppWidgetIds(ComponentName(applicationContext, EventWidget::class.java))

          val intent = Intent().apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(EventWidget.WIDGET_IDS_KEY, ids)
          }

          applicationContext.sendBroadcast(intent)
          result.success(null)
        }
      }
    }

  }

  companion object {
    const val FLUTTER_CHANNEL = "com.richardrobinson.countdown2.shared.data"
  }

}
