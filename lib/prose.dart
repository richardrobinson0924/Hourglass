import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class Prose {
  Future<String> get();

  static Future<String> fetch() async {
    final choices = [Quote(), Joke()]..shuffle();
    var prose = await Greeting().get();

    for (int i = 0; i < choices.length; i += 1) {
      var tmp = await choices[i].get();
      if (tmp != null) {
        prose = tmp;
        break;
      }
    }

    return prose;
  }
}

class HttpStatus {
  static const success = 200;
}

class Quote implements Prose {
  static final Quote _singleton = Quote._();

  factory Quote() => _singleton;

  Quote._();

  static String fromMap(Map<String, dynamic> json) =>
      '"${json['contents']['quotes'][0]['quote']}"'
      ' - ${json['contents']['quotes'][0]['author']}';

  Future<String> get() async {
    print('Getting quote...');
    const quoteURL = 'http://quotes.rest/qod.json';

    var response = await http.get(quoteURL);

    if (response.statusCode == HttpStatus.success) {
      print('Quote acquired');

      return fromMap(json.decode(response.body));
    }

    return null;
  }
}

class Joke implements Prose {
  static final Joke _singleton = Joke._();

  factory Joke() => _singleton;

  Joke._();

  static String fromMap(Map<String, dynamic> json) =>
      (json['contents']['jokes'][0]['joke']['text'] as String);

  Future<String> get() async {
    print('Getting joke...');
    const jokeURL = 'https://api.jokes.one/jod';

    var response =
        await http.get(jokeURL, headers: {'Content-type': 'application/json'});

    if (response.statusCode == HttpStatus.success) {
      print('Joke acquired');

      final decoded = json.decode(response.body);
      final joke = decoded['contents']['jokes'][0]['joke'];

      final clean = joke['clean'];
      final isClean = clean == null || clean.toString() == '1';

      final racial = joke['racial'];
      final isRacial = racial != null && racial.toString() == '1';

      if (isClean && !isRacial) return fromMap(decoded).replaceAll('\n', ' ');
    }

    return null;
  }
}

class Greeting implements Prose {
  static final Greeting _singleton = Greeting._();

  factory Greeting() => _singleton;

  Greeting._();

  Future<String> get() async => toString();

  @override
  String toString() {
    // TODO: implement toString
    final hour = DateTime.now().hour;

    var ret = '';

    if (hour >= 5 && hour < 12) ret = 'Have an amazing morning 😀';
    if (hour >= 12 && hour < 19) ret = 'Have a nice afternoon 🥳';
    if (hour >= 19 || hour < 5) ret = 'Have a fantastic night 🥱';

    return ret;
  }
}
