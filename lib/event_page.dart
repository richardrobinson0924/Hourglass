import 'dart:async';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:countdown/fillable_container.dart';
import 'package:flutter/material.dart';
import 'package:aeyrium_sensor/aeyrium_sensor.dart';

import 'model.dart';

class EventPage extends StatefulWidget {
  final Event event;

  EventPage({Key key, this.event}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState(event: event);
}

class _EventPageState extends State<EventPage> {
  final Event event;
  Timer _timer;
  double pitch = 0, roll = 0;

  StreamSubscription<dynamic> _streamSubscriptions;
  ConfettiController _confettiController;

  _EventPageState({Key key, this.event}) : super();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) => setState(() {
      if (event.isOver) timer.cancel();
    }));

    _confettiController = ConfettiController(duration: Duration(seconds: 5));

    _streamSubscriptions = AeyriumSensor.sensorEvents.listen((sensorEvent) => setState(() {
      pitch = sensorEvent.pitch;
      roll = sensorEvent.roll;
    }));
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }

    _confettiController.dispose();

    if (_streamSubscriptions != null) {
      _streamSubscriptions.cancel();
    }

    super.dispose();
  }

  Widget makeTimePart(int part, String label) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: <Widget>[
      Text(
        part.toString().padLeft(2, '0'),
        style: TextStyle(
          fontFamily: 'Inter-ExtraBold',
          fontSize: 80.0,
          fontFeatures: [FontFeature.tabularFigures(), FontFeature.stylisticSet(1)]
        )
      ),
      Padding(padding: EdgeInsets.only(left: 5)),
      Text(label, style: TextStyle(fontFamily: 'Inter-Medium', fontSize: 32.0)),
    ],
  );

  Widget get endOfEventView => Container(
    child: ConfettiWidget(confettiController: _confettiController)
  );

  @override
  Widget build(BuildContext context) {
    var durationToSeconds = (Duration duration) => duration.abs().inSeconds.toDouble();
    var isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: event.isOver ? endOfEventView :  Stack(
        children: <Widget>[
          FillableContainer(
            backgroundColor: Theme.of(context).backgroundColor,
            progressColor: Colors.blue.withOpacity(0.1),
            size: durationToSeconds(event.end.difference(event.start)),
            progress: durationToSeconds(DateTime.now().difference(event.start)),
            pitch: pitch,
            roll: roll,
          ),
          Container(
            padding: EdgeInsets.only(left: 25.0, top: 100.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                makeTimePart(event.timeRemaining.daysRemaining,    'd'),
                makeTimePart(event.timeRemaining.hoursRemaining,   'h'),
                makeTimePart(event.timeRemaining.minutesRemaining, 'm'),
                makeTimePart(event.timeRemaining.secondsRemaining, 's')
              ],
            ),
          ),
          Positioned(
            top: 0.0, left: 0.0, right: 0.0,
            child: AppBar(
              iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
              centerTitle: true,
              elevation: 0.0,
              title: Text('${event.title}', style: TextStyle(color: isDark ? Colors.white : Colors.black),),
              backgroundColor: Colors.transparent,
            )
          )
        ],
      )
    );
  }
}
