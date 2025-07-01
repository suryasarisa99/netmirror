import 'package:http/http.dart' as http;
import 'package:netmirror/api/playlist/get_master_hls.dart';
import 'package:netmirror/constants.dart';

Future<String> getAudioHls({
  required String id,
  required MyAudioPlaylist audioSrc,
}) async {
  // Exception('getAudioHls is not implemented');

  final headers = {
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
    'Origin': API_URL,
    'Pragma': 'no-cache',
    'Referer': '$API_URL/',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'cross-site',
    'User-Agent':
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
    'sec-ch-ua':
        '"Google Chrome";v="129", "Not=A?Brand";v="8", "Chromium";v="129"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Linux"',
  };

  final suffix = audioSrc.getSuffix(id);
  // final smallSuffix = "a/${audioSrc.number}";

  // log("audio src: Prefix: ${audioSrc.prefix} : Suffix: $suffix  : id: $id");
  // final url = Uri.parse('https://${audioSrc.prefix}.top/files/$id$suffix.m3u8');
  final url = Uri.parse(audioSrc.url);
  // log("url: $url");

  // const prefixUrl =
  //     'https://${audioSrc.prefix}.nfmirrorcdn.top/files/${id}/${smallSuffix}/';

  final res = await http.get(url, headers: headers);
  final status = res.statusCode;
  if (status != 200) throw Exception('http.get error: statusCode= $status');
  // log("HLS Audio: ${res.body.substring(1, 80)} ...");

  return res.body;
}
