package com.richardrobinson.countdown2

import android.annotation.TargetApi
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import kotlin.time.ExperimentalTime

/**
 * Implementation of App Widget functionality.
 */
@TargetApi(Build.VERSION_CODES.CUPCAKE)
@ExperimentalTime
class EventWidget : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.hasExtra(WIDGET_IDS_KEY)) {
            val ids: IntArray? = intent.extras!!.getIntArray(WIDGET_IDS_KEY)
            if (ids != null) {
                onUpdate(context, AppWidgetManager.getInstance(context), ids)
            }
        }

        super.onReceive(context, intent)
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { appWidgetId ->
            val event = Event.parseEvent(context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE))

            val pendingIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                action = OPEN_EVENT_INTENT
                putExtra(EXTRA_ID, event?.index ?: 0)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }.let {
                intent -> PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
            }

            val views: RemoteViews = RemoteViews(context.packageName, R.layout.widget).apply {
                setOnClickPendingIntent(R.id.widget, pendingIntent)

                if (event != null) {
                    setTextViewText(R.id.title2, event.title)

                    setTextViewText(R.id.days, event.timeRemaining.days.toString().padStart(2, '0'))
                    setTextViewText(R.id.hours, event.timeRemaining.hours.toString().padStart(2, '0'))
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }


    companion object {
        const val OPEN_EVENT_INTENT = "com.richardrobinson.countdown2.appwidget.openevent"
        const val EXTRA_ID = "com.richardrobinson.countdown2.appwidget.ID"
        const val WIDGET_IDS_KEY = "mywidgetproviderwidgetids"

        private const val PREFS_NAME = "FlutterSharedPreferences"
    }
}