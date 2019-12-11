import 'dart:async';
import 'dart:convert';

import 'package:countdown/add_event.dart';
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
  var _internalIsLoading = false;

  get isLoading => _internalIsLoading;
  set isLoading(bool value) => setState(() => _internalIsLoading = value);

  Timer _timer;

  @override
  void initState() {
    super.initState();
    isLoading = true;

    http.get(quoteURL).then((response) {
      if (response.statusCode == 200) {
        Global().quote = Quote.fromJson(json.decode(response.body));
      } else {
        print('Failed with status code ${response.statusCode}');
      }
    });

    _model.events.syncRemoveWhere((event) => event.isOver);
    isLoading = false;

    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {
      _model.events.syncRemoveWhere((event) => event.isOver);
    }));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget loadingIndicator = const Center(
    child: CircularProgressIndicator(backgroundColor: Colors.cyan)
  );

  Widget eventsList() => ListView.builder(
    itemCount: _model.events.length,
    itemBuilder: (context, index) {
      final event = _model.events[index];
      final key = GlobalKey();

      return Dismissible(
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
                  setState(() => _model.events.remove(event));
                  Navigator.of(context).pop();
                },
              )
            ],
          )
        ),
        child: ListTile(
          title: Text(event.title),
          subtitle: Text(event.timeRemaining.toString()),
          onTap: () => Navigator.push(
            context,
            MorpheusPageRoute(
              parentKey: key,
              builder: (context) => EventPage(event: event)
            )
          ),
        ),
      );
    }
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: isLoading ? loadingIndicator : eventsList(),
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
