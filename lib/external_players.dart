import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:netmirror/constants.dart';

// mpv \
//   --http-header-fields="Accept: */*, Accept-Language: en-US,en;q=0.9, Cache-Control: no-cache, Cookie: 81304576=43%3A3755; 81157729=97%3A7899; recentplay=SE80991848-81157729; 81188619=470%3A2612; SE80991848=81056389; 81056389=2601%3A2765; ott=nf; t_hash_t=a315fd896d4ef9dc44df4442b40c1335%3A%3Abbe9cd14d871f534260531cb50b3c5a7%3A%3A1727535745%3A%3Ani; t_hash=8bd737f1f1159c5380753e8aed304bc8%3A%3A1727553686%3A%3Ani, Pragma: no-cache, Referer: $API_URL/home, User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36" \
// '$API_URL/hls/81726031.m3u8?in=a315fd896d4ef9dc44df4442b40c1335::fe53071764cf92f71da6e6be7ad06641::1727553688::ni'

// ffplay \
//   -headers "Accept: */*\r\nAccept-Language: en-GB,en-US;q=0.9,en;q=0.8\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\nOrigin: $API_URL\r\nPragma: no-cache\r\nReferer: $API_URL/\r\nSec-Fetch-Dest: empty\r\nSec-Fetch-Mode: cors\r\nSec-Fetch-Site: cross-site\r\nUser-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36\r\nsec-ch-ua: \"Not)A;Brand\";v=\"99\", \"Google Chrome\";v=\"127\", \"Chromium\";v=\"127\"\r\nsec-ch-ua-mobile: ?0\r\nsec-ch-ua-platform: \"Linux\"\r\n" \
//   '$API_URL/hls/81726031.m3u8?in=263100c297d0565f93e2bc2c81ba6584::ae926b7511909f41f0d2d0206dac6578::1726820684::ni'

// ffplay \
//   -headers "Accept: */*\r\nAccept-Language: en-GB,en-US;q=0.9,en;q=0.8\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\nOrigin: $API_URL\r\nPragma: no-cache\r\nReferer: $API_URL/\r\nSec-Fetch-Dest: empty\r\nSec-Fetch-Mode: cors\r\nSec-Fetch-Site: cross-site\r\nUser-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36\r\nsec-ch-ua: \"Not)A;Brand\";v=\"99\", \"Google Chrome\";v=\"127\", \"Chromium\";v=\"127\"\r\nsec-ch-ua-mobile: ?0\r\nsec-ch-ua-platform: \"Linux\"\r\n" \
//   '$API_URL/hls/81726031.m3u8?in=a315fd896d4ef9dc44df4442b40c1335::fe53071764cf92f71da6e6be7ad06641::1727553688::ni'

void openPlayer(int videoId) {
  openMpv(videoId, proxy: true);
  // openVlc(videoId);
  // openFfplay(videoId);
}

Future<void> openVlc(int videoId) async {
  final String url = '$apiUrl/hls/$videoId.m3u8?in=$key';

  const userAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36';
  const command = 'vlc';
  final arguments = [
    // '--intf rc',
    '--network-caching=${20 * 60 * 60 * 1000}',
    '--fullscreen',
    '--http-user-agent=$userAgent',
    '--http-referrer=$apiUrl/',
    '--file-caching=yes',
    url,
  ];

  late Process process;
  log("$command $arguments");

  if (Platform.isWindows) {
    process = await Process.start(command, arguments);
  } else {
    process = await Process.start(
      command,
      arguments,
      environment: {'LD_PRELOAD': '/lib/x86_64-linux-gnu/libpthread.so.0'},
    );
  }

  process.stdout
      .transform(utf8.decoder)
      .listen((data) => print("Output: $data"));
  process.stderr
      .transform(utf8.decoder)
      .listen((data) => print("Error: $data"));

  await process.exitCode;
}

Future<void> openMpv(int videoId, {proxy = false}) async {
  final String url = '$apiUrl/hls/$videoId.m3u8?in=$key';

  const userAgent =
      'Mozilla/5.0 AppleWebKit/537.36 Chrome/127.0.0.0 Safari/537.36';
  // const userAgent =
  //     'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36';
  const command = 'mpv';
  final arguments = [
    '--no-config',
    '--demuxer=lavf',
    if (proxy) '--http-proxy=http://localhost:8080',
    '--user-agent=$userAgent',
    '--http-header-fields=${headers2.join(',')}',
    '--force-window=yes',
    '--cache=yes',
    // '--hls-bitrate=max',
    // '--demuxer-max-back-bytes=1000M',
    // '--demuxer-max-bytes=1000M',
    url,
  ];

  // await startMitmProxy();
  // return;

  final process = await Process.start(command, arguments);

  // Handle process output and errors
  process.stdout
      .transform(utf8.decoder)
      .listen((data) => print("Output: $data"));
  process.stderr
      .transform(utf8.decoder)
      .listen((data) => print("Error: $data"));

  await process.exitCode;
}

Future<void> openFfplay(int videoId) async {
  final String url = '$apiUrl/hls/$videoId.m3u8?in=$key';

  const userAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36';
  const command = 'ffplay';
  final arguments = [
    // '-http_proxy localhost:8080',
    '-user_agent',
    userAgent,
    '-headers',
    'Origin: $apiUrl\r\nReferer: $apiUrl/\r\nSec-Fetch-Mode: cors',
    '-protocol_whitelist',
    'file,http,https,tcp,tls,crypto',
    '-i',
    url,
  ];

  final process = await Process.start(command, arguments);

  process.stdout
      .transform(utf8.decoder)
      .listen((data) => print("Output: $data"));
  process.stderr
      .transform(utf8.decoder)
      .listen((data) => print("Error: $data"));

  await process.exitCode;
}

Future<void> mplayer(int videoId) async {
  final String url = '$apiUrl/hls/$videoId.m3u8?in=$key';

  const userAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36';
  const command = 'mplayer';
  final arguments = [
    // '--http-proxy=http://localhost:8080',
    // '--user-agent=$userAgent',
    '--http-header=${headers2.join(',')}',
    // '--http-header-fields=Origin: $API_URL,Referer: $API_URL/,Sec-Fetch-Mode: cors',
    '--force-window=yes',
    // '--hls-bitrate=max',
    '--cache=yes',
    // '--demuxer-max-back-bytes=1000M',
    // '--demuxer-max-bytes=1000M',
    url,
  ];

  final process = await Process.start(command, arguments);

  // Handle process output and errors
  process.stdout
      .transform(utf8.decoder)
      .listen((data) => print("Output: $data"));
  process.stderr
      .transform(utf8.decoder)
      .listen((data) => print("Error: $data"));

  await process.exitCode;
}

Future<void> startMitmProxy() async {
  const commandMitmproxy = 'mitmproxy';
  final mitmproxyArguments = ['-s', '~/Desktop/test/mitm-script.py'];

  final mitmproxyProcess = await Process.start(
    commandMitmproxy,
    mitmproxyArguments,
  );

  await Future.delayed(const Duration(seconds: 2));
}
