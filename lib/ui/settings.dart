import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/model.dart';

class Settings extends StatefulWidget {
  final Model model;

  Settings({@required this.model});

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String enumStringOf(dynamic enumOption) {
    final split = enumOption.toString().split('.')[1];
    return split[0].toUpperCase() + split.substring(1);
  }

  @override
  Widget build(BuildContext context) => Container(
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
                value: widget.model.configuration.shouldShowNotifications,
                onChanged: (value) {
                  setState(() => widget
                      .model.configuration.shouldShowNotifications = value);
                }),
            SwitchListTile(
                title: Text(
                  'Use OpenDyslexic Font',
                ),
                value: widget.model.configuration.shouldUseAltFont,
                onChanged: (value) {
                  setState(() =>
                      widget.model.configuration.shouldUseAltFont = value);
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

                  this.setState(() => SystemChrome.setSystemUIOverlayStyle(
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
                    color: Theme.of(context).textColor.withOpacity(0.5)),
              ),
            )
          ],
        ),
      );
}
