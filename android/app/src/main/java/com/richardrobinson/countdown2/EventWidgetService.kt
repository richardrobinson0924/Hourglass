package com.richardrobinson.countdown2

import android.app.Activity
import android.view.*
import android.content.Context
import android.content.Intent
import android.content.res.Resources
import android.content.res.XmlResourceParser
import android.graphics.drawable.Drawable
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.util.concurrent.TimeUnit
import kotlin.time.Duration
import kotlin.time.DurationUnit
import kotlin.time.ExperimentalTime

class EventWidgetService : RemoteViewsService() {
	override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
			EventRemoteViewsFactory(this.applicationContext, intent)
}

class EventRemoteViewsFactory(private val context: Context, intent: Intent) : RemoteViewsService.RemoteViewsFactory {
	private val prefsName = "FlutterSharedPreferences"

	override fun onCreate() {
		MiniModel.initialize(context.getSharedPreferences(prefsName, Context.MODE_PRIVATE))
	}

	override fun getLoadingView(): RemoteViews = RemoteViews(context.packageName, R.id.emptyView)

	override fun getItemId(position: Int): Long = position.toLong()

	override fun onDataSetChanged() {
	}

	override fun hasStableIds(): Boolean = true

	@ExperimentalTime
	override fun getViewAt(position: Int): RemoteViews {
		return RemoteViews(context.packageName, R.layout.widget_item).apply {
			val event = MiniModel.events[position]

			setProgressBar(
					R.id.progressBar,
					(event.end.epochSecond - event.start.epochSecond).toInt(),
					event.secondsRemaining.toInt(unit = TimeUnit.SECONDS),
					false
			)

			setTextViewText(R.id.item_text, event.title)

			setTextViewText(R.id.details_text, if (event.isOver) "Event Complete" else "in " + event.secondsRemaining.asPrettyString)
		}
	}

	@ExperimentalTime
	private val Duration.asPrettyString: String
		get() = mapOf(
				"day" to inDays.toInt(),
				"hour" to inHours.toInt().rem(24),
				"min" to inMinutes.toInt().rem(60)
		).map { (s, value) ->
			"$value ${if (value == 1) s else s + "s"}"
		}.joinToString(separator = ", ")

	override fun getCount(): Int = MiniModel.events.count()

	override fun getViewTypeCount(): Int = 1

	override fun onDestroy() {
	}

}