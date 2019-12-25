import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Model {
  final List<Event> events;
  final Configuration configuration;

  Model.empty()
      : configuration = Configuration(),
        events = [];

  Model.fromJson(Map<String, dynamic> map)
      : assert(map != null),
        configuration = Configuration.fromJson(map['configuration']),
        events = (map['events'] as List<dynamic>)
            .map<Event>((rawJSON) => Event.fromJson(rawJSON))
            .toList();

  Map<String, dynamic> toJson() => {
        'configuration': configuration.toJson(),
        'events': events.map<dynamic>((event) => event.toJson()).toList()
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

  @override
  String toString() {
    // TODO: implement toString
    var ret = 'Model{configuration=${configuration.toString()}, events=[\n';

    events.forEach((event) => ret += '\t${event.toString()}, \n');
    return '$ret]}';
  }
}

enum MyColorScheme { SystemDefault, Dark, Light }

extension Ex on MyColorScheme {
  String get name {
    switch (this) {
      case MyColorScheme.SystemDefault:
        return 'System Default';
      case MyColorScheme.Light:
        return 'The Light Side';
      case MyColorScheme.Dark:
        return 'The Dark Side';
      default:
        throw Exception();
    }
  }
}

class Configuration {
  bool shouldShowNotifications;
  bool shouldUseAltFont;
  MyColorScheme colorScheme;

  String get fontFamily => !shouldUseAltFont ? 'Inter' : 'OpenDyslexic';

  Configuration()
      : shouldUseAltFont = false,
        shouldShowNotifications = true,
        colorScheme = MyColorScheme.SystemDefault;

  Configuration.fromJson(Map<String, dynamic> json)
      : shouldShowNotifications =
            json['shouldShowNotifications'] as bool ?? true,
        shouldUseAltFont = json['shoudUseAltFont'] as bool ?? false,
        colorScheme = MyColorScheme.values[json['colorScheme'] as int ?? 0];

  Map<String, dynamic> toJson() => {
        'shouldShowNotifications': shouldShowNotifications,
        'shouldUseAltFont': shouldUseAltFont,
        'colorScheme': colorScheme.index
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

  static void saveModel(Model model) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('hourglassModel', json.encode(model.toJson()));
  }
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

    if (hour >= 5 && hour < 12) return 'Have an amazing morning 😀';
    if (hour >= 12 && hour < 19) return 'Have a nice afternoon 🥳';
    if (hour >= 19 || hour < 5) return 'Have a fantastic night 🥱';

    throw Exception('Did not satisfy any condition');
  }

  @override
  String toString() => content.isEmpty ? _greeting : '"$content" — $author';
}

class Circle extends StatelessWidget {
  final double radius;
  final Color color;

  Circle({Key key, @required this.radius, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Theme.of(context).primaryColor),
      );
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
  String toString() => '$days ${days == 1 ? 'day' : 'days'}, '
      '$hours ${hours == 1 ? 'hr' : 'hrs'}, '
      '$minutes ${minutes == 1 ? 'min' : 'mins'}, '
      '$seconds ${seconds == 1 ? 'sec' : 'secs'}';
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
  int compareTo(Event other) => this.end.compareTo(other.end);
}

extension ThemeExtension on ThemeData {
  Color get textColor => this.textTheme.body1.color;
}
