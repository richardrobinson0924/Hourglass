import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'package:confetti/confetti.dart';
import 'package:countdown/model/extensions.dart';
import 'package:countdown/ui/widgets/fluid_view.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';

import '../model/model.dart';

class EventPage extends StatefulWidget {
  final Event event;

  EventPage({Key key, @required this.event}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState(event: event);
}

class _EventPageState extends State<EventPage> {
  final Event event;

  Timer _timer;
  double roll = 0.0;

  StreamSubscription<SensorEvent> _streamSubscriptions;

  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 5));

  _EventPageState({Key key, @required this.event}) : super();

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(seconds: 1), update);

    _streamSubscriptions = AeyriumSensor.sensorEvents
        .listen((sensorEvent) => setState(() => roll = sensorEvent.roll));

    if (event.isOver) {
      Model.instance().notificationsManager.cancel(event.hashCode);
    }
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

  Widget makeTimePart(TimeUnit unit) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Padding(padding: EdgeInsets.only(left: 15.0)),
          Text(
              max(0, event.timeRemaining.combined[unit])
                  .toString()
                  .padLeft(2, '0'),
              style: TextStyle(
                  fontFamily: Model.instance().fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: Model.instance().shouldUseAltFont ? 50.0 : 70.0,
                  fontFeatures: [
                    FontFeature.tabularFigures(),
                    FontFeature.stylisticSet(1)
                  ])),
          Padding(padding: EdgeInsets.only(left: 15)),
          Text(unit.name[0],
              style: TextStyle(
                  fontFamily: Model.instance().fontFamily,
                  fontSize: 20.0,
                  color: Theme.of(context).textColor.withOpacity(0.5))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    Padding pad(double padding) =>
        Padding(padding: EdgeInsets.only(top: padding));

    var ratio = DateTime.now().difference(event.start) /
        event.end.difference(event.start);

    if (!ratio.isFinite) ratio = 1.0;

    final fluidView = FluidView(
        angle: roll,
        color: event.color,
        radius: const Radius.circular(10.0),
        progress: min(1.0, ratio));

    final text = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        makeTimePart(TimeUnit.day),
        pad(5.0),
        makeTimePart(TimeUnit.hour),
        pad(5.0),
        makeTimePart(TimeUnit.minute),
        pad(5.0),
        makeTimePart(TimeUnit.second),
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
        event.title,
        style: TextStyle(
            fontFamily: Model.instance().fontFamily,
            color: DynamicTheme.of(context).data.textColor),
      ),
      backgroundColor: Colors.transparent,
    );

    return Scaffold(
        backgroundColor: Theme.of(context).appBackgroundColor,
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
                        child: Semantics(
                            label: 'Time remaining',
                            value: event.timeRemaining.toString(),
                            child: text),
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
                      Model.instance().prose,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14.0,
                          color: Theme.of(context).textColor.withOpacity(0.5),
                          fontFamily: Model.instance().fontFamily),
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
