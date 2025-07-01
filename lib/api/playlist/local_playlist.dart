import 'package:path/path.dart' as p;

// String makeLocalPlaylist(String playlist, path) {
//   final contentpath =
//       "content://com.example.netmirror.fileprovider/external_files/$path";

//   // final prefix = isDesk ? "." : contentpath;
//   const prefix = ".";

//   RegExp regex = RegExp(r'::ni\s*$');
//   return playlist.split("\n").map((line) {
//     if (line.endsWith('.m3u8"')) {
//       final lastItem = line.split(",").last;
//       final onlineUrl = lastItem.substring(5, lastItem.length - 1);
//       // final offlineUrl = "$contentpath/audios/audioHls.m3u8";
//       final offlineUrl = "$prefix/audios/audioHls.m3u8";
//       return line.replaceFirst(onlineUrl, offlineUrl);
//     } else if (regex.hasMatch(line)) {
//       return "$prefix/videos/videoHls.m3u8";
//     } else {
//       return line;
//     }
//   }).join("\n");
// }
String makeLocalPlaylist(
  String playlist,
  String videoId,
  List<int> audioPaths,
) {
  final audioRegex = RegExp(
    r'#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",LANGUAGE="[^"]+",NAME="[^"]+",DEFAULT=.{2,6}?,URI="(?<url>https://[^/]+/files/\w+/a/(?<number>\d+)/\d+.m3u8)"',
  );
  RegExp videoRegex = RegExp(r'::ni\s*$');

  final videoPath = p.join("./.$videoId", "videos", "videoHls.m3u8");
  return playlist
      .split("\n")
      .map((line) {
        final audioMatch = audioRegex.firstMatch(line);
        if (audioMatch != null) {
          final number = audioMatch.namedGroup("number");
          if (audioPaths.contains(int.parse(number!))) {
            final audioPath = p.join(
              "./.$videoId",
              "audios-$number",
              "audioHls.m3u8",
            );
            return line.replaceFirst(audioMatch.namedGroup('url')!, audioPath);
          } else {
            return null;
          }
        } else if (videoRegex.hasMatch(line)) {
          return videoPath;
        } else {
          return line;
        }
      })
      .where((line) => line != null)
      .join("\n");
}

String makeLocalVideoPlaylist(String playlist) {
  // final contentpath =
  // "content://com.example.netmirror.fileprovider/external_files/${videoId}/videos";

  return playlist
      .split("\n")
      .map((line) {
        if (line.endsWith('.jpg')) {
          final part = line.replaceFirst((".jpg"), ".mp4");
          // return "$contentpath/$part";
          return part;
        } else {
          return line;
        }
      })
      .join("\n");
}

String makeLocalAudioPlaylist(String playlist) {
  // final contentpath =
  // "content://com.example.netmirror.fileprovider/external_files/$videoId/audios";

  return playlist
      .split("\n")
      .map((line) {
        if (line.endsWith('.jpg')) {
          final part = line.replaceFirst((".jpg"), ".aac");
          // return "$contentpath/$part";
          return part;
        } else if (line.endsWith(".js")) {
          final part = line.replaceFirst((".js"), ".aac");
          // return "$contentpath/$part";
          return part;
        } else {
          return line;
        }
      })
      .join("\n");
}
