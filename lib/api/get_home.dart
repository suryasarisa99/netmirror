import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/log.dart';
import 'package:shared_code/models/ott.dart';

Future<String> getHome({int id = 0, required OTT ott, String? studio}) async {
  log("id is $id, ott: ${ott.cookie}, studio: $studio");
  String path = switch (id) {
    0 => 'home',
    1 => 'series',
    2 => 'movies',
    _ => 'home',
  };

  final tHashT = CookiesManager.tHashT;
  final cookies = {'t_hash_t': Uri.encodeComponent(tHashT!), 'ott': ott.cookie};
  if (studio != null) {
    cookies['studio'] = studio;
  }

  log("1: ${'t_hash_t=${Uri.encodeComponent(tHashT)}; ott=${ott.cookie};'}");
  log("2: ${cookies.entries.map((e) => '${e.key}=${e.value}').join('; ')}");

  // final cookie =
  //     """t_hash_t=fdbcca769c4ee56d76462d24788143e8%3A%3A0dceae76fee45c9ea748c7e7ad92ce98%3A%3A1752262822%3A%3Ani; ott=hs; studio=marvel""";
  final headers = {
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'no-cache',
    // 'cookie': 't_hash_t=${Uri.encodeComponent(tHashT)}; ott=${ott.cookie};',
    'cookie': cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
    // 'cookie': cookie,
    // 'cookie':
    //     't_hash_t=2b66aa69f84c5baaf670d0d861a8478e%3A%3A52feffc5ff3749cbf39f66aa513945e8%3A%3A1754000358%3A%3Ani',
    'pragma': 'no-cache',
    'priority': 'u=0, i',
    // 'referer': '$apiUrl/',
    'referer': 'https://net50.cc/mobile/home?app=1',
    'sec-ch-ua':
        '"Not)A;Brand";v="8", "Chromium";v="138", "Android WebView";v="138"',
    'sec-ch-ua-mobile': '?1',
    'sec-ch-ua-platform': '"Android"',
    'sec-fetch-dest': 'document',
    'x-requested-with': 'app.netmirror.netmirrornew',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'same-origin',
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
    'user-agent':
        'Mozilla/5.0 (Linux; Android 11; AC2001 Build/RP1A.201005.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.168 Mobile Safari/537.36 /OS.Gatu v3.0',
  };
  log("headers: $headers");

  final params = {'app': "1"};
  final url = Uri.parse('$apiUrl/$path').replace(queryParameters: params);
  log("url: $url");
  try {
    final res = await http.get(url, headers: headers);
    final status = res.statusCode;
    if (status != 200) throw Exception('http.get error: statusCode= $status');

    // log(res.body);
    return res.body;
  } catch (e, s) {
    log("Error in getHome: $url $e");
    log("Stack trace: $s");
    throw Exception('Error fetching home data: $e');
  }
}
