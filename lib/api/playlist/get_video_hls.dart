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
    'Origin': API_URL,
    'Pragma': 'no-cache',
    'Referer': '$API_URL/',
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

  final resulution = src.quality;
  // String key = src.key;

  final url = Uri.parse(
    'https://${src.prefix}.top/files/$id/$resulution/$resulution.m3u8?in=${src.key}',
  );
  // log("video hls: $url");
  // log("quality: $resulution || id: $id || ${src.videoId}  ");

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) {
    throw Exception(
      'HSL Video Playlist Error Vhttp.get error: statusCode= $status',
    );
  }

  // log("${res.body.substring(1, 120)}...");
  return res.body;
}

// https://s03.nfmirrorcdn.top/files/81143875/720p/720p.m3u8?in=263100c297d0565f93e2bc2c81ba6584::68ff512824e519b4392ad68c1722a46e::1726763842::ni
