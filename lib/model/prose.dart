import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class Prose {
  Future<String> get();

  static String get greeting {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) return 'Have an amazing morning 😀';
    if (hour >= 12 && hour < 19) return 'Have a nice afternoon 🥳';
    if (hour >= 19 || hour < 5) return 'Have a fantastic night 🥱';

    return null;
  }

  static Future<String> fetchFrom(List<Prose> choices) async {
    if (choices.isEmpty) return greeting;

    choices.shuffle();
    return (await choices.first.get()) ?? fetchFrom(choices.sublist(1));
  }
}

class HttpStatus {
  static const success = 200;
}

class Quote implements Prose {
  static final Quote _singleton = Quote._();

  factory Quote.instance() => _singleton;

  Quote._();

  static String fromMap(Map<String, dynamic> json) =>
      '"${json['contents']['quotes'][0]['quote']}"'
      ' - ${json['contents']['quotes'][0]['author']}';

  Future<String> get() async {
    const quoteURL = 'http://quotes.rest/qod.json';
    final response = await http.get(quoteURL);

    if (response.statusCode == HttpStatus.success) {
      return fromMap(json.decode(response.body));
    }

    return Future<String>.value(null);
  }
}

class Joke2 implements Prose {
  static final Joke2 _singleton = Joke2._();

  factory Joke2.instance() => _singleton;

  Joke2._();

  static String fromMap(Map<String, dynamic> json) =>
      '${json['setup']} ${json['punchline']}';

  @override
  Future<String> get() async {
    const url = 'https://official-joke-api.appspot.com/jokes/general/random';
    final response = await http.get(url);

    if (response.statusCode == HttpStatus.success) {
      final decoded = json.decode(response.body);
      return fromMap(decoded[0]);
    }

    return Future<String>.value(null);
  }
}

class Joke implements Prose {
  static final Joke _singleton = Joke._();

  factory Joke.instance() => _singleton;

  Joke._();

  static String fromMap(Map<String, dynamic> json) =>
      (json['contents']['jokes'][0]['joke']['text'] as String);

  Future<String> get() async {
    const jokeURL = 'https://api.jokes.one/jod';
    final response =
        await http.get(jokeURL, headers: {'Content-type': 'application/json'});

    if (response.statusCode == HttpStatus.success) {
      final decoded = json.decode(response.body);
      final joke = decoded['contents']['jokes'][0]['joke'];

      final clean = joke['clean'];
      final isClean = clean == null || clean.toString() == '1';

      final racial = joke['racial'];
      final isRacial = racial != null && racial.toString() == '1';

      if (isClean && !isRacial) return fromMap(decoded).replaceAll('\n', ' ');
    }

    return Future<String>.value(null);
  }
}
