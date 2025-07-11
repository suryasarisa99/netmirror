import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:shared_code/models/ott.dart';

Future<String> getHome({int id = 0, required OTT ott, String? studio}) async {
  final path = switch (id) {
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
  final headers = {
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'no-cache',
    // 'cookie': 't_hash_t=${Uri.encodeComponent(tHashT!)}; ott=${ott.cookie};',
    'cookie': cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
    'pragma': 'no-cache',
    'priority': 'u=0, i',
    'referer': '$apiUrl/',
    'sec-ch-ua':
        '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Linux"',
    'sec-fetch-dest': 'document',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'same-origin',
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
    'user-agent':
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  };

  final params = {'app': "1"};
  final url = Uri.parse('$apiUrl/$path').replace(queryParameters: params);

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) throw Exception('http.get error: statusCode= $status');

  // log(res.body);
  return res.body;
}
