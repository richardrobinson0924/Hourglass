import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'model.dart';

String enumStringOf(dynamic enumOption, {bool titleCase = true}) {
  final split = enumOption.toString().split('.')[1];
  return (titleCase ? split[0].toUpperCase() : split[0]) + split.substring(1);
}

enum TimeUnit { day, hour, minute, second }

extension TimeUnitExt on TimeUnit {
  String get name {
    switch (this) {
      case TimeUnit.day:
        return 'day';
      case TimeUnit.hour:
        return 'hour';
      case TimeUnit.minute:
        return 'min';
      case TimeUnit.second:
        return 'sec';
    }

    return '';
  }
}

extension DurationExt on Duration {
  double operator /(Duration other) => this.inSeconds / other.inSeconds;
}

extension NotifExt on FlutterLocalNotificationsPlugin {
  /// Schedule a notification at the end date of [e] with the id of [e.hashCode]
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
    assert(oldIndex >= 0 && oldIndex < length);
    assert(newIndex >= 0);

    if (newIndex > length) newIndex = length;
    if (oldIndex < newIndex) newIndex--;

    final item = this.removeAt(oldIndex);
    this.insert(newIndex, item);
  }
}

extension E2 on Map<TimeUnit, int> {
  Iterable<String> get mapToString => this.entries.map((entry) {
        final suffix = entry.value == 1 ? '' : 's';
        return '${entry.value} ${entry.key.name}$suffix';
      });
}

extension E on Duration {
  Map<TimeUnit, int> get combined => {
        TimeUnit.day: inDays,
        TimeUnit.hour: inHours.remainder(Duration.hoursPerDay),
        TimeUnit.minute: inMinutes.remainder(Duration.minutesPerHour),
        TimeUnit.second: inSeconds.remainder(Duration.secondsPerMinute)
      };
}

extension ThemeExtension on ThemeData {
  Color get textColor => this.textTheme.body1.color;

  Color get appBackgroundColor =>
      this.brightness == Brightness.dark ? Color(0xFF121212) : Colors.white;
}
