package com.richardrobinson.countdown2

import android.content.SharedPreferences
import android.graphics.Color
import com.google.gson.JsonElement
import com.google.gson.JsonParser
import java.time.Instant
import kotlin.time.Duration
import kotlin.time.ExperimentalTime
import kotlin.time.seconds


data class Event(val title: String, val end: Instant, val color: Color, val start: Instant = Instant.now()) {
    val isOver: Boolean
        get() = Instant.now().epochSecond >= end.epochSecond

    @ExperimentalTime
    val timeRemaining: Duration
        get() = if (isOver) (0).seconds else (end.epochSecond - Instant.now().epochSecond).seconds

    @ExperimentalTime
    val totalDuration: Duration
        get() = (end.epochSecond - start.epochSecond).seconds
    
    val id: Long
        get() = start.hashCode().toLong()

    companion object {
        fun deserialize(json: JsonElement): Event {
            val obj = json.asJsonObject
            return Event(
                    title = obj["title"].asString,
                    start = Instant.ofEpochMilli(obj["start"].asLong),
                    end = Instant.ofEpochMilli(obj["end"].asLong),
                    color = Color.valueOf(obj["color"].asInt)
            )
        }
    }

}

object MiniModel {
    var events: List<Event> = ArrayList()
    var isDark: Boolean = false

    fun initialize(prefs: SharedPreferences) {
        val flutterPrefix = "flutter."

        this.isDark = prefs.getBoolean("${flutterPrefix}isDark", false)
        val modelPrefs = prefs.getString("${flutterPrefix}hourglassModel", "")

        if (!modelPrefs.isNullOrBlank()) {
            this.events = JsonParser.parseString(modelPrefs)
                    .asJsonObject
                    .getAsJsonArray("events")
                    .map { Event.deserialize(json = it) }
        }
    }
}



















