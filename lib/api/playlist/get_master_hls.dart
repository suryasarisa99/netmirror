import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:netmirror/constants.dart';
import 'package:shared_code/models/ott.dart';

Future<String> getMasterHls(
  String videoId,
  String key,
  OTT ott, {
  hd = true,
}) async {
  final url = Uri.parse('$newApiUrl/${ott.url}hls/$videoId.m3u8?in=$key');
  // log("getMasterHls url: $url, key: $key", name: "http");

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) throw Exception('http.get error: statusCode= $status');
  final videoUrls = res.body
      .split("\n")
      .where((line) => line.contains('::ni'))
      .toList();
  log(videoUrls.toString());
  // log(res.body);
  return res.body;
}

MasterPlayList parseMasterHls(String raw) {
  final audioUrls = raw.split("\n").where((line) => line.endsWith('.m3u8"'));
  final videoUrls = raw
      .split("\n")
      .where((line) => line.contains('::ni'))
      .toList();

  // log(videoUrls.toString());

  final audioSources = audioUrls.map((e) {
    final items = e.split(",").sublist(2);
    final x = items.map((i) {
      final lastWord = i.split("=").last;
      return lastWord.substring(1, lastWord.length - 1);
    }).toList();
    return MyAudioPlaylist.parse(x);
  }).toList();

  return MasterPlayList.fromUrls(videoUrls, audioSources);
}

class MasterPlayList {
  final List<MyVideoPlaylist> videos;
  final Map<String, int> indexMap;
  final List<MyAudioPlaylist> audios;

  MasterPlayList({
    required this.videos,
    required this.indexMap,
    required this.audios,
  });

  factory MasterPlayList.fromUrls(
    List<String> urls,
    List<MyAudioPlaylist> audioSources,
  ) {
    final List<MyVideoPlaylist> sources = urls
        .map((url) => MyVideoPlaylist.parse(url))
        .toList();

    final Map<String, int> indexMap = {};
    sources.forEachIndexed((i, src) {
      indexMap[src.quality] = i;
    });
    return MasterPlayList(
      videos: sources,
      indexMap: indexMap,
      audios: audioSources,
    );
  }
}

final videoM3u8Exp = RegExp(
  r'https://(?<prefix>[\w\.-]+)\.top/files/(?<id>[\w]+)/(?<quality>[\w]+)/\w+\.m3u8\?in=(?<key>[\w:]+)',
);

class MyVideoPlaylist {
  final String url;
  final String quality;
  final String videoId;
  final String prefix;
  final String key;

  MyVideoPlaylist({
    required this.url,
    required this.key,
    required this.prefix,
    required this.quality,
    required this.videoId,
  });

  factory MyVideoPlaylist.parse(String url) {
    var match = videoM3u8Exp.firstMatch(url);
    if (match == null) {
      final String err = "Parsing Video Url from MasterPlaylist, url: $url";
      log(err);
      Exception(err);
    }
    final prefix = match!.namedGroup("prefix")!;
    final quality = match.namedGroup("quality")!;
    final key = match.namedGroup("key")!;
    final id = match.namedGroup("id")!;

    return MyVideoPlaylist(
      url: url,
      key: key,
      prefix: prefix,
      quality: quality,
      videoId: id,
    );
  }
}

class MyAudioPlaylist {
  final String lang;
  final String name;
  final bool defaultVal;
  final String url;
  final String prefix;
  final String suffix;
  final String number;

  MyAudioPlaylist({
    required this.lang,
    required this.name,
    required this.defaultVal,
    required this.url,
    required this.prefix,
    required this.suffix,
    required this.number,
  });

  String getSuffix(String id) {
    return url.split(id).last.split(".").first;
  }

  factory MyAudioPlaylist.parse(List<String> items) {
    // log("Audio Items: $items");
    final url = items[3];
    final match = audioM3u8Exp.firstMatch(url);
    if (match == null) {
      final err = "Parsing Audio Urls from MasterHls,  url: '$url'";
      log(err);
      Exception(err);
    }
    final prefix = match!.namedGroup('prefix')!;
    final id = match.namedGroup('id')!;
    final index = match.namedGroup('index')!;

    return MyAudioPlaylist(
      lang: items[0],
      name: items[1],
      defaultVal: items[2] == "YES",
      url: items[3],
      number: index,
      prefix: prefix,
      suffix: id,
    );
  }
}

String filterM3U8ByQuality(String source, String quality) {
  // Split the source into lines
  List<String> lines = source.split('\n');
  List<String> filteredLines = [];
  bool skipNextLine = false;

  for (int i = 0; i < lines.length; i++) {
    String line = lines[i].trim();

    // Always keep header, version, and audio entries
    if (line.startsWith('#EXTM3U') ||
        line.startsWith('#EXT-X-VERSION') ||
        line.startsWith('#EXT-X-MEDIA:TYPE=AUDIO')) {
      filteredLines.add(line);
      continue;
    }

    // Check if current line is a stream info line
    if (line.startsWith('#EXT-X-STREAM-INF')) {
      // Check if the next line exists (it should contain the URL)
      if (i + 1 < lines.length) {
        // Check if this stream info contains the desired quality
        if (line.contains('RESOLUTION') && lines[i + 1].contains(quality)) {
          // Keep this stream info and its URL
          filteredLines.add(line);
          skipNextLine = false;
        } else {
          // Skip this stream info and its URL
          skipNextLine = true;
          continue;
        }
      }
    } else if (!skipNextLine) {
      // Add non-stream-info lines (including URLs) if not marked for skipping
      filteredLines.add(line);
    }
  }

  // Join the filtered lines back together
  return filteredLines.join('\n');
}
