import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension SplittableList<Element> on Iterable {
  Iterable<Iterable<Element>> split(bool Function(Element) test) => [
    this.where(test),
    this.where((e) => !test(e))
  ];
}

class SyncList<Element> extends ListBase<Element> {
  String _createKey(Object o) => prefsIdentifier + o.hashCode.toString();

  final List<Element> _innerList = List<Element>();
  final String prefsIdentifier;
  final SharedPreferences prefs;

  SyncList({
    @required this.prefsIdentifier,
    @required this.prefs,
    @required Element Function(Map<String, dynamic>) decoder
  }) : super() {
    _innerList.addAll(prefs
        .getKeys()
        .where((key) => key.startsWith(prefsIdentifier))
        .map((key) => decoder(json.decode(prefs.get(key))))
    );
  }

  @override
  int get length => _innerList.length;

  @override
  set length(int length) => _innerList.length = length;

  @override
  Element operator [](int index) => _innerList[index];

  @override
  void operator []=(int index, Element value) => _innerList[index] = value;

  @override
  void add(Element element) {
    _innerList.add(element);
    _innerList.sort();

    prefs.setString(_createKey(element), json.encode(element));
  }

  @override
  bool remove(Object element) {
    prefs.remove(_createKey(element));
    return _innerList.remove(element);
  }

  @override
  void addAll(Iterable<Element> iterable) {
    _innerList.addAll(iterable);
    _innerList.sort();

    iterable.forEach((e) => prefs.setString(_createKey(e), json.encode(e)));
  }

  @override
  Element removeAt(int index) {
    var element = _innerList[index];
    remove(element);
    return element;
  }

  @override
  void removeWhere(bool Function(Element) test) {
    _innerList.where(test).forEach((e) => prefs.remove(_createKey(e)));
    _innerList.removeWhere(test);
  }
}