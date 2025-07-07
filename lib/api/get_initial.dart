import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:shared_code/models/ott.dart';
// import 'dart:developer' as d;

Future<String> getInitial() async {
  final url = Uri.parse('$API_URL/home?app=1');
  const headers = {
    'Host': 'netfree2.cc',
    'Sec-Ch-Ua':
        '"Not)A;Brand";v="8", "Chromium";v="138", "Android WebView";v="138"',
    'Sec-Ch-Ua-Mobile': '?1',
    'Sec-Ch-Ua-Platform': '"Android"',
    'Upgrade-Insecure-Requests': '1',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 11; AC2001 Build/RP1A.201005.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.45 Mobile Safari/537.36 /OS.Gatu v3.0',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'X-Requested-With': '',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-User': '?1',
    'Sec-Fetch-Dest': 'document',
    // 'Accept-Encoding': 'gzip, deflate, br',
    'Accept-Language': 'en-US,en;q=0.9',
    'Priority': 'u=0, i',
  };

  try {
    // final res = await http.get(url, headers: headers);
    final res = await http.get(url, headers: headers);
    final status = res.statusCode;
    if (status != 200) throw Exception('http.get error: statusCode= $status');
    final setCookie = res.headers['set-cookie'];
    if (setCookie == null) {
      throw Exception('Error::Netmirror-Step-1:Failed to get addhash cookie');
    }
    return Uri.decodeComponent(setCookie.split(";").first.split("=").last);
  } catch (e) {
    log(
      "Error in getInitial request \n url: ${url.toString()} \n ${e.toString()}",
    );
    rethrow;
  }
}

Future<void> openAdd(String addhash) async {
  // final url1Str = 'https://userverify.netmirror.app/verify?dpj1o=$addhash&a=y&t=0.2822303821745413';
  // final url2Str =
  //     'https://userverify.netmirror.app/?fr3=$addhash&a=y&t=0.2822303821745413';
  log("openAdd params: addhash=$addhash", name: "http");
  final url = Uri.parse('$ADD_URL$addhash&a=y&t=0.2822303821745413');
  log("add link: $url");
  await http.get(url);
}

Future<String?> verifyAdd(String addhash) async {
  final headers = {
    'accept': '*/*',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'no-cache',
    'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
    'cookie': 'addhash=$addhash;',
    'origin': API_URL,
    'pragma': 'no-cache',
    'priority': 'u=1, i',
    'referer': '$API_URL/home',
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

  final data = {'verify': addhash};

  // final url = Uri.parse('$API_URL/verify2.php');
  final url = Uri.parse('$API_URL/verify2.php');

  final res = await http.post(url, headers: headers, body: data);
  final status = res.statusCode;
  if (status != 200) {
    log("Verify Add, ${res.body}");
    throw Exception('http.post error: statusCode= $status');
  }

  log(res.body);
  final sucess = jsonDecode(res.body)['statusup'] == 'All Done';
  if (sucess) {
    return Uri.decodeComponent(
      res.headers['set-cookie']!.split(";").first.split("=").last,
    );
  } else {
    log("verifyADD: null. ${jsonDecode(res.body)}");
    return null;
  }
}

Future<String> getPv({int id = 0, OTT ott = OTT.netflix}) async {
  final path = switch (id) {
    0 => 'home',
    1 => 'movies',
    2 => 'series',
    _ => 'home',
  };
  final tHashT = CookiesManager.tHashT;
  final headers = {
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'no-cache',
    'cookie': 't_hash_t=${Uri.encodeComponent(tHashT!)}; ott=${ott.cookie};',
    'pragma': 'no-cache',
    'priority': 'u=0, i',
    'referer': '$API_URL/',
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

  final url = Uri.parse('$API_URL/$path');

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) throw Exception('http.get error: statusCode= $status');

  return res.body;
}

Future<String> getNf({int id = 0, required OTT ott}) async {
  final path = switch (id) {
    0 => 'home',
    2 => 'movies',
    1 => 'series',
    _ => 'home',
  };
  final tHashT = CookiesManager.tHashT;
  final headers = {
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'accept-language': 'en-US,en;q=0.9',
    'cache-control': 'no-cache',
    'cookie': 't_hash_t=${Uri.encodeComponent(tHashT!)}; ott=${ott.cookie};',
    'pragma': 'no-cache',
    'priority': 'u=0, i',
    'referer': '$API_URL/',
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

  final url = Uri.parse('$API_URL/$path').replace(queryParameters: params);

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) throw Exception('http.get error: statusCode= $status');

  log(res.body);
  return res.body;
}

// void main() async {
  // final addhash = await getInitial();
  // print(addhash);
  // await openAdd(addhash);
  // print("add opened");
  // await Future.delayed(const Duration(seconds: 35), () async {
  //   print(await verifyAdd(addhash));
  // });

  // fc41a648812345422a5c26963f66f60b::3b0786ec72b25d4aa5776bc2b61b11ff::1734871888::ni
  // b2c1bf7c577fb8a203f1122b24cac923::57e05044f1db741209f6dc17879b5233::1734871926::ni
// }
