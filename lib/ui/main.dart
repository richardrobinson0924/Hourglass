import 'dart:async';
import 'dart:convert';

import 'package:countdown/model/prose.dart';
import 'package:countdown/ui/add_event.dart';
import 'package:countdown/ui/event_page.dart';
import 'package:countdown/ui/home_page.dart';
import 'package:countdown/ui/settings.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
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
        primaryColor: Color(0xFFBB86FC),
        accentColor: Color(0xFFBB86FC),
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

  var isLoading = true;
  Timer _timer;

  Future<dynamic> onSelectNotification(String payload) async {
    final event = Event.fromJson(json.decode(payload));

    Model.instance().notificationsManager.cancel(event.hashCode);

    Navigator.push(
        context,
        MorpheusPageRoute(
            builder: (context) => EventPage(
                  event: event,
                  configuration: Model.instance().configuration,
                )));
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    Prose.fetchFrom([Quote.instance(), Joke.instance(), Joke2.instance()])
        .then((prose) => Model.instance().configuration.prose = prose);

    Model.instance().notificationsManager.initialize(
        InitializationSettings(AndroidInitializationSettings('notification'),
            IOSInitializationSettings()),
        onSelectNotification: onSelectNotification);

    SharedPreferences.getInstance().then((prefs) {
      final raw = prefs.getString('hourglassModel');
      setState(() {
        if (raw != null) Model.instance().setProperties(json.decode(raw));
        isLoading = false;
      });
    });

    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      Model.instance().save();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget get loadingView => Container();

  Future<void> showSettings(BuildContext context) async {
    final oldNotificationsValue =
        Model.instance().configuration.shouldShowNotifications;

    await showModalBottomSheet<void>(
        shape: RoundedRectangleBorder(
            side: BorderSide(),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0))),
        context: context,
        builder: (_) => Settings());

    final model = Model.instance();
    model.save();

    if (oldNotificationsValue != model.configuration.shouldShowNotifications) {
      model.notificationsManager.cancelAll();

      if (model.configuration.shouldShowNotifications)
        model.events
            .forEach((e) => model.notificationsManager.scheduleEvent(e));
    }
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
              fontFamily: Model.instance().configuration.fontFamily,
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
          : Container(padding: EdgeInsets.only(top: 10.0), child: EventsHome()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddEventPage(), fullscreenDialog: true)),
        tooltip: 'Add Event',
        child: Icon(Icons.add),
      ),
    );
  }
}
