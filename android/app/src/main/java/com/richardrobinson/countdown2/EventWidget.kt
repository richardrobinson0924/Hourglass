package com.richardrobinson.countdown2

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.Service
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.*
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.widget.RemoteViews
import androidx.annotation.RequiresApi

/**
 * Implementation of App Widget functionality.
 */
@RequiresApi(Build.VERSION_CODES.CUPCAKE)
class EventWidget : AppWidgetProvider() {

    class UpdateTimeService : Service() {

        private val intentFilter = IntentFilter().apply {
            addAction(Intent.ACTION_TIME_TICK)
            addAction(Intent.ACTION_TIME_CHANGED)
            addAction(Intent.ACTION_TIMEZONE_CHANGED)
        }

        private val receiver = object: BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) = update(context)
        }


        override fun onCreate() {
            super.onCreate()
            registerReceiver(receiver, intentFilter)
        }

        override fun onBind(intent: Intent?): IBinder? = null

        override fun onDestroy() {
            super.onDestroy()
            unregisterReceiver(receiver)
        }

        override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
            super.onStartCommand(intent, flags, startId)

            if (intent != null && UPDATE_TIME == intent.action) update(this)

            return START_STICKY
        }

        companion object {
            const val UPDATE_TIME = "com.richardrobinson.countdown2.action.UPDATE_TIME"
        }

    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach {
            val intent = Intent(context, EventWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, it)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }

            val pendingIntent: PendingIntent = Intent(context, MainActivity::class.java).let { i ->
                PendingIntent.getActivity(context, 0, i, 0)
            }

            val rv = RemoteViews(context.packageName, R.layout.event_widget).apply {
                setRemoteAdapter(R.id.listView, intent)
                setOnClickPendingIntent(R.id.listView, pendingIntent)
            }


            appWidgetManager.updateAppWidget(it, rv)
        }

        update(context)

        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.listView)

        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
        super.onEnabled(context)
        val pending = PendingIntent.getService(context, 0, Intent(context, UpdateTimeService::class.java), 0)

        val interval: Long = 1000 * 60

        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).apply {
            cancel(pending)
            setRepeating(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime(), interval, pending)
        }

        update(context)
    }

	override fun onReceive(context: Context, intent: Intent?) {
		super.onReceive(context, intent)
		update(context)
	}

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    companion object {
        val EXTRA_ID: String = "com.richardrobinson.countdown2.appwidget.ID"
    }
}

fun update(context: Context) {
    val rv = RemoteViews(context.packageName, R.layout.event_widget).apply {
        setRemoteAdapter(R.id.listView, Intent(context, EventWidgetService::class.java))
    }

    val component = ComponentName(context, EventWidget::class.java)

    AppWidgetManager.getInstance(context).apply {
        updateAppWidget(component, rv)

        val ids = getAppWidgetIds(component)
        ids.forEach { updateAppWidget(it, rv) }

        notifyAppWidgetViewDataChanged(ids, R.id.listView)
    }

}