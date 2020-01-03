package com.richardrobinson.countdown2

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import kotlin.time.Duration
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
			val remaining = event.secondsRemaining.inSeconds / (event.end.epochSecond - event.start.epochSecond).toDouble()

			setProgressBar(R.id.progressBar, 100, (remaining * 100).toInt(), false)

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