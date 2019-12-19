import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:countdown/add_event.dart';
import 'package:countdown/app_bar_divider.dart';
import 'package:countdown/event_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:morpheus/page_routes/morpheus_page_route.dart';
import 'package:http/http.dart' as http;


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
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        backgroundColor: Colors.black
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const quoteURL = 'http://quotes.rest/qod.json';

  var _model = Model();
  var isLoading = true;
  Timer _timer;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();

    _model.initialize().then((_) => setState(() => isLoading = false));
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
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget get emptyScreen => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Spacer(flex: 1),
        Center(
          child: Theme.of(context).brightness == Brightness.dark
            ? Image.asset('assets/void.png', width: 250)
            : Image.asset('assets/undraw_thoughts_e49y.png'),
        ),
        Padding(padding: EdgeInsets.only(top: 30.0),),
        Text('No events. Add something you\'re looking forward to'),
        Spacer(flex: 3,)
      ],
    ),
  );

  Widget get loadingView => Container();

  Dismissible makeRow({@required Key key, @required Event event}) => Dismissible(
    direction: DismissDirection.endToStart,
    background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 25.0),
        child: Icon(Icons.delete, color: Colors.white)
    ),
    key: key,
    confirmDismiss: (direction) async => await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: <Widget>[
          FlatButton(
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FlatButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() => _model.removeEvent(event));
              Navigator.of(context).pop();
            },
          )
        ],
      )
    ),
    child: ListTile(
      title: Text(event.title),
      subtitle: Text(event.isOver ? 'Event Completed' : event.timeRemaining.toString()),
      onTap: () => Navigator.push(
        context,
        MorpheusPageRoute(
          parentKey: key,
          builder: (context) => EventPage(event: event)
        )
      ),
    ),
  );

  bool shouldShowDivider = true;
  bool shouldShowIllustration = true;

  Widget get eventsList {
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
            color: Theme.of(context).textTheme.body1.color,
            fontFamily: 'Inter-Regular'
        ),
      ),
      children: completedEvents,
    );

    final possibleDivider = shouldShowDivider
        ? Divider(height: 0, color: (isDark ? Colors.white : Colors.black).withOpacity(0.4))
        : Container();

    return nonCompletedEvents.isEmpty
      ? Column(children: [
          expansionTile,
          possibleDivider,
          shouldShowIllustration || completedEvents.isEmpty ? emptyScreen : Container()
        ])
      : ListView(children: [
          expansionTile,
          possibleDivider,
          ...nonCompletedEvents
        ]);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
        centerTitle: true,
        bottom: shouldShowDivider ? AppBarDivider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.25)) : null,
        title: Text(
          'Your Events',
          style: TextStyle(
              fontFamily: 'Inter-Regular',
              color: Theme.of(context).textTheme.body1.color
          ),
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: null
          )
        ],
      ),
      body: isLoading ? loadingView : eventsList,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddEventPage(model: _model),
                fullscreenDialog: true
            )
        ),
        tooltip: 'Add Event',
        child: Icon(Icons.add),
      ),
    );
  }
}

