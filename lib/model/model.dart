import 'dart:collection';
import 'dart:convert';

import 'package:countdown/model/extensions.dart';
import 'package:countdown/model/prose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Model {
  List<Event> _events = [];
  List<Event> get events => UnmodifiableListView<Event>(_events);

  bool _shouldUseAltFont = false;
  bool get shouldUseAltFont => _shouldUseAltFont;
  set shouldUseAltFont(bool value) {
    _shouldUseAltFont = value;
    save();
  }

  String get fontFamily => shouldUseAltFont ? 'OpenDyslexic' : 'Inter';

  String prose = Prose.greeting;

  final notificationsManager = FlutterLocalNotificationsPlugin();

  static final Model _instance = Model._internal();
  Model._internal();
  factory Model.instance() => _instance;

  Map<String, dynamic> toJson() =>
      {'shouldUseAltFont': shouldUseAltFont, 'events': _events};

  void save() => SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('hourglassModel', json.encode(toJson())));

  void setProperties(Map<String, dynamic> map) {
    _events = map['events'].map<Event>((x) => Event.fromJson(x)).toList();
    shouldUseAltFont = map['shouldUseAltFont'] ?? false;
  }

  void addEvent(Event e, {int at}) {
    _events.insert(at ?? _events.length, e);

    if (!e.isOver) notificationsManager.scheduleEvent(e);
    save();
  }

  void removeEventAt(int index) {
    final e = _events.removeAt(index);

    save();
    notificationsManager.cancel(e.hashCode);
  }
}

class Circle extends StatelessWidget {
  final double radius;
  final Color color;

  const Circle({Key key, @required this.radius, this.color}) : super(key: key);

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

class Event {
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;

  /// An event is over if the current time is equal to or after the end date
  bool get isOver => end.difference(DateTime.now()) <= Duration(seconds: 0);

  Duration get timeRemaining => DateTime.now().difference(end).abs();

  Event(this.title, {@required this.end, @required this.color})
      : start = DateTime.now(),
        assert(end != null),
        assert(color != null),
        assert(end.isAfter(DateTime.now()));

  /// Deserialize an [Event] instance from a JSON map
  Event.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        color = Color(json['color']),
        start = DateTime.fromMillisecondsSinceEpoch(json['start']),
        end = DateTime.fromMillisecondsSinceEpoch(json['end']);

  /// Serialize this instance to a JSON map
  Map<String, dynamic> toJson() => {
        'title': title,
        'color': color.value,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch
      };

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
