import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Model {
  final List<Event> events;
  final Configuration configuration;

  Model.fromJson(Map<String, dynamic> map)
    : configuration = map == null
          ? Configuration()
          : Configuration.fromJson(map['configuration']),
      events = map == null
          ? []
          : (map['events'] as List<dynamic>)
              .map<Event>((rawJSON) => Event.fromJson(rawJSON))
              .toList(); /* (map['events'] as List<dynamic>).map<Event>((e) => Event.fromJson(json.decode(e))).toList(); */

  Map<String, dynamic> toJson() => {
    'configuration': configuration.toJson(),
    'events': events
        .map<dynamic>((event) => event.toJson())
        .toList() /* events.map<String>((event) => json.encode(event.toJson())).toList() */
  };

  int get numberOfEvents => events?.length ?? 0;

  Event eventAt(int index) => events[index];

  void addEvent(Event e) {
    assert(events != null);

    events.add(e);

    if (configuration.shouldShowNotifications) {
      Global().notificationsManager.schedule(
          e.hashCode,
          'Countdown to ${e.title} Over',
          'The countdown to ${e.title} is now complete!',
          e.end,
          Global().notificationDetails,
          payload: json.encode(e.toJson()));
    }
  }

  void removeEvent(Event e) {
    events.remove(e);

    Global().notificationsManager.cancel(e.hashCode);
  }
}

class Configuration {
  bool shouldShowNotifications;
  bool shouldUseAltFont;
  String get fontFamily => !shouldUseAltFont ? 'Inter' : 'OpenDyslexic';

  Configuration()
      : shouldUseAltFont = false,
        shouldShowNotifications = true;

  Configuration.fromJson(Map<String, dynamic> json)
      : shouldShowNotifications =
            json['shouldShowNotifications'] as bool ?? true,
        shouldUseAltFont = json['shoudUseAltFont'] as bool ?? false;

  Map<String, dynamic> toJson() => {
        'shouldShowNotifications': shouldShowNotifications,
        'shouldUseAltFont': shouldUseAltFont
      };
}

/// Global access singleton
class Global {
  static final Global _instance = Global._internal();
  factory Global() => _instance;
  Global._internal();

  var quote = Quote();

  final notificationsManager = FlutterLocalNotificationsPlugin();

  final notificationDetails = NotificationDetails(
      AndroidNotificationDetails(
        'com.richardrobinson.countdown',
        'Hourglass',
        'The countdown app',
        importance: Importance.Max,
        priority: Priority.High,
      ),
      null);

  static void saveModel(Model model) =>
      SharedPreferences.getInstance().then((prefs) =>
          prefs.setString('hourglassModel', json.encode(model.toJson())));
}

/// A class to aide in parsing from a JSON HTTP GET request into a formatted [toString]
class Quote {
  final String content;
  final String author;

  Quote({this.content = '', this.author = ''});

  Quote.fromJson(Map<String, dynamic> json)
      : this(
            content: json['contents']['quotes'][0]['quote'],
            author: json['contents']['quotes'][0]['author']);

  String get _greeting {
    var hour = DateTime.now().hour;
    print(hour.toString());

    if (hour >= 5 && hour < 12) return 'Have an amazing morning 😀';
    if (hour >= 12 && hour < 19) return 'Have a nice afternoon 🥳';
    if (hour >= 19 || hour < 5) return 'Have a fantastic night 🥱';

    throw Exception('Did not satisfy any condition');
  }

  @override
  String toString() => content.isEmpty ? _greeting : '"$content" — $author';
}

/// In contrast to the [Duration] class, the fields of [NormalizedDuration] are
/// discrete parts of the total remaining time and do not represent the entire
/// duration each
class NormalizedDuration {
  final int days, hours, minutes, seconds;

  NormalizedDuration.custom(
      [this.days = 0, this.hours = 0, this.minutes = 0, this.seconds = 0]);

  NormalizedDuration({@required Duration totalDuration})
      : this.seconds =
            totalDuration.inSeconds.remainder(Duration.secondsPerMinute),
        this.minutes =
            totalDuration.inMinutes.remainder(Duration.minutesPerHour),
        this.hours = totalDuration.inHours.remainder(Duration.hoursPerDay),
        this.days = totalDuration.inDays;

  /// Formats the duration as a [String]; for example: `42 days 23 hrs 59 mins 00 secs`
  @override
  String toString() => '$days days, $hours hrs, $minutes mins, $seconds secs';
}

class Event implements Comparable<Event> {
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;

  bool get isOver => end.difference(DateTime.now()) <= Duration(seconds: 0);

  NormalizedDuration get timeRemaining =>
      NormalizedDuration(totalDuration: DateTime.now().difference(end).abs());

  Event({@required this.title, @required this.end, @required this.color})
      : start = DateTime.now(),
        assert(end != null),
        assert(color != null),
        assert(end.isAfter(DateTime.now()));

  /// Deserialize an [Event] instance from a JSON map
  Event.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        color = Color(json['color'] as int),
        start = DateTime.fromMillisecondsSinceEpoch(json['start'] as int),
        end = DateTime.fromMillisecondsSinceEpoch(json['end'] as int);

  /// Serialize this instance to a JSON map
  Map<String, dynamic> toJson() => {
        'title': title,
        'color': color.value,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch
      };

  @override
  String toString() => toJson().toString();

  @override
  int compareTo(Event other) => this.end.compareTo(other.end);
}
