import 'ott.dart';

class MinifyMovie {
  String id;
  String title;
  String year;
  String? runtime;
  String type;
  List<Season> seasons;
  List<Language> lang;
  List<Suggestion> suggest;
  OTT ott;

  get isMovie => type == 'm';
  get isShow => !isMovie;

  MinifyMovie({
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
  final int? currentEpisodeIndex;
  final int currentSeasonIndex;

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
    required this.currentEpisodeIndex,
    required this.currentSeasonIndex,
  });

  Episode? get currentEpisode {
    if (!isShow) return null;
    return seasons[currentSeasonIndex].episodes?[currentEpisodeIndex!];
  }

  String get videoId {
    if (!isShow) return id;
    return currentEpisode!.id;
  }

  bool get hasNext {
    if (!isShow) return false;
    return (currentSeasonIndex < seasons.length - 1 ||
        currentEpisodeIndex! < seasons[currentSeasonIndex].episodes!.length);
  }

  Episode? get nextEpisode {
    if (!isShow) return null;
    final currentSeason = seasons[currentSeasonIndex];
    if (currentEpisodeIndex! < currentSeason.episodes!.length - 1) {
      return currentSeason.episodes![currentEpisodeIndex! + 1];
    } else if (currentSeasonIndex < seasons.length - 1) {
      return seasons[currentSeasonIndex + 1].episodes?.first;
    }
    return null;
  }

  PlayerData copyWith({required int ei, int? si}) {
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
      currentEpisodeIndex: ei,
      currentSeasonIndex: si ?? currentSeasonIndex,
    );
  }
}

class Season {
  /// Season number, e.g. S1
  int s;

  /// Episodes total count, e.g. 10
  int ep;

  /// Season id, e.g. "s1"
  String id;

  /// List of episodes in this season
  List<Episode>? episodes;

  Season({
    required this.s,
    required this.ep,
    required this.id,
    required this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      s: json['s'],
      ep: json['ep'],
      id: json['id'],
      episodes: json['episodes'] == null
          ? null
          : (json['episodes'] as List).map((e) => Episode.fromJson(e)).toList(),
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
    return {
      's': s,
      'ep': ep,
      'id': id,
      'episodes': episodes?.map((e) => e.toJson()).toList(),
    };
  }
}

class Episode {
  /// Episode id
  String id;

  /// Episode title
  String t;

  /// Season number, e.g. S1
  String s;

  /// Episode number, e.g. E1
  String ep;

  /// Time in format HH:MM:SS
  String time;

  Episode({
    required this.id,
    required this.t,
    required this.s,
    required this.ep,
    required this.time,
  });

  static int getSeasonsNumber(Episode episode) {
    return int.parse(episode.s.substring(1));
  }

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
