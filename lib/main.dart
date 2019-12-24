import 'dart:async';
import 'dart:convert';

import 'package:countdown/CustomExpansionTile.dart';
import 'package:countdown/add_event.dart';
import 'package:countdown/app_bar_divider.dart';
import 'package:countdown/event_page.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:morpheus/page_routes/morpheus_page_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      defaultBrightness: Theme.of(context).brightness,
      data: (brightness) => ThemeData(
        brightness: brightness,
        primarySwatch: Colors.pink,
        accentColor: Colors.pink,
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
        _model = raw == null ? Model.empty() : Model.fromJson(json.decode(raw));
        isLoading = false;

        assert(_model != null);
      });
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
            Spacer(flex: 2),
            Center(
              child: Theme.of(context).brightness == Brightness.dark
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

  Future<bool> buildDismissDialog(Event event) => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            content: Text('Are you sure you want to delete "${event.title}"?'),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              FlatButton(
                child: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              )
            ],
          ));

  Widget makeRow({@required Event event}) {
    var key = Key(event.start.toIso8601String());

    return Dismissible(
      direction: DismissDirection.endToStart,
      background: Container(
          color: Colors.blueAccent,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 25.0),
          child: Icon(Icons.delete, color: Colors.white)),
      key: key,
      onDismissed: (_) {
        setState(() => _model.removeEvent(event));
        Global.saveModel(_model);
      },
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
  }

  bool shouldShowDivider = true;
  bool shouldShowIllustration = true;

  var isExpansionTileExpanded = false;

  Widget makeEventsList() {
    assert(_model != null);

    final completedEvents = _model.events
        .where((event) => event.isOver)
        .map((event) => makeRow(event: event))
        .toList();

    final inProgressEvents = _model.events
        .where((event) => !event.isOver)
        .map((event) => makeRow(event: event))
        .toList();

    final completedEventsWidget = CustomExpansionTile(
      onExpansionChanged: (isExpanded) {
        setState(() {
          isExpansionTileExpanded = isExpanded;
        });
      },
      initiallyExpanded: false,
      title: Text(
        'Completed Events (${completedEvents.length})',
        style: TextStyle(fontFamily: _model.configuration.fontFamily),
      ),
      children: completedEvents,
    );

    List<Widget> list = List<Widget>()..addAll(inProgressEvents);

    if (completedEvents.isNotEmpty) {
      list.add(Container(
        height: 20.0,
      ));
      list.add(completedEventsWidget);
    }

    return Stack(
      children: <Widget>[
        (inProgressEvents.isEmpty &&
                (completedEvents.isEmpty || !isExpansionTileExpanded))
            ? emptyScreen
            : Container(),
        ListView.separated(
            shrinkWrap: true,
            itemBuilder: (_, index) => list[index],
            separatorBuilder: (_, index) => Divider(
                  color: Theme.of(context).dividerColor,
                  height: 0.0,
                  thickness: 1.0,
                ),
            itemCount: list.length)
      ],
    );
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
                        color: Theme.of(context)
                            .textTheme
                            .body1
                            .color
                            .withOpacity(0.75),
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
                        onChanged: (value) =>
                            DynamicTheme.of(context).setBrightness(value),
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
                            color: Theme.of(context)
                                .textTheme
                                .body1
                                .color
                                .withOpacity(0.5)),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
        bottom: shouldShowDivider
            ? AppBarDivider(
                color: DynamicTheme.of(context).data.dividerColor,
              )
            : null,
        title: Text(
          'Your Events',
          style: TextStyle(
              fontFamily: _model?.configuration?.fontFamily ??
                  Configuration().fontFamily),
        ),
        actions: <Widget>[
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert),
            onSelected: (_) => showSettings(context),
            itemBuilder: (context) => <PopupMenuEntry<int>>[
              const PopupMenuItem(value: 0, child: Text('Settings'))
            ],
          )
        ],
      ),
      body: isLoading ? loadingView : makeEventsList(),
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
