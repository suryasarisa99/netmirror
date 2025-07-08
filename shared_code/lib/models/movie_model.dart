import 'ott.dart';

class MinifyMovie {
  final String id;
  final String title;
  final String year;
  final String? runtime;
  final String type;
  final Map<int, Season>
  seasons; // Changed from List to Map<seasonNumber, Season>
  final List<Language> lang;
  final List<Suggestion> suggest;
  final OTT ott;

  get isMovie => type == 'm';
  get isShow => !isMovie;

  const MinifyMovie({
    required this.id,
    required this.title,
    required this.year,
    required this.runtime,
    required this.type,
    required this.seasons,
    required this.lang,
    required this.suggest,
    required this.ott,
  });
}

class PlayerData extends MinifyMovie {
  final int? currentEpisodeNumber; // Changed from Index to Number
  final int currentSeasonNumber; // Changed from Index to Number

  PlayerData({
    required super.id,
    required super.title,
    required super.year,
    required super.runtime,
    required super.type,
    required super.seasons,
    required super.lang,
    required super.suggest,
    required super.ott,
    required this.currentEpisodeNumber,
    required this.currentSeasonNumber,
  });

  Episode? get currentEpisode {
    if (!isShow) return null;
    return seasons[currentSeasonNumber]?.episodes?[currentEpisodeNumber!];
  }

  Season? get currentSeason {
    if (!isShow) return null;
    return seasons[currentSeasonNumber];
  }

  String get videoId {
    if (!isShow) return id;
    return currentEpisode!.id;
  }

  bool get hasNext {
    if (!isShow) return false;
    final currentSeason = seasons[currentSeasonNumber];
    if (currentSeason?.episodes == null) return false;

    // Check if there's a next episode in current season
    final episodeNumbers = currentSeason!.episodes!.keys.toList()..sort();
    final currentEpIndex = episodeNumbers.indexOf(currentEpisodeNumber!);

    return (currentEpIndex < episodeNumbers.length - 1) || _hasNextSeason();
  }

  bool _hasNextSeason() {
    final seasonNumbers = seasons.keys.toList()..sort();
    final currentSeasonIndex = seasonNumbers.indexOf(currentSeasonNumber);
    return currentSeasonIndex < seasonNumbers.length - 1;
  }

  Episode? get nextEpisode {
    if (!isShow) return null;
    final currentSeason = seasons[currentSeasonNumber];
    if (currentSeason?.episodes == null) return null;

    // Get sorted episode numbers for current season
    final episodeNumbers = currentSeason!.episodes!.keys.toList()..sort();
    final currentEpIndex = episodeNumbers.indexOf(currentEpisodeNumber!);

    // Check if there's a next episode in current season
    if (currentEpIndex < episodeNumbers.length - 1) {
      final nextEpisodeNumber = episodeNumbers[currentEpIndex + 1];
      return currentSeason.episodes![nextEpisodeNumber];
    }

    // Check next season
    if (_hasNextSeason()) {
      final seasonNumbers = seasons.keys.toList()..sort();
      final currentSeasonIndex = seasonNumbers.indexOf(currentSeasonNumber);
      final nextSeasonNumber = seasonNumbers[currentSeasonIndex + 1];
      final nextSeason = seasons[nextSeasonNumber];

      if (nextSeason?.episodes?.isNotEmpty == true) {
        final firstEpisodeNumber =
            (nextSeason!.episodes!.keys.toList()..sort()).first;
        return nextSeason.episodes![firstEpisodeNumber];
      }
    }

    return null;
  }

  PlayerData copyWith({required int episodeNumber, int? seasonNumber}) {
    return PlayerData(
      id: id,
      title: title,
      year: year,
      runtime: runtime,
      type: type,
      seasons: seasons,
      lang: lang,
      suggest: suggest,
      ott: ott,
      currentEpisodeNumber: episodeNumber,
      currentSeasonNumber: seasonNumber ?? currentSeasonNumber,
    );
  }
}

class Season {
  /// Season number, e.g. 1
  final int s;

  /// Episodes total count, e.g. 10
  final int ep;

  /// Season id, e.g. "s1"
  final String id;

  /// Map of episodes in this season, keyed by episode number
  final Map<int, Episode>? episodes;

  const Season({
    required this.s,
    required this.ep,
    required this.id,
    required this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    Map<int, Episode>? episodesMap;
    if (json['episodes'] != null) {
      final episodesList = (json['episodes'] as List)
          .map((e) => Episode.fromJson(e))
          .toList();
      episodesMap = {};
      for (final episode in episodesList) {
        episodesMap[episode.epNum] = episode;
      }
    }

    return Season(
      s: json['s'],
      ep: json['ep'],
      id: json['id'],
      episodes: episodesMap,
    );
  }

  factory Season.parse(Map<String, dynamic> json) {
    return Season(
      s: int.parse(json['s']),
      ep: int.parse(json['ep']),
      id: json['id'],
      episodes: null,
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>>? episodesList;
    if (episodes != null) {
      episodesList = episodes!.values.map((e) => e.toJson()).toList();
      // Sort episodes by episode number for consistent serialization
      episodesList.sort(
        (a, b) =>
            Episode.fromJson(a).epNum.compareTo(Episode.fromJson(b).epNum),
      );
    }

    return {'s': s, 'ep': ep, 'id': id, 'episodes': episodesList};
  }

  /// Creates a copy of the season with new episodes
  Season copyWithEpisodes(List<Episode> episodesList) {
    Map<int, Episode> episodesMap = {};
    for (final episode in episodesList) {
      episodesMap[episode.epNum] = episode;
    }

    return Season(s: s, ep: ep, id: id, episodes: episodesMap);
  }
}

class Episode {
  /// Episode id
  final String id;

  /// Episode title
  final String t;

  /// Season number, e.g. S1
  final String s;

  /// Episode number, e.g. E1
  final String ep;

  /// Time in format HH:MM:SS
  final String time;

  int get epNum => int.parse(ep.substring(1));
  int get sNum => int.parse(s.substring(1));

  const Episode({
    required this.id,
    required this.t,
    required this.s,
    required this.ep,
    required this.time,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'],
      t: json['t'],
      s: json['s'],
      ep: json['ep'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 't': t, 's': s, 'ep': ep, 'time': time};
  }
}

class Language {
  String l;
  String s;

  Language({required this.l, required this.s});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(l: json['l'], s: json['s']);
  }

  Map<String, dynamic> toJson() {
    return {'l': l, 's': s};
  }
}

class Suggestion {
  String id;

  Suggestion({required this.id});

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(id: json['id']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }
}
