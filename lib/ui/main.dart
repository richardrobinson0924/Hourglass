import 'dart:async';
import 'dart:convert';

import 'package:countdown/model/prose.dart';
import 'package:countdown/ui/add_event.dart';
import 'package:countdown/ui/event_page.dart';
import 'package:countdown/ui/home_page.dart';
import 'package:countdown/ui/settings.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:morpheus/page_routes/morpheus_page_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var contrast = Theme.of(context).brightness == Brightness.dark
        ? Brightness.dark
        : Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: contrast,
        statusBarIconBrightness: contrast));

    return DynamicTheme(
      defaultBrightness: Theme.of(context).brightness,
      data: (brightness) => ThemeData(
          brightness: brightness,
          primaryColor: Colors.teal, // Color(0xFFBB86FC),
          accentColor: Colors.teal //Color(0xFFBB86FC),
          ),
      themedWidgetBuilder: (context, theme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: theme,
        darkTheme: theme,
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  static const quoteURL = 'http://quotes.rest/qod.json';

  Model _model;
  var isLoading = true;
  Timer _timer;

  Future<dynamic> onSelectNotification(String payload) async {
    final event = Event.fromJson(json.decode(payload));

    Global.instance().notificationsManager.cancel(event.hashCode);

    Navigator.push(
        context,
        MorpheusPageRoute(
            builder: (context) => EventPage(
                  event: event,
                  configuration: _model?.configuration ?? Configuration(),
                )));
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    Prose.fetchFrom([Quote.instance(), Joke.instance(), Joke2.instance()])
        .then((prose) => Global.instance().prose = prose);

    final initSettings = InitializationSettings(
        AndroidInitializationSettings('notification'),
        IOSInitializationSettings());

    Global.instance()
        .notificationsManager
        .initialize(initSettings, onSelectNotification: onSelectNotification);

    SharedPreferences.getInstance().then((prefs) {
      var raw = prefs.getString('hourglassModel');
      setState(() {
        _model = raw == null ? Model.empty() : Model.fromJson(json.decode(raw));
        isLoading = false;
      });
    });

    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      Global.saveModel(_model);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget get loadingView => Container();

  void showSettings(BuildContext context) {
    final oldNotificationsValue = _model.configuration.shouldShowNotifications;

    showModalBottomSheet<void>(
        shape: RoundedRectangleBorder(
            side: BorderSide(),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0))),
        context: context,
        builder: (_) => Settings(model: _model)).then((_) {
      Global.saveModel(_model);

      if (oldNotificationsValue !=
          _model.configuration.shouldShowNotifications) {
        Global.instance().notificationsManager.cancelAll();

        if (_model.configuration.shouldShowNotifications)
          _model.events.forEach((e) => Global.instance()
              .notificationsManager
              .schedule(
                  e.hashCode,
                  'Countdown to ${e.title} Over',
                  'The countdown to ${e.title} is now complete!',
                  e.end,
                  Global.instance().notificationDetails,
                  payload: json.encode(e.toJson())));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DynamicTheme.of(context).brightness == Brightness.dark
          ? Color(0xFF121212)
          : null,
      appBar: AppBar(
        elevation: 2.0,
        brightness: DynamicTheme.of(context).brightness,
        backgroundColor: DynamicTheme.of(context).brightness == Brightness.dark
            ? Color(0xFF121212)
            : Colors.white,
        centerTitle: true,
        title: Text(
          'Your Events',
          style: TextStyle(
              fontFamily: _model?.configuration?.fontFamily ??
                  Configuration().fontFamily,
              color: Theme.of(context).textColor),
        ),
        actions: <Widget>[
          PopupMenuButton<int>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).textColor,
            ),
            onSelected: (_) => showSettings(context),
            itemBuilder: (context) => <PopupMenuEntry<int>>[
              const PopupMenuItem(value: 0, child: Text('Settings'))
            ],
          )
        ],
      ),
      body: isLoading
          ? loadingView
          : Container(
              padding: EdgeInsets.only(top: 10.0),
              child: EventsHome(model: _model)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddEventPage(model: _model),
                fullscreenDialog: true)),
        tooltip: 'Add Event',
        child: Icon(Icons.add),
      ),
    );
  }
}
