package com.richardrobinson.countdown2

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
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

	override fun getLoadingView(): RemoteViews? = null

	override fun getItemId(position: Int): Long = position.toLong()

	override fun onDataSetChanged() {
	}

	override fun hasStableIds(): Boolean = true

	@ExperimentalTime
	override fun getViewAt(position: Int): RemoteViews {
		val event = MiniModel.events[position]

		val colorMap = mapOf(
				R.color.tealFG to R.id.progressBarTeal,
				R.color.orangeFG to R.id.progressBarOrange,
				R.color.deepPurpleFG to R.id.progressBarDeepPurple,
				R.color.indigoFG to R.id.progressBarIndigo,
				R.color.redFG to R.id.progressBarRed
		).mapKeys {
			Color.valueOf(context
					.applicationContext
					.resources
					.getColor(it.key, null))
		}

		val fillInIntent = Intent().apply {
			Bundle().also { extras ->
				extras.putInt(EventWidget.EXTRA_ID, position)
				putExtras(extras)
			}
		}


		return RemoteViews(context.packageName, R.layout.widget_item).apply {
			setViewVisibility(colorMap[event.color] ?: error(""), View.VISIBLE)

			setProgressBar(
					colorMap[event.color] ?: error(""),
					event.totalDuration.toInt(unit = DurationUnit.SECONDS),
					event.timeRemaining.toInt(unit = DurationUnit.SECONDS),
					false
			)

			setTextViewText(R.id.item_text, event.title)

			setTextViewText(R.id.details_text, if (event.isOver) "Event Completed" else "in " + event.timeRemaining.daysAndHours)

			setOnClickFillInIntent(this.layoutId, fillInIntent)
		}
	}

	@ExperimentalTime
	private val Duration.daysAndHours: String
		get() {
			val days = inDays.toInt()
			var hrs = inHours.toInt().rem(24)
			if (inMinutes.toInt().rem(60) >= 30) hrs++

			val daysStr = if (days == 1) "day" else "days"
			val hrsStr = if (hrs == 1) "hour" else "hours"

			return "$days $daysStr and $hrs $hrsStr"
		}

	override fun getCount(): Int = MiniModel.events.count()

	override fun getViewTypeCount(): Int = 1

	override fun onDestroy() {
	}

}