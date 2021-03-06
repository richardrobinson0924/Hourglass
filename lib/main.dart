import 'dart:async';
import 'dart:convert';

import 'package:countdown/model/prose.dart';
import 'package:countdown/ui/add_event.dart';
import 'package:countdown/ui/event_page.dart';
import 'package:countdown/ui/settings.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:morpheus/page_routes/morpheus_page_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/extensions.dart';
import 'model/model.dart';
import 'ui/widgets/radial_progress_indicator.dart';

void main() => runApp(MyApp());

class ScreenArguments {
  static const root = '/';
  static const add = '/add';
  static const eventPage = '/event';

  final Event event;

  ScreenArguments(this.event);
}

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
        primaryColor: Colors.teal,
        accentColor: Colors.teal,
      ),
      themedWidgetBuilder: (context, theme) => MaterialApp(
        initialRoute: ScreenArguments.root,
        routes: {
          ScreenArguments.root: (_) => MyHomePage(),
          ScreenArguments.add: (_) => AddEventPage(),
          ScreenArguments.eventPage: (_) => EventPage()
        },
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: theme,
        darkTheme: theme,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var isLoading = true;
  Timer _timer;

  _MyHomePageState() : super();

  Future<dynamic> onSelectNotification(String payload) async {
    final event = Event.fromJson(json.decode(payload));

    Model.instance().cfg.notificationsManager.cancel(event.hashCode);

    Navigator.push(
        context, MorpheusPageRoute(builder: (_) => EventPage(event: event)));
  }

  @override
  void initState() {
    super.initState();

    platform.setMethodCallHandler((call) {
      switch (call.method) {
        case Methods.addEvent:
          {
            Future.delayed(Duration.zero,
                () => Navigator.pushNamed(context, ScreenArguments.add));
            break;
          }

        case Methods.launchEventPage:
          {
            final data = call.arguments;

            print(data);

            if (data != null && data >= 0) {
              Navigator.pushNamed(context, ScreenArguments.eventPage,
                  arguments: ScreenArguments(Model.instance().events[data]));
            }
          }
      }

      return null;
    });

    Prose.fetchFrom([Quote.instance(), Joke.instance(), Joke2.instance()])
        .then((prose) => Model.instance().cfg.prose = prose);

    Model.instance().cfg.notificationsManager.initialize(
        InitializationSettings(AndroidInitializationSettings('notification'),
            IOSInitializationSettings()),
        onSelectNotification: onSelectNotification);

    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));

    SharedPreferences.getInstance().then((prefs) {
      final raw = prefs.getString('hourglassModel');
      setState(() {
        if (raw != null) Model.instance().setProperties(json.decode(raw));
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget get loadingView => Container();

  Future<void> showSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
        shape: RoundedRectangleBorder(
            side: BorderSide(),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0))),
        context: context,
        builder: (_) => Settings());

    final model = Model.instance();
    model.save();
  }

  Widget buildEmptyScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Spacer(flex: 4),
          Center(
            child: Theme.of(context).brightness == Brightness.dark
                ? Image.asset(
                    'assets/void.png',
                    width: 250,
                    semanticLabel: 'No events.',
                  )
                : Image.asset(
                    'assets/empty_light.png',
                    width: 300.0,
                    semanticLabel: 'No events.',
                  ),
          ),
          Padding(padding: EdgeInsets.only(top: 30.0)),
          Text(
            'No events. Add something you\'re looking forward to',
            style:
                TextStyle(color: Theme.of(context).textColor.withOpacity(0.5)),
          ),
          Spacer(flex: 7)
        ],
      ),
    );
  }

  Widget buildRow(BuildContext context, int index) {
    final event = Model.instance().events[index];

    final transitionKey = GlobalKey();
    final listTileKey = Key(event.hashCode.toString());

    final snackBar = SnackBar(
      content: Text('\'${event.title}\' removed.'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () =>
            setState(() => Model.instance().addEvent(event, at: index)),
      ),
    );

    double getProgress() =>
        DateTime.now().difference(event.end) /
        event.start.difference(event.end);

    return Dismissible(
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.green.shade400,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) {
          setState(() => Model.instance().removeEventAt(index));
          Scaffold.of(context).showSnackBar(snackBar);
        },
        key: listTileKey,
        child: Material(
          color: Theme.of(context).appBackgroundColor,
          key: transitionKey,
          child: ListTile(
            leading: RadialProgressIndicator(
              radius: 20.0,
              color: event.color,
              backgroundColor: event.color.withOpacity(0.25),
              progress: getProgress(),
            ),
            key: listTileKey,
            title: Text(event.title),
            subtitle: Text(event.isOver
                ? 'Event Completed'
                : 'in ${event.timeRemaining.compounded.toString(abbreviated: true)}'),
            onTap: () => Navigator.push(
              context,
              MorpheusPageRoute(
                  parentKey: transitionKey,
                  builder: (_) => EventPage(event: event)),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final list = Model.instance().events;

    final themeData = Theme.of(context).copyWith(
        textTheme: Theme.of(context)
            .textTheme
            .apply(fontFamily: Model.instance().cfg.fontFamily));

    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: Theme.of(context).appBackgroundColor,
        appBar: AppBar(
          bottom: AppBarDivider(height: 1.0),
          elevation: 0.0,
          brightness: DynamicTheme.of(context).brightness,
          backgroundColor: Theme.of(context).appBackgroundColor,
          centerTitle: true,
          title: Text(
            'Your Events',
            style: TextStyle(
                color: Theme.of(context).textColor,
                fontFamily: Model.instance().cfg.fontFamily),
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
            ? Container()
            : list.isEmpty
                ? buildEmptyScreen(context)
                : ListView.separated(
                    padding: EdgeInsets.only(top: 10.0),
                    separatorBuilder: (_, __) => Divider(height: 16.0),
                    itemBuilder: (context, index) => buildRow(context, index),
                    itemCount: list.length),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddEventPage(),
                  fullscreenDialog: true)),
          tooltip: 'Add Event',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class AppBarDivider extends Divider implements PreferredSizeWidget {
  AppBarDivider(
      {Key key, @required double height, double indent = 0.0, Color color})
      : assert(height >= 0.0),
        super(key: key, height: height, indent: indent, color: color);

  @override
  Size get preferredSize => Size.fromHeight(height);
}
