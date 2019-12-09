import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  _EventPageState({Key key, this.event}) : super();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget makeTimePart(int part, String label) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: <Widget>[
      Text(
        part.toString().padLeft(2, '0'),
        style: TextStyle(
          fontFamily: 'Inter-Bold',
          fontSize: 80.0,
          fontFeatures: [FontFeature.tabularFigures(), FontFeature.stylisticSet(1)]
        )
      ),
      Padding(padding: EdgeInsets.only(left: 5)),
      Text(label, style: TextStyle(fontFamily: 'Inter-Regular', fontSize: 32.0)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 0.0,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('${event.title}', style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.only(left: 25.0, top: 30.0),
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
    );
  }
}
