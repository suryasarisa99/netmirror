import 'dart:convert';
import 'dart:developer';

import 'package:netmirror/models/netmirror/netmirror_model.dart';

class MinifyMovie {
  String id;
  String title;
  String year;
  String? runtime;
  String type;
  List<NmSeason> seasons;
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

class NmMovie {
  String id;
  DateTime lastUpdated;
  String status;
  String? dLang;
  String title;
  String year;
  String ua;
  String match;
  String? runtime;
  String hdsd;
  String type;
  String creator;
  String director;
  String writer;
  String? shortCast;
  String cast;
  List<String> genre;
  String? genreStr;
  String thisMovieIs;
  String mDesc;
  String mReason;
  String desc;
  String? oin;
  String resume;
  List<NmSeason> seasons;
  List<Language> lang;
  List<Suggestion> suggest;
  dynamic error;
  OTT ott;

  NmMovie({
    required this.id,
    required this.status,
    required this.dLang,
    required this.title,
    required this.year,
    required this.ua,
    required this.match,
    required this.runtime,
    required this.hdsd,
    required this.type,
    required this.creator,
    required this.director,
    required this.writer,
    required this.shortCast,
    required this.cast,
    required this.genre,
    required this.genreStr,
    required this.thisMovieIs,
    required this.mDesc,
    required this.mReason,
    required this.desc,
    required this.oin,
    required this.resume,
    required this.lang,
    required this.suggest,
    required this.lastUpdated,
    required this.ott,
    required this.seasons,
    this.error,
  });

  get isMovie => type == 'm';
  get isShow => !isMovie;
  // OTT get ott => OTT.fromValue(ottStr);

  factory NmMovie.parse(Map<String, dynamic> json, String id, OTT? ott) {
    List<NmEpisode> episodesList = [];
    List<Suggestion> suggestList = [];
    List<String> genre = [];

    if (json['episodes'] != null) {
      List episodes = json['episodes'] as List;
      if (!(episodes.length == 1 && episodes[0] == null)) {
        episodesList = episodes.map((e) => NmEpisode.fromJson(e)).toList();
      }
    }

    var seasons = json['season'] != null
        ? (json['season'] as List).map((s) => NmSeason.parse(s)).toList()
        : <NmSeason>[];

    log("seasons length: ${seasons.length}");
    for (int i = seasons.length - 1; i >= 0; i--) {
      int seasonIndex = NmEpisode.getSeasonsNumber(episodesList.first);
      if (seasons[i].s == seasonIndex) {
        seasons[i].episodes = episodesList;
        break;
      }
    }

    suggestList = (json['suggest'] == "" || json["suggest"] == null)
        ? []
        : (json['suggest'] as List).map((e) => Suggestion.fromJson(e)).toList();

    genre = json['genre'] == null
        ? []
        : (json['genre'] as String).split(', ').map((e) => e.trim()).toList();

    log(jsonEncode(json));
    return NmMovie(
      id: id,
      status: json['status'],
      dLang: json['d_lang'],
      title: json['title'],
      year: json['year'],
      ua: json['ua'],
      match: json['match'],
      runtime: json['runtime'],
      hdsd: json['hdsd'],
      type: json['type'],
      creator: json['creator'],
      director: json['director'],
      writer: json['writer'],
      shortCast: json['short_cast'],
      cast: json['cast'],
      genre: genre,
      genreStr: json['genre'],
      thisMovieIs: json['thismovieis'],
      mDesc: json['m_desc'],
      mReason: json['m_reason'],
      desc: json['desc'],
      oin: json['oin'],
      resume: json['resume'],
      lang: (json['lang'] as List).map((i) => Language.fromJson(i)).toList(),
      suggest: suggestList,
      error: json['error'],
      ott: ott ?? OTT.fromValue(json['ottStr'] ?? 'pv'),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      seasons: seasons,
    );
  }

  bool get isStale => DateTime.now().difference(lastUpdated).inHours > 24;
  bool get isFresh => !isStale;

  factory NmMovie.fromJson(Map<String, dynamic> json, String id, OTT? ott) {
    List<Suggestion> suggestList = [];
    List<String> genre = [];

    var seasons = json['season'] != null
        ? (json['season'] as List).map((s) => NmSeason.fromJson(s)).toList()
        : <NmSeason>[];

    if (json['suggest'] == "") {
      suggestList = [];
    } else {
      List suggest = json['suggest'] as List;
      suggestList = suggest.map((e) => Suggestion.fromJson(e)).toList();
    }

    if (json['genre'] is String) {
      genre =
          (json['genre'] as String).split(', ').map((e) => e.trim()).toList();
    } else if (json['genre'] is List) {
      genre = (json['genre'] as List).map((e) => e.toString()).toList();
    } else {
      genre = [];
    }

    // log(jsonEncode(json));
    return NmMovie(
      id: id,
      status: json['status'],
      dLang: json['d_lang'],
      title: json['title'],
      year: json['year'],
      ua: json['ua'],
      match: json['match'],
      runtime: json['runtime'],
      hdsd: json['hdsd'],
      type: json['type'],
      creator: json['creator'],
      director: json['director'],
      writer: json['writer'],
      shortCast: json['short_cast'],
      cast: json['cast'],
      genre: genre,
      genreStr: json['genreStr'],
      thisMovieIs: json['thismovieis'],
      mDesc: json['m_desc'],
      mReason: json['m_reason'],
      desc: json['desc'],
      oin: json['oin'],
      resume: json['resume'],
      lang: (json['lang'] as List).map((i) => Language.fromJson(i)).toList(),
      suggest: suggestList,
      error: json['error'],
      ott: ott ?? OTT.fromValue(json['ottStr'] ?? 'pv'),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      seasons: seasons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'd_lang': dLang,
      'title': title,
      'year': year,
      'ua': ua,
      'match': match,
      'runtime': runtime,
      'hdsd': hdsd,
      'type': type,
      'creator': creator,
      'director': director,
      'writer': writer,
      'short_cast': shortCast,
      'cast': cast,
      'genre': genre,
      'genreStr': genreStr,
      'thismovieis': thisMovieIs,
      'm_desc': mDesc,
      'm_reason': mReason,
      'desc': desc,
      'oin': oin,
      'resume': resume,
      'lang': lang.map((i) => i.toJson()).toList(),
      'suggest': suggest.map((i) => i.toJson()).toList(),
      'error': error,
      'lastUpdated': lastUpdated.toIso8601String(),
      'ottStr': ott.value,
      'season': seasons.map((e) => e.toJson()).toList(),
    };
  }

  MinifyMovie toMinifyMovie() {
    return MinifyMovie(
      id: id,
      title: title,
      year: year,
      runtime: runtime,
      type: type,
      seasons: seasons,
      lang: lang,
      suggest: suggest,
      ott: ott,
    );
  }
}

class NmSeason {
  int s; // season number
  int ep; // episodes total count
  String id; // season id
  List<NmEpisode>? episodes;

  NmSeason({
    required this.s,
    required this.ep,
    required this.id,
    required this.episodes,
  });

  factory NmSeason.fromJson(Map<String, dynamic> json) {
    return NmSeason(
      s: json['s'],
      ep: json['ep'],
      id: json['id'],
      episodes: json['episodes'] == null
          ? null
          : (json['episodes'] as List)
              .map((e) => NmEpisode.fromJson(e))
              .toList(),
    );
  }

  factory NmSeason.parse(Map<String, dynamic> json) {
    return NmSeason(
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

class NmEpisode {
  String id;
  String t;
  String s;
  String ep;
  String time;

  NmEpisode({
    required this.id,
    required this.t,
    required this.s,
    required this.ep,
    required this.time,
  });

  static int getSeasonsNumber(NmEpisode episode) {
    return int.parse(episode.s.substring(1));
  }

  factory NmEpisode.fromJson(Map<String, dynamic> json) {
    return NmEpisode(
      id: json['id'],
      t: json['t'],
      s: json['s'],
      ep: json['ep'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      't': t,
      's': s,
      'ep': ep,
      'time': time,
    };
  }
}

class Language {
  String l;
  String s;

  Language({required this.l, required this.s});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      l: json['l'],
      s: json['s'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'l': l,
      's': s,
    };
  }
}

class Suggestion {
  String id;

  Suggestion({required this.id});

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
