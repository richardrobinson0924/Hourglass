import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:countdown/fillable_container.dart';
import 'package:countdown/fluid_view.dart';
import 'package:flutter/material.dart';
import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'package:flutter/physics.dart';

import 'model.dart';

class EventPage extends StatefulWidget {
  final Event event;
  final Configuration configuration;

  EventPage({Key key, this.event, this.configuration}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState(
      event: event,
      configuration: configuration
  );
}

class _EventPageState extends State<EventPage> {
  final Event event;
  final Configuration configuration;

  Timer _timer;
  double roll = 0.0;

  StreamSubscription<SensorEvent> _streamSubscriptions;
  ConfettiController _confettiController;

  _EventPageState({Key key, this.event, this.configuration}) : super();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _timer = Timer.periodic(Duration(seconds: 1), update);
    _confettiController = ConfettiController(duration: Duration(seconds: 5));

    _streamSubscriptions = AeyriumSensor.sensorEvents.listen((sensorEvent) =>
        setState(() => roll = sensorEvent.roll)
    );
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
          fontFamily: configuration.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: configuration.shouldUseAltFont ? 60.0 : 80.0,
          fontFeatures: [FontFeature.tabularFigures(), FontFeature.stylisticSet(1)]
        )
      ),
      Padding(padding: EdgeInsets.only(left: 15)),
      Text(
          label,
          style: TextStyle(
            fontFamily: configuration.fontFamily,
            fontSize: 26.0,
            color: Theme.of(context).textTheme.body1.color.withOpacity(0.5)
          )
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;

    var textTheme = Theme.of(context).textTheme;
    var timeRemaining = event.timeRemaining;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // background
          Container(color: Theme.of(context).backgroundColor),
          // fluid
          Align(
            alignment: Alignment.bottomCenter,
            child: FluidView(
                angle: roll,
                color: event.color,
                progress: Ratio(
                    part: DateTime.now().difference(event.start),
                    total: event.end.difference(event.start)
                ).map((t) => max(t.inSeconds.toDouble(), 0.0))
            ),
          ),
          // text
          Container(
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Spacer(flex: 3),
                makeTimePart(timeRemaining.days,    'days'),
                makeTimePart(timeRemaining.hours,   'hours'),
                makeTimePart(timeRemaining.minutes, 'mins'),
                makeTimePart(timeRemaining.seconds, 'secs'),
                Spacer(flex: 1),
                Center(
                  child: Text(
                    Global().quote.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: textTheme.body1.color.withOpacity(0.5),
                      fontFamily: configuration.fontFamily
                    ),
                  )
                ),
                Spacer(flex: 4)
              ],
            ),
          ),
          // confetti
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
          // app bar
          Positioned(
            top: 0.0, left: 0.0, right: 0.0,
            child: AppBar(
              iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
              centerTitle: true,
              elevation: 0.0,
              title: Text(
                '${event.title}',
                style: TextStyle(
                  fontFamily: configuration.fontFamily,
                  color: textTheme.body1.color
                ),
              ),
              backgroundColor: Colors.transparent,
            )
          )
        ],
      )
    );
  }
}
