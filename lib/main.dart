import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:countdown/add_event.dart';
import 'package:countdown/event_page.dart';
import 'package:countdown/prose.dart';
import 'package:countdown/radial_progress_indicator.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:morpheus/page_routes/morpheus_page_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

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

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    Prose.fetch().then((prose) => Global().prose = prose);

    final initSettings = InitializationSettings(
        AndroidInitializationSettings('app_icon'), IOSInitializationSettings());

    Global().notificationsManager.initialize(initSettings,
        onSelectNotification: (payload) async => Navigator.push(
            context,
            MorpheusPageRoute(
                builder: (context) => EventPage(
                      event: Event.fromJson(json.decode(payload)),
                      configuration: _model?.configuration ?? Configuration(),
                    ))));

    SharedPreferences.getInstance().then((prefs) {
      var raw = prefs.getString('hourglassModel');
      setState(() {
        _model = raw == null ? Model.empty() : Model.fromJson(json.decode(raw));
        isLoading = false;

        assert(_model != null);
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

  Widget get emptyScreen => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Spacer(flex: 4),
            Center(
              child: Theme.of(context).brightness == Brightness.dark
                  ? Image.asset('assets/void.png', width: 250)
                  : Image.asset(
                      'assets/empty_light.png',
                      width: 300.0,
                    ),
            ),
            Padding(padding: EdgeInsets.only(top: 30.0)),
            Text(
              'No events. Add something you\'re looking forward to',
              style: TextStyle(
                  color: Theme.of(context).textColor.withOpacity(0.5)),
            ),
            Spacer(flex: 7)
          ],
        ),
      );

  Widget get loadingView => Container();

  Widget makeRow({@required Event event}) {
    final transitionKey = GlobalKey();
    final listTileKey = Key(event.hashCode.toString());

    return Dismissible(
      onDismissed: (_) {
        setState(() => _model.removeEvent(event));
        Global.saveModel(_model);
      },
      key: listTileKey,
      child: Card(
        color: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF1C1C1C)
            : Colors.white,
        key: transitionKey,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 5.0),
          child: ListTile(
            leading: RadialProgressIndicator(
              radius: 20.0,
              color: event.color,
              backgroundColor: event.color.withOpacity(0.25),
              progress: min(
                  1.0,
                  DateTime.now().difference(event.end).inSeconds /
                      event.start.difference(event.end).inSeconds),
            ),
            key: listTileKey,
            title: Text(event.title),
            subtitle: Text(event.isOver
                ? 'Event Completed'
                : 'in ${event.timeRemaining.toString()}'),
            onTap: () => Navigator.push(
                context,
                MorpheusPageRoute(
                    parentKey: transitionKey,
                    builder: (context) => EventPage(
                        event: event, configuration: _model.configuration))),
          ),
        ),
      ),
    );
  }

  Widget makeEventsList() {
    assert(_model != null);

    final list = _model.events.map((event) => makeRow(event: event)).toList();

    return list.isEmpty
        ? emptyScreen
        : ListView.separated(
            shrinkWrap: false,
            separatorBuilder: (_, index) => SizedBox(height: 3.0),
            itemBuilder: (_, index) => Container(
                padding: EdgeInsets.symmetric(horizontal: 9.0),
                child: list[index]),
            itemCount: list.length);
  }

  void showSettings(BuildContext context) {
    final oldNotificationsValue = _model.configuration.shouldShowNotifications;

    String enumStringOf(dynamic enumOption) {
      final split = enumOption.toString().split('.')[1];
      return split[0].toUpperCase() + split.substring(1);
    }

    showModalBottomSheet<void>(
        shape: RoundedRectangleBorder(
            side: BorderSide(),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0))),
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => Container(
                height: 300.0,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 20.0),
                    ),
                    Center(
                        child: Text(
                      'Settings',
                      style: TextStyle(
                        color: Theme.of(context).textColor.withOpacity(0.75),
                        fontSize: 18.0,
                      ),
                    )),
                    Padding(padding: EdgeInsets.only(top: 10.0)),
                    SwitchListTile(
                        title: Text(
                          'Enable Notifications',
                        ),
                        value: _model.configuration.shouldShowNotifications,
                        onChanged: (value) {
                          setState(() => _model
                              .configuration.shouldShowNotifications = value);
                          this.setState(() => _model
                              .configuration.shouldShowNotifications = value);
                        }),
                    SwitchListTile(
                        title: Text(
                          'Use OpenDyslexic Font',
                        ),
                        value: _model.configuration.shouldUseAltFont,
                        onChanged: (value) {
                          setState(() =>
                              _model.configuration.shouldUseAltFont = value);
                          this.setState(() =>
                              _model.configuration.shouldUseAltFont = value);
                        }),
                    ListTile(
                      title: Text(
                        'Color Theme',
                      ),
                      trailing: DropdownButton<Brightness>(
                        value: DynamicTheme.of(context).brightness,
                        items: Brightness.values
                            .map((color) => DropdownMenuItem<Brightness>(
                                  value: color,
                                  child: Text(enumStringOf(color)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          DynamicTheme.of(context).setBrightness(value);

                          var contrast = value == Brightness.dark
                              ? Brightness.light
                              : Brightness.dark;

                          this.setState(() =>
                              SystemChrome.setSystemUIOverlayStyle(
                                  SystemUiOverlayStyle(
                                      statusBarColor: Colors.transparent,
                                      statusBarBrightness: contrast,
                                      statusBarIconBrightness: contrast)));
                        },
                        underline: Container(),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                    ),
                    Center(
                      child: Text(
                        'Hourglass v1.0. Crafted with care in Canada.',
                        style: TextStyle(
                            fontSize: 14.0,
                            color:
                                Theme.of(context).textColor.withOpacity(0.5)),
                      ),
                    )
                  ],
                ),
              ),
            )).then((_) {
      Global.saveModel(_model);

      if (oldNotificationsValue !=
          _model.configuration.shouldShowNotifications) {
        Global().notificationsManager.cancelAll();

        if (_model.configuration.shouldShowNotifications)
          _model.events.forEach((e) => Global().notificationsManager.schedule(
              e.hashCode,
              'Countdown to ${e.title} Over',
              'The countdown to ${e.title} is now complete!',
              e.end,
              Global().notificationDetails,
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
              color: DynamicTheme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
        ),
        actions: <Widget>[
          PopupMenuButton<int>(
            icon: Icon(
              Icons.more_vert,
              color: DynamicTheme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
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
              padding: EdgeInsets.only(top: 10.0), child: makeEventsList()),
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
