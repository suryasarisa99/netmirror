import 'package:http/http.dart' as http;
import 'package:netmirror/api/playlist/get_master_hls.dart';
import 'package:netmirror/constants.dart';

Future<String> getVideoHls({
  required String id,
  required MyVideoPlaylist src,
  required bool isShow,
}) async {
  final headers = {
    'Accept': '*/*',
    'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'Origin': apiUrl,
    'Pragma': 'no-cache',
    'Referer': '$apiUrl/',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'cross-site',
    'User-Agent':
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
    'sec-ch-ua':
        '"Not)A;Brand";v="99", "Google Chrome";v="127", "Chromium";v="127"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Linux"',
  };

  final resolution = src.quality;
  // String key = src.key;

  final url = Uri.parse(
    'https://${src.prefix}.top/files/$id/$resolution/$resolution.m3u8?in=${src.key}',
  );
  // log("quality: $resolution || id: $id || ${src.videoId}  ");

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) {
    throw Exception(
      'HSL Video Playlist Error http.get error: statusCode= $status',
    );
  }

  // log("${res.body.substring(1, 120)}...");
  return res.body;
}
