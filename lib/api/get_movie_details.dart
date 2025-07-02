import 'dart:convert';
import 'dart:developer';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:http/http.dart' as http;
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/models/netmirror/nm_movie_model.dart';

Future<Movie> getMovie(String id, {OTT ott = OTT.none}) async {
  final tHashT = CookiesManager.tHashT;
  final headers = {
    'accept': '*/*',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'no-cache',
    'cookie': 't_hash_t=$tHashT;',
    'pragma': 'no-cache',
    'priority': 'u=1, i',
    'referer': '$API_URL/movies',
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

  final params = {'id': id, 't': '1734872811'};

  final url = Uri.parse(
    'https://a.netfree2.cc/mobile/${ott.url}post.php',
  ).replace(queryParameters: params);
  // log("getMovie: $url", name: "http");

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) {
    log("Error: ${res.body}", name: "http");
    throw Exception('http.get error: statusCode= $status');
  }
  // log("res.body: ${res.body}", name: "http");
  return Movie.parse(jsonDecode(res.body), id, ott);
}
