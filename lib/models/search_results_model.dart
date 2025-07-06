import 'package:shared_code/models/ott.dart';

class SearchResults {
  final List<SearchResult> results;
  final OTT ott;
  final String query;
  final String error;

  SearchResults({
    required this.results,
    required this.ott,
    required this.query,
    required this.error,
  });

  factory SearchResults.fromJson(
    Map<String, dynamic> json,
    OTT ott,
    String query,
  ) {
    return SearchResults(
      // ott: OTT.fromValue(json['ott']),
      query: query,
      ott: ott,
      results: json['searchResult'] == null
          ? []
          : (json['searchResult'] as List)
                .map((e) => SearchResult.fromJson(e))
                .toList(),
      error: json['error'],
    );
  }
}

class SearchResult {
  final String id;
  final String t;
  final String? y;
  final String? r;

  SearchResult({
    required this.id,
    required this.t,
    required this.y,
    required this.r,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'],
      t: json['t'],
      y: json['y'],
      r: json['r'],
    );
  }
}
