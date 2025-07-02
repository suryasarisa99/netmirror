import 'package:better_player_plus/better_player_plus.dart';
import 'package:netmirror/constants.dart';

class NmSearchResults {
  final List<NmSearchResult> results;
  final OTT ott;
  final String query;
  final String error;

  NmSearchResults({
    required this.results,
    required this.ott,
    required this.query,
    required this.error,
  });

  factory NmSearchResults.fromJson(
    Map<String, dynamic> json,
    OTT ott,
    String query,
  ) {
    return NmSearchResults(
      // ott: OTT.fromValue(json['ott']),
      query: query,
      ott: ott,
      results: json['searchResult'] == null
          ? []
          : (json['searchResult'] as List)
                .map((e) => NmSearchResult.fromJson(e))
                .toList(),
      error: json['error'],
    );
  }
}

class NmSearchResult {
  final String id;
  final String t;
  final String? y;
  final String? r;

  NmSearchResult({
    required this.id,
    required this.t,
    required this.y,
    required this.r,
  });

  factory NmSearchResult.fromJson(Map<String, dynamic> json) {
    return NmSearchResult(
      id: json['id'],
      t: json['t'],
      y: json['y'],
      r: json['r'],
    );
  }
}
