import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'model.dart';

String enumStringOf(dynamic enumOption, {bool titleCase = true}) {
  final split = enumOption.toString().split('.')[1];
  return (titleCase ? split[0].toUpperCase() : split[0]) + split.substring(1);
}

class Unit {
  static const second = Unit._('sec', 'second');
  static const minute = Unit._('min', 'minute');
  static const hour = Unit._('hr', 'hour');
  static const day = Unit._('day', 'day');

  final String abbreviated;
  final String full;

  const Unit._(this.abbreviated, this.full);
}

class CompoundedDuration {
  final Map<Unit, int> _map;

  CompoundedDuration.converted(Duration other)
      : _map = {
          Unit.day: other.inDays,
          Unit.hour: other.inHours.remainder(24),
          Unit.minute: other.inMinutes.remainder(60),
          Unit.second: other.inSeconds.remainder(60)
        };

  int operator [](Unit unit) => _map[unit];

  @override
  String toString({bool abbreviated = false}) => _map.entries.map((entry) {
        final suffix = (entry.value == 1) ? '' : 's';
        final unit = abbreviated ? entry.key.abbreviated : entry.key.full;

        return '${entry.value} $unit$suffix';
      }).join(', ');
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

extension E on Duration {
  CompoundedDuration get compounded => CompoundedDuration.converted(this);
}

extension ThemeExtension on ThemeData {
  Color get textColor => this.textTheme.body1.color;

  Color get appBackgroundColor =>
      this.brightness == Brightness.dark ? Color(0xFF121212) : Colors.white;
}
