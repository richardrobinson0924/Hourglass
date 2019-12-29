import 'package:countdown/model/model.dart';
import 'package:countdown/ui/radial_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:morpheus/page_routes/morpheus_page_route.dart';

import 'event_page.dart';

class EventsHome extends StatefulWidget {
  final Model model;

  EventsHome({Key key, @required this.model}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EventsHomeState();
}

class _EventsHomeState extends State<EventsHome> {
  Widget buildEmptyScreen() => Center(
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

  Widget buildRow(BuildContext context, int index) {
    final event = widget.model.events[index];

    final transitionKey = GlobalKey();
    final listTileKey = Key(event.hashCode.toString());

    final snackBar = SnackBar(
      content: Text('\'${event.title}\' removed.'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() => widget.model.addEvent(event, index: index));

          Global.saveModel(widget.model);
        },
      ),
    );

    return Dismissible(
      onDismissed: (_) {
        setState(() => widget.model.removeEvent(widget.model.events[index]));
        Global.saveModel(widget.model);

        Scaffold.of(context).showSnackBar(snackBar);
      },
      key: listTileKey,
      child: Card(
        color: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF1C1C1C)
            : Colors.white,
        key: transitionKey,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading: RadialProgressIndicator(
              radius: 20.0,
              color: event.color,
              backgroundColor: event.color.withOpacity(0.25),
              progress: DateTime.now().difference(event.end) /
                  event.start.difference(event.end),
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
                        event: event,
                        configuration: widget.model.configuration))),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.model.events;

    return list.isEmpty
        ? buildEmptyScreen()
        : ListView.separated(
            shrinkWrap: false,
            separatorBuilder: (_, index) => SizedBox(height: 3.0),
            itemBuilder: (context, index) => Container(
                padding: EdgeInsets.symmetric(horizontal: 9.0),
                child: buildRow(context, index)),
            itemCount: list.length);
  }
}
