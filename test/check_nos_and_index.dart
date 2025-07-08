import 'dart:convert';
import 'dart:developer';

import 'package:netmirror/db/db.dart';
import 'package:netmirror/db/tables.dart';
import 'package:netmirror/models/movie_model.dart';

// to check season and episodes numbers with index
// due to some has missing seasons and some episodes not start from 0
// so don't store seasonIndex and episodeIndex in database

void checkSeasonAndEpisodeNumbers() async {
  final db = await DB.instance.database;
  final result = await db.query(Tables.movie);
  log("result length: ${result.length}");
  for (var item in result) {
    final key = item['key'] as String;
    final val = Movie.fromJson(jsonDecode(item['value']! as String), key, null);
    if (val.isMovie) continue;
    for (final season in val.seasons.values) {
      if (season.episodes != null && season.episodes!.isNotEmpty) {
        final sortedEpisodes = season.episodes!.values.toList()
          ..sort((a, b) => a.epNum.compareTo(b.epNum));
        for (int i = 0; i < sortedEpisodes.length; i++) {
          final episode = sortedEpisodes[i];
          if (int.parse(episode.ep.substring(1)) != i + 1) {
            log(
              "error in ${val.title}, at season ${season.s}, episode ${episode.ep}",
            );
          }
        }
      }
    }
  }
}
