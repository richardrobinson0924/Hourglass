import 'dart:async';
import 'dart:convert';

import 'package:countdown/add_event.dart';
import 'package:countdown/app_bar_divider.dart';
import 'package:countdown/event_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:morpheus/page_routes/morpheus_page_route.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        backgroundColor: Colors.white,
      ),
      darkTheme:
          ThemeData(brightness: Brightness.dark, backgroundColor: Colors.black),
      home: MyHomePage(),
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

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    final initSettings = InitializationSettings(
        AndroidInitializationSettings('app_icon'), IOSInitializationSettings());

    Global().notificationsManager.initialize(initSettings,
        onSelectNotification: (payload) async => Navigator.push(
            context,
            MorpheusPageRoute(
                builder: (context) =>
                    EventPage(event: Event.fromJson(json.decode(payload))))));

    SharedPreferences.getInstance().then((prefs) {
      var raw = prefs.getString('hourglassModel');
      setState(() {
        _model = Model.fromJson(raw == null ? null : json.decode(raw));
        isLoading = false;

        assert(_model != null);
      });

      print(raw);
    });

    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));

    http.get(quoteURL).then((response) {
      if (response.statusCode == 200) {
        Global().quote = Quote.fromJson(json.decode(response.body));
      } else {
        print('Failed with status code ${response.statusCode}');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      var prefs = await SharedPreferences.getInstance();
      prefs.setString('hourglassModel', json.encode(_model.toJson()));
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget get emptyScreen => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Spacer(flex: 1),
            Center(
              child: isDark
                  ? Image.asset('assets/void.png', width: 250)
                  : Image.asset('assets/undraw_thoughts_e49y.png'),
            ),
            Padding(padding: EdgeInsets.only(top: 30.0)),
            Text('No events. Add something you\'re looking forward to'),
            Spacer(flex: 3)
          ],
        ),
      );

  Widget get loadingView => Container();

  Dismissible makeRow({@required Key key, @required Event event}) =>
      Dismissible(
        direction: DismissDirection.endToStart,
        background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 25.0),
            child: Icon(Icons.delete, color: Colors.white)),
        key: key,
        confirmDismiss: (direction) async => await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  content:
                      Text('Are you sure you want to delete "${event.title}"?'),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    FlatButton(
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        setState(() => _model.removeEvent(event));
                        Global.saveModel(_model);
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                )),
        child: ListTile(
          title: Text(
            event.title,
            style: TextStyle(fontFamily: _model.configuration.fontFamily),
          ),
          subtitle: Text(
            event.isOver ? 'Event Completed' : event.timeRemaining.toString(),
            style: TextStyle(fontFamily: _model.configuration.fontFamily),
          ),
          onTap: () => Navigator.push(
              context,
              MorpheusPageRoute(
                  parentKey: key,
                  builder: (context) => EventPage(
                      event: event, configuration: _model.configuration))),
        ),
      );

  bool shouldShowDivider = true;
  bool shouldShowIllustration = true;

  Widget get eventsList {
    assert(_model != null);

    final completedEvents = _model.events
        .where((event) => event.isOver)
        .map((event) => makeRow(key: GlobalKey(), event: event))
        .toList();

    final nonCompletedEvents = _model.events
        .where((event) => !event.isOver)
        .map((event) => makeRow(key: GlobalKey(), event: event))
        .toList();

    final expansionTile = ExpansionTile(
      onExpansionChanged: (isExpanded) => setState(() {
        shouldShowDivider = !isExpanded;
        shouldShowIllustration = !isExpanded;
      }),
      initiallyExpanded: false,
      title: Text(
        'Completed Events (${completedEvents.length})',
        style: TextStyle(
          fontFamily: _model.configuration.fontFamily,
        ),
      ),
      children: completedEvents,
    );

    final possibleDivider = shouldShowDivider
        ? Divider(height: 0, color: textColor.withOpacity(0.4))
        : Container();

    return nonCompletedEvents.isEmpty
        ? Column(children: [
            expansionTile,
            possibleDivider,
            shouldShowIllustration || completedEvents.isEmpty
                ? emptyScreen
                : Container()
          ])
        : ListView(
            children: [expansionTile, possibleDivider, ...nonCompletedEvents]);
  }

  void showSettings(BuildContext context) => showModalBottomSheet<void>(
      shape: RoundedRectangleBorder(
          side: BorderSide(),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))),
      context: context,
      builder: (context) => StatefulBuilder(
            builder: (context, setState) => Container(
              height: 260.0,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 20.0),
                  ),
                  Center(
                      child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .title
                          .color
                          .withOpacity(0.75),
                      fontSize: 18.0,
                    ),
                  )),
                  Padding(padding: EdgeInsets.only(top: 10.0)),
                  SwitchListTile(
                      title: Text(
                        'Enable Notifications',
                        style: TextStyle(
                            fontFamily: _model.configuration.fontFamily),
                      ),
                      value: _model.configuration.shouldShowNotifications,
                      onChanged: (value) {
                        Global().notificationsManager.cancelAll();

                        if (value)
                          _model.events.forEach((e) => Global()
                              .notificationsManager
                              .schedule(
                                  e.hashCode,
                                  'Countdown to ${e.title} Over',
                                  'The countdown to ${e.title} is now complete!',
                                  e.end,
                                  Global().notificationDetails,
                                  payload: json.encode(e.toJson())));

                        setState(() => _model
                            .configuration.shouldShowNotifications = value);
                        this.setState(() => _model
                            .configuration.shouldShowNotifications = value);
                      }),
                  SwitchListTile(
                      title: Text(
                        'Use OpenDyslexic Font',
                        style: TextStyle(
                            fontFamily: _model.configuration.fontFamily),
                      ),
                      value: _model.configuration.shouldUseAltFont,
                      onChanged: (value) {
                        setState(() =>
                            _model.configuration.shouldUseAltFont = value);
                        this.setState(() =>
                            _model.configuration.shouldUseAltFont = value);
                      }),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                  ),
                  Center(
                    child: Text(
                      'Hourglass v1.0. Crafted with care in Canada.',
                      style: TextStyle(
                          fontSize: 14.0,
                          fontFamily: _model.configuration.fontFamily,
                          color: textColor.withOpacity(0.5)),
                    ),
                  )
                ],
              ),
            ),
          ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
        centerTitle: true,
        bottom: shouldShowDivider
            ? AppBarDivider(color: textColor.withOpacity(0.25))
            : null,
        title: Text(
          'Your Events',
          style: TextStyle(
              fontFamily: _model?.configuration?.fontFamily ??
                  Configuration().fontFamily,
              color: textColor),
        ),
        actions: <Widget>[
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (_) => showSettings(context),
            itemBuilder: (context) => <PopupMenuEntry<int>>[
              const PopupMenuItem(value: 0, child: Text('Settings'))
            ],
          )
        ],
      ),
      body: isLoading ? loadingView : eventsList,
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
