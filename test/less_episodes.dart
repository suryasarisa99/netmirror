import 'dart:convert';
import 'dart:developer';

import 'package:netmirror/db/db.dart';
import 'package:netmirror/db/tables.dart';
import 'package:netmirror/models/movie_model.dart';

void lessEpisodes() async {
  final db = await DB.instance.database;
  final result = await db.query(Tables.movie);
  log("result length: ${result.length}");
  for (var item in result) {
    final key = item['key'] as String;
    final val = Movie.fromJson(jsonDecode(item['value']! as String), key, null);
    if (val.isMovie) continue;
    for (final season in val.seasons.values) {
      if (season.episodes != null &&
          season.episodes!.isNotEmpty &&
          season.ep < 6) {
        final episodes = season.episodes!.values.toList();
        for (final episode in episodes) {
          if (int.parse(episode.time.substring(0, 2)) < 20) {
            log(
              "title: ${val.title}, ott: ${val.ott},ep:${season.ep} time: ${episode.time} seconds",
            );
          }
        }
      }
    }
  }
}
