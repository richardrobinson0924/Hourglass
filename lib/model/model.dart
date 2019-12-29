import 'dart:collection';
import 'dart:convert';

import 'package:countdown/model/prose.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension DurationExt on Duration {
  double operator /(Duration other) => this.inSeconds / other.inSeconds;
}

extension ListExt<T> on List<T> {
  /// Reorders the elements in a list using the algorithm provided at
  /// <https://stackoverflow.com/questions/54162721/>
  void move({@required int oldIndex, @required int newIndex}) {
    assert(oldIndex >= 0 && oldIndex < this.length);
    assert(newIndex >= 0);

    if (newIndex > this.length) newIndex = this.length;
    if (oldIndex < newIndex) newIndex--;

    final item = this.removeAt(oldIndex);
    this.insert(newIndex, item);
  }
}

class Model {
  final List<Event> _events;
  final Configuration configuration;

  UnmodifiableListView<Event> get events =>
      UnmodifiableListView<Event>(_events);

  Model.empty()
      : configuration = Configuration(),
        _events = [];

  Model.fromJson(Map<String, dynamic> map)
      : assert(map != null),
        configuration = Configuration.fromJson(map['configuration']),
        _events = (map['events'] as List<dynamic>)
            .map<Event>((rawJSON) => Event.fromJson(rawJSON))
            .toList();

  Map<String, dynamic> toJson() => {
        'configuration': configuration.toJson(),
        'events': _events.map<dynamic>((event) => event.toJson()).toList()
      };

  void addEvent(Event e, {int index}) {
    assert(_events != null);

    _events.insert(index ?? _events.length, e);

    if (configuration.shouldShowNotifications) {
      Global.instance().notificationsManager.schedule(
          e.hashCode,
          'Countdown to ${e.title} Over',
          'The countdown to ${e.title} is now complete!',
          e.end,
          Global.instance().notificationDetails,
          payload: json.encode(e.toJson()));
    }
  }

  void removeEvent(Event e) {
    _events.remove(e);

    Global.instance().notificationsManager.cancel(e.hashCode);
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
  factory Global.instance() => _instance;
  Global._internal();

  String prose = Prose.greeting;

  final notificationsManager = FlutterLocalNotificationsPlugin();

  final notificationDetails = NotificationDetails(
      AndroidNotificationDetails(
        'com.richardrobinson.countdown2',
        'Hourglass',
        'The countdown app',
        importance: Importance.Max,
        priority: Priority.High,
      ),
      null);

  static void saveModel(Model model) async {
    if (model != null) {
      var prefs = await SharedPreferences.getInstance();
      prefs.setString('hourglassModel', json.encode(model.toJson()));
    }
  }
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

  @override
  String toString() =>
      <String, int>{'day': days, 'hour': hours, 'min': minutes, 'sec': seconds}
          .entries
          .map<String>((entry) => (entry.value == 1)
              ? '1 ${entry.key}'
              : '${entry.value} ${entry.key}s')
          .join(', ');
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

  @override
  int get hashCode => hashValues(title, start, end, color);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    return other is Event &&
        other.start == this.start &&
        other.title == this.title &&
        other.end == this.end &&
        other.color == this.color;
  }
}

extension ThemeExtension on ThemeData {
  Color get textColor => this.textTheme.body1.color;
}
