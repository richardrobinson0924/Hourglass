package com.richardrobinson.countdown2

import android.annotation.TargetApi
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonParser
import java.time.Instant
import kotlin.time.Duration
import kotlin.time.ExperimentalTime
import kotlin.time.seconds


data class Event(val title: String, val end: Instant, val index: Int, val start: Instant = Instant.now()) {
    val isOver: Boolean
        get() = Instant.now().epochSecond >= end.epochSecond

    @ExperimentalTime
    val timeRemaining: Duration
        get() = if (isOver) (0).seconds else (end.epochSecond - Instant.now().epochSecond).seconds

    companion object {
        private fun deserialize(json: JsonElement, index: Int): Event {
            val obj = json.asJsonObject
            return Event(
                    title = obj["title"].asString,
                    start = Instant.ofEpochMilli(obj["start"].asLong),
                    end = Instant.ofEpochMilli(obj["end"].asLong),
                    index = index
            )
        }

        fun parseEvent(prefs: SharedPreferences): Event? {
            val flutterPrefix = "flutter."

            val model = prefs.getString("${flutterPrefix}hourglassModel", "").let {
                JsonParser.parseString(it ?: "{}").asJsonObject
            }

            val index = model.get("eventIndex")?.asInt ?: 0
            val events =  model.getAsJsonArray("events") ?: null

            if (events != null && index >= 0 && index < events.size()) {
                return deserialize(events[index], index)
            }

            return null
        }
    }

}


@ExperimentalTime
val Duration.days: Int
    get() = inDays.toInt()

@ExperimentalTime
val Duration.hours: Int
    get() = inHours.toInt().rem(24)

@ExperimentalTime
val Duration.minutes: Int
    get() = inMinutes.toInt().rem(60)















