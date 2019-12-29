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

extension NotifExt on FlutterLocalNotificationsPlugin {
  void scheduleEvent(Event e) {
    final details = NotificationDetails(
        AndroidNotificationDetails(
          'com.richardrobinson.countdown2',
          'Hourglass',
          'The countdown app',
          importance: Importance.Max,
          priority: Priority.High,
        ),
        null);

    schedule(e.hashCode, 'Countdown to ${e.title} Over',
        'The countdown to ${e.title} is now complete!', e.end, details,
        payload: json.encode(e.toJson()));
  }
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
  List<Event> _events = [];
  List<Event> get events => UnmodifiableListView<Event>(_events);

  Configuration _configuration = Configuration();
  Configuration get configuration => _configuration;

  final notificationsManager = FlutterLocalNotificationsPlugin();

  static final Model _instance = Model._internal();
  Model._internal();
  factory Model.instance() => _instance;

  Map<String, dynamic> toJson() =>
      {'configuration': configuration, 'events': _events};

  void save() => SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('hourglassModel', json.encode(toJson())));

  void setProperties(Map<String, dynamic> map) {
    _events = map['events'].map((x) => Event.fromJson(x)).toList();
    _configuration = Configuration.fromJson(map['configuration']);
  }

  void addEvent(Event e, {int index}) {
    _events.insert(index ?? _events.length, e);

    if (configuration.shouldShowNotifications && !e.isOver) {
      notificationsManager.scheduleEvent(e);
    }

    save();
  }

  void removeEvent(Event e) {
    _events.remove(e);

    save();
    notificationsManager.cancel(e.hashCode);
  }
}

class Configuration {
  bool shouldShowNotifications;
  bool shouldUseAltFont;
  String prose = Prose.greeting;

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
      : seconds = totalDuration.inSeconds.remainder(Duration.secondsPerMinute),
        minutes = totalDuration.inMinutes.remainder(Duration.minutesPerHour),
        hours = totalDuration.inHours.remainder(Duration.hoursPerDay),
        days = totalDuration.inDays;

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
