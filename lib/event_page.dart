import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'package:confetti/confetti.dart';
import 'package:countdown/fluid_view.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'model.dart';

class EventPage extends StatefulWidget {
  final Event event;
  final Configuration configuration;

  EventPage({Key key, this.event, this.configuration}) : super(key: key);

  @override
  _EventPageState createState() =>
      _EventPageState(event: event, configuration: configuration);
}

class _EventPageState extends State<EventPage> {
  final Event event;
  final Configuration configuration;

  Timer _timer;
  double roll = 0.0;

  StreamSubscription<SensorEvent> _streamSubscriptions;

  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 5));

  _EventPageState({Key key, this.event, this.configuration}) : super();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _timer = Timer.periodic(Duration(seconds: 1), update);

    _streamSubscriptions = AeyriumSensor.sensorEvents
        .listen((sensorEvent) => setState(() => roll = sensorEvent.roll));
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
          Text(event.isOver ? '00' : part.toString().padLeft(2, '0'),
              style: TextStyle(
                  fontFamily: configuration.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: configuration.shouldUseAltFont ? 40.0 : 70.0,
                  fontFeatures: [
                    FontFeature.tabularFigures(),
                    FontFeature.stylisticSet(1)
                  ])),
          Padding(padding: EdgeInsets.only(left: 15)),
          Text(label,
              style: TextStyle(
                  fontFamily: configuration.fontFamily,
                  fontSize: 20.0,
                  color: Theme.of(context).textColor.withOpacity(0.5))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final timeRemaining = event.timeRemaining;

    Padding pad(double padding) =>
        Padding(padding: EdgeInsets.only(top: padding));

    var ratio = DateTime.now().difference(event.start).inSeconds /
        event.end.difference(event.start).inSeconds;

    if (!ratio.isFinite) ratio = 1.0;

    final fluidView = FluidView(
        angle: roll,
        color: event.color,
        radius: const Radius.circular(10.0),
        progress: min(1.0, ratio));

    final text = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        makeTimePart(timeRemaining.days, 'd'),
        pad(5.0),
        makeTimePart(timeRemaining.hours, 'h'),
        pad(5.0),
        makeTimePart(timeRemaining.minutes, 'm'),
        pad(5.0),
        makeTimePart(timeRemaining.seconds, 's'),
      ],
    );

    final confetti = ConfettiWidget(
      confettiController: _confettiController,
      blastDirection: pi / 2,
      emissionFrequency: 0.6,
      minimumSize: const Size(10, 10),
      maximumSize: const Size(30, 30),
      numberOfParticles: 1,
    );

    final appBar = AppBar(
      brightness: DynamicTheme.of(context).brightness,
      iconTheme: IconThemeData(),
      centerTitle: true,
      elevation: 0.0,
      title: Text(
        '${event.title}',
        style: TextStyle(
            fontFamily: configuration.fontFamily,
            color: DynamicTheme.of(context).data.textColor),
      ),
      backgroundColor: Colors.transparent,
    );

    return Scaffold(
        backgroundColor: DynamicTheme.of(context).brightness == Brightness.dark
            ? Color(0xFF121212)
            : Colors.white,
        body: Stack(
          children: <Widget>[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(left: 15.0),
                      ),
                      Expanded(
                        child: text,
                      ),
                      Container(
                          height: 335.0,
                          width: 85.0,
                          child: Material(
                            borderRadius: BorderRadius.circular(10.0),
                            elevation: 8.0,
                            child: DecoratedBox(
                                child: fluidView,
                                decoration: BoxDecoration(
                                    color: event.color.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10.0))),
                          )),
                      Padding(
                        padding: EdgeInsets.only(right: 45.0),
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 80.0),
                  ),
                  Center(
                      child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text(
                      Global().quote.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14.0,
                          color: Theme.of(context).textColor.withOpacity(0.5),
                          fontFamily: configuration.fontFamily),
                    ),
                  )),
                ],
              ),
            ),
            Align(alignment: Alignment.topCenter, child: confetti),
            Positioned(top: 0.0, left: 0.0, right: 0.0, child: appBar)
          ],
        ));
  }
}
