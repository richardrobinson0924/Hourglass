import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension SynchronizableList<E> on List<E> {
  static final makeKey = (dynamic e) => '__' + e.hashCode.toString();

  void syncAdd(E e) {
    this.add(e);
    this.sort();

    SharedPreferences.getInstance().then((prefs) => prefs.setString(makeKey(e), json.encode(e)));
  }

  void syncRemove(E e) {
    this.remove(e);

    SharedPreferences.getInstance().then((prefs) => prefs.remove(makeKey(e)));
  }

  void syncRemoveWhere(bool Function(E) test) {
    SharedPreferences.getInstance().then((prefs) {
      this.where(test).forEach((event) => prefs.remove(makeKey(event)));
      this.removeWhere(test);
    });
  }
}

class Model {
  List<Event> events = List<Event>();

  Model() {
    SharedPreferences.getInstance().then((prefs) {
      this.events = prefs.getKeys()
          .where((key) => key.startsWith('__'))
          .map((key) => Event.fromJson(json.decode(prefs.get(key))))
          .toList();

      this.events.sort();
    });
  }

}

/// Global access singleton
class Global {
  static final Global _instance = Global._internal();

  factory Global() => _instance;

  Global._internal();

  var quote = Quote();
}

/// A class to aide in parsing from a JSON HTTP GET request into a formatted [toString]
class Quote {
  final String content;
  final String author;

  Quote({this.content = '', this.author = ''});

  Quote.fromJson(Map<String, dynamic> json) : this(
    content: json['contents']['quotes'][0]['quote'],
    author: json['contents']['quotes'][0]['author']
  );

  @override
  String toString() => content.isEmpty ? 'Have a fantastic day.' : '"$content" — $author';
}

/// In contrast to the [Duration] class, the fields of [NormalizedDuration] are
/// discrete parts of the total remaining time and do not represent the entire
/// duration each
class NormalizedDuration {
  final int days, hours, minutes, seconds;

  NormalizedDuration({@required Duration totalDuration})
      : this.seconds = totalDuration.inSeconds.remainder(Duration.secondsPerMinute),
        this.minutes = totalDuration.inMinutes.remainder(Duration.minutesPerHour),
        this.hours   = totalDuration.inHours.remainder(Duration.hoursPerDay),
        this.days    = totalDuration.inDays;

  /// Formats the duration as a [String]; for example: `42 days 23 hrs 59 mins 00 secs`
  @override
  String toString() => '$days days, $hours hrs, $minutes mins, $seconds secs';
}

class Event implements Comparable<Event> {
  final String title;
  final DateTime start;
  final DateTime end;

  bool get isOver => end.difference(DateTime.now()) <= Duration(seconds: 0);

  NormalizedDuration get timeRemaining => NormalizedDuration(
      totalDuration: DateTime.now().difference(end).abs()
  );

  Event({@required this.title, @required this.end}) : start = DateTime.now() {
    assert (end.isAfter(start));
    assert (title.trim().length > 0);
  }

  /// Deserialize an [Event] instance from a JSON map
  Event.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        start = DateTime.fromMillisecondsSinceEpoch(json['start'] as int),
        end   = DateTime.fromMillisecondsSinceEpoch(json['end'] as int);

  /// Serialize this instance to a JSON map
  Map<String, dynamic> toJson() => {
    'title' : title,
    'start' : start.millisecondsSinceEpoch,
    'end'   : end.millisecondsSinceEpoch
  };

  @override
  String toString() => 'Event{title=$title, start=${start.toIso8601String()}, end=${end.toIso8601String()}';

  @override
  int compareTo(Event other) => this.end.compareTo(other.end);
}