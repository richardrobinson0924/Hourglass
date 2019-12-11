import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Model {
  List<Event> _events;
  SharedPreferences _prefs;

  int get size => _events?.length ?? 0;

  void removeCompletedEvents() {
    var condition = (Event event) => event.isOver;

    _events.where(condition).forEach((event) => _prefs.remove('__${event.title}'));
    _events.removeWhere(condition);
  }

  Model() : _events = null;

  /// Asynchronously initializes the model. Must be called only once, before any
  /// other methods or functions are called
  Future<Null> initialize() async {
    assert (_events == null);
    _prefs = await SharedPreferences.getInstance();

    this._events = _prefs.getKeys()
        .where((key) => key.startsWith('__'))
        .map<Event>((key) => Event.fromJson(json.decode(_prefs.get(key))))
        .toList();
  }

  /// Adds [event] to the user's model's list of events
  ///
  /// Preconditions: [events] does not contain an [Event] whose [title] is equal to that of [event]
  void add(Event event) {
    assert (_events != null && _events.every((other) => other.title != event.title));

    _events.add(event);
    _prefs.setString('__${event.title}', json.encode(event));
  }

  /// Removes [event] from the user's model's [events] list
  ///
  /// Preconditions: [initialize] was previously called
  void remove(Event event) {
    assert (_events != null && _events.contains(event));

    _events.remove(event);
    _prefs.remove('__${event.title}');
  }

  Event eventAt({@required int index}) => _events[index];
}

class Quote {
  final String content;
  final String author;

  Quote({this.content = '', this.author = ''});

  Quote.fromJson(Map<String, dynamic> json) : this(
    content: json['contents']['quotes'][0]['quote'],
    author: json['contents']['quotes'][0]['author']
  );

  @override
  String toString() => content.isEmpty ? '' : '$content -- $author';
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
  int compareTo(Event other) => end.compareTo(other.end);

  @override
  String toString() => 'Event{title=$title, start=${start.toIso8601String()}, end=${end.toIso8601String()}';
}