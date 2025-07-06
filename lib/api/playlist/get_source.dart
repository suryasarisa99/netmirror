import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/models/search_results_model.dart';
import 'package:shared_code/models/ott.dart';

Future<Sources> getSource({required String id, required OTT ott}) async {
  final tHashT = CookiesManager.tHashT;

  final headers = {
    'accept': '*/*',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
    'cache-control': 'no-cache',
    'cookie': 't_hash_t=$tHashT;',
    'pragma': 'no-cache',
    'priority': 'u=1, i',
    'referer': '$API_URL/watch/$id',
    'sec-ch-ua':
        '"Not)A;Brand";v="99", "Google Chrome";v="127", "Chromium";v="127"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Linux"',
    'sec-fetch-dest': 'empty',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-origin',
    'user-agent':
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
  };

  final params = {
    'id': id,
    // 't': 'Adios Amigo',
    // 'tm': '1726486629',
  };

  final url = Uri.parse(
    '$API_URL/${ott.url}playlist.php',
  ).replace(queryParameters: params);
  log("Source url: $url");

  final res = await http.get(url, headers: headers);
  log("Source response: ${res.body}");
  final status = res.statusCode;

  if (status != 200) throw Exception('http.get error: statusCode= $status');
  // log("Source: ${res.body.substring(0, 10)}");
  // log("Source: ${res.body}");
  final result = Sources.parse(res.body);
  log("sources: ${result.sources.length}");
  log("subtitles: ${result.subtitles.length}");
  log("other tracks: ${result.otherTracks.length}");
  if (result.subtitles.isNotEmpty) {
    for (var subtitle in result.subtitles) {
      log("subtitle: ${subtitle.file}");
    }
  }
  CookiesManager.resourceKey = result.resourceKey;
  return result;
}

Future<List<MySubtitle>> getSubtitles(String url) async {
  final res = await http.get(Uri.parse("https:$url"));
  print(res.body);
  return splitSubtitles(res.body);
}

List<MySubtitle> splitSubtitles(String fullString) {
  List<MySubtitle> subtitles = [];
  RegExp subtitleRegex = RegExp(
    r"\d+\n(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})\n(.*)",
  );
  Iterable<Match> matches = subtitleRegex.allMatches(fullString);

  int index = 0;
  for (Match match in matches) {
    String from = match.group(1)!.trim();
    String to = match.group(2)!.trim();
    String text = match.group(3)!.trim();

    Duration start = parseDuration(from);
    Duration end = parseDuration(to);

    subtitles.add(MySubtitle(start: start, end: end, text: text, index: index));
    index++;
  }

  return subtitles;
}

Duration parseDuration(String durationString) {
  List<String> parts = durationString.split(':');
  int hours = int.parse(parts[0]);
  int minutes = int.parse(parts[1]);
  int seconds = int.parse(parts[2].split(',')[0]);
  int milliseconds = int.parse(parts[2].split(',')[1]);

  return Duration(
    hours: hours,
    minutes: minutes,
    seconds: seconds,
    milliseconds: milliseconds,
  );
}

class Sources {
  final String image;
  final List<SourceModel> sources;
  final List<TrackModel> otherTracks;
  final List<TrackModel> subtitles;
  final String resourceKey;

  Sources({
    required this.image,
    required this.sources,
    required this.otherTracks,
    required this.resourceKey,
    this.subtitles = const [],
  });

  // String get resourceKey {
  //   return sources.first.file.split("=").last.trim();
  // }

  String? get subtitle {
    return otherTracks.firstWhereOrNull((t) => t.kind == "captions")?.file;
  }

  SourceModel get Low {
    return sources.firstWhere(
      (s) => s.label == "Low HD",
      orElse: () => sources.firstWhereOrNull((s) => s.label == "Auto")!,
    );
  }

  factory Sources.parse(String raw) {
    final jsonList = jsonDecode(raw) as List;
    return Sources.fromJson(jsonList.first);
  }

  factory Sources.fromJson(Map<String, dynamic> json) {
    final tracks = json['tracks'] != null
        ? (json['tracks'] as List).map((e) => TrackModel.fromJson(e)).toList()
        : <TrackModel>[];
    final subtitles = tracks.where((t) => t.kind == "captions").toList();
    final otherTracks = tracks.where((t) => t.kind != "captions").toList();
    final sources = (json['sources'] as List)
        .map((e) => SourceModel.fromJson(e))
        .toList();
    final resourceKey =
        Uri.parse(sources.first.file).queryParameters['in'] ?? '';

    return Sources(
      image: json['image'],
      sources: sources,
      otherTracks: otherTracks,
      subtitles: subtitles,
      resourceKey: resourceKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'souces': sources.map((s) => s.toJson()).toList(),
      'tracks': otherTracks.map((t) => t.toJson()).toList(),
    };
  }
}

class SourceModel {
  final String file;
  final String label;
  final String type;

  SourceModel({required this.file, required this.label, required this.type});

  String get key {
    return file.split("=").last.trim();
  }

  String get resolution {
    return {
      "Full HD": "1080p",
      "Mid HD": "720p",
      "Low HD": "480p",
      "Auto": "auto",
    }[label]!;
  }

  factory SourceModel.fromJson(Map<String, dynamic> json) {
    return SourceModel(
      file: json['file'],
      label: json['label'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'file': file, 'type': type, 'label': label};
  }
}

class TrackModel {
  final String kind;
  final String? label;
  final String file;

  TrackModel({required this.kind, required this.label, required this.file});

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      kind: json['kind'],
      label: json['label'],
      file: json['file'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'kind': kind, 'file': file, 'label': label};
  }
}

class MySubtitle {
  final int? index;
  final Duration? start;
  final Duration? end;
  final String? text;

  MySubtitle({this.index, this.start, this.end, this.text});
}
