import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

  StreamSubscription<SensorEvent> _streamSubscriptions;
  ConfettiController _confettiController;

  _EventPageState({Key key, this.event}) : super();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _timer = Timer.periodic(Duration(seconds: 1), update);
    _confettiController = ConfettiController(duration: Duration(seconds: 5));

    _streamSubscriptions = AeyriumSensor.sensorEvents.listen((sensorEvent) => setState(() {
      pitch = sensorEvent.pitch;
      roll = sensorEvent.roll;
    }));
  }

  void update(Timer timer) {
    if (event.isOver) {
      _confettiController.play();
      timer.cancel();
    }

    setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
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
      Padding(padding: EdgeInsets.only(left: 15.0)),
      Text(
        event.isOver ? '00' : part.toString().padLeft(2, '0'),
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

  @override
  Widget build(BuildContext context) {
    var durationToSeconds = (Duration duration) => duration.abs().inSeconds.toDouble();
    var isDark = Theme.of(context).brightness == Brightness.dark;

    var textTheme = Theme.of(context).textTheme;
    var timeRemaining = event.timeRemaining;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _confettiController.play(),
      ),
      body: Stack(
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
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Spacer(flex: 3),
                makeTimePart(timeRemaining.days,    'd'),
                makeTimePart(timeRemaining.hours,   'h'),
                makeTimePart(timeRemaining.minutes, 'm'),
                makeTimePart(timeRemaining.seconds, 's'),
                Spacer(flex: 1),
                Center(
                  child: Text(
                    Global().quote.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: textTheme.body1.color.withOpacity(0.5),
                      fontFamily: 'Inter-Regular'
                    ),
                  )
                ),
                Spacer(flex: 4)
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.6,
              minimumSize: const Size(10, 10),
              maximumSize: const Size(30, 30),
              numberOfParticles: 1,
            )
          ),
          Positioned(
            top: 0.0, left: 0.0, right: 0.0,
            child: AppBar(
              iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
              centerTitle: true,
              elevation: 0.0,
              title: Text('${event.title}', style: TextStyle(fontFamily: 'Inter-Regular')),
              backgroundColor: Colors.transparent,
            )
          )
        ],
      )
    );
  }
}
