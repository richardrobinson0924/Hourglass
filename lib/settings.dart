import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  Default, Dark, Light
}

extension AppThemeExtension on AppTheme {
  String get name {
    switch (this) {
      case AppTheme.Default : return 'System Default';
      case AppTheme.Dark    : return 'The Dark Side ';
      case AppTheme.Light   : return 'The Light Side';
      default: return '';
    }
  }
}

enum Font {
  Default, Inter, OpenDyslexic
}

extension FontExtension on Font {
  String get name {
    switch (this) {
      case Font.Default      : return 'System Default';
      case Font.Inter        : return 'Inter         ';
      case Font.OpenDyslexic : return 'OpenDyslexic  ';
      default: return '';
    }
  }
}

class Configuration {
  final SharedPreferences _prefs;

  bool _shouldShowNotifications;
  bool get shouldShowNotifications => _shouldShowNotifications;

  set shouldShowNotifications(bool value) {
    _shouldShowNotifications = value;
    _prefs.setBool('shouldShowNotifications', value);
  }

  AppTheme _appTheme;
  AppTheme get appTheme => _appTheme;

  set appTheme(AppTheme appTheme) {
    _appTheme = appTheme;
    _prefs.setInt('theme', AppTheme.values.indexOf(appTheme));
  }

  Font _font;
  Font get font => _font;

  set font(Font font) {
    _font = font;
    _prefs.setInt('font', Font.values.indexOf(font));
  }

  Configuration(this._prefs) {
    _shouldShowNotifications = _prefs.getBool('shouldShowNotifications') ?? true;
    _appTheme = AppTheme.values[_prefs.getInt('theme') ?? 0];
    _font = Font.values[_prefs.getInt('font') ?? 0];
  }
}

class SettingsPage extends StatefulWidget {
  final Configuration configuration;

  SettingsPage({Key key, @required this.configuration}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState(configuration: configuration);
}

class _SettingsPageState extends State<SettingsPage> {
  final Configuration configuration;

  _SettingsPageState({Key key, @required this.configuration}) : super();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: Text('Enable Notifications'),
            value: configuration.shouldShowNotifications,
            onChanged: (value) => configuration.shouldShowNotifications = value
          ),
          ListTile(
            leading: const Icon(Icons.brightness_4),
            title: Text('Theme'),
////            trailing: DropdownButton<AppTheme>(
////              value: configuration.appTheme,
////              onChanged: (value) => setState(() => configuration.appTheme = value),
////              items: AppTheme.values.map((value) => DropdownMenuItem<AppTheme>(
////                value: value,
////                child: Text(value.toString().split('.')[1])
////              )).toList()
////            )
          ),
          ListTile(
            title: const Text('The Dark Side'),
            leading: Radio<AppTheme>(
              value: AppTheme.Dark,
              groupValue: configuration.appTheme,
              onChanged: (value) => setState(() => configuration.appTheme = value),
            ),
          ),
          ListTile(
            title: const Text('The Light Side'),
            leading: Radio<AppTheme>(
              value: AppTheme.Light,
              groupValue: configuration.appTheme,
              onChanged: (value) => setState(() => configuration.appTheme = value),
            ),
          ),
          ListTile(
            title: const Text('VentaBlack'),
            leading: Radio<AppTheme>(
              value: AppTheme.Default,
              groupValue: configuration.appTheme,
              onChanged: (value) => setState(() => configuration.appTheme = value),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.font_download),
            title: Text('Font'),
            trailing: DropdownButton<Font>(
                value: configuration.font,
                onChanged: (value) => setState(() => configuration.font = value),
                items: Font.values.map((value) => DropdownMenuItem<Font>(
                  value: value,
                  child: Text(value.toString().split('.')[1])
                )).toList()
            )
          )
        ]
      )
    );
  }

  List<ListTile> makeRadioGroup<T>(Map<T, String> group, void Function(T) onChange) {
    var groupValue = group.keys.first;

    return group.map<ListTile, dynamic>((key, value) => MapEntry(
      ListTile(
        title: Text(value),
        leading: Radio<T>(
          value: key,
          groupValue: groupValue,
          onChanged: (value) {
            groupValue = value;
            onChange(groupValue);
          },
        ),
      ),
      null
    )).keys.toList();
  }
}