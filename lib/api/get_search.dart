import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/models/search_results_model.dart';
import 'package:shared_code/models/ott.dart';

Future<SearchResults> getSearchResults(
  String query, {
  OTT ott = OTT.netflix,
}) async {
  // final tHashT = await CookiesManager.validTHashT;
  final tHashT = CookiesManager.tHashT;
  final headers = {
    'accept': '*/*',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'no-cache',
    'cookie': 't_hash_t=$tHashT;',
    'pragma': 'no-cache',
    'priority': 'u=1, i',
    'referer': '$apiUrl/movies',
    'sec-ch-ua':
        '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Linux"',
    'sec-fetch-dest': 'empty',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-origin',
    'user-agent':
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'x-requested-with': 'XMLHttpRequest',
  };

  final params = {'s': query, 't': '1734872866'};

  final url = Uri.parse(
    '$apiUrl/${ott.url}search.php',
  ).replace(queryParameters: params);

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) throw Exception('http.get error: statusCode= $status');
  log("response: ${res.body}");
  return SearchResults.fromJson(jsonDecode(res.body), ott, query);
}
