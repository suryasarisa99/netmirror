import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/api/playlist/fast_playlist.dart';
import 'package:netmirror/api/playlist/get_master_hls.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/data/options.dart';
import 'package:netmirror/models/movie_model.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:netmirror/provider/AudioTrackProvider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future goToMovie(BuildContext context, int ottId, String movieId) {
  debugPrint("Navigating to movie: $movieId on OTT: $ottId");
  return GoRouter.of(context).push("/movie/$ottId/$movieId");
}

void goToPlayerNew({
  required BuildContext context,
  required WidgetRef ref,
  required Movie movie,
  WatchHistory? wh,
  int? sNum,
  int? eNum,
}) async {
  if (movie.isShow && sNum == null) {
    // l.error("Episode index is null for show");
    return;
  }
  // GoRouter.of(context).push(
  //   "/player",
  //   extra: (
  //     movie: movie,
  //     watchHistory: wh,
  //     seasonIndex: sIndex ?? seasonIndex,
  //     episodeIndex: eIndex,
  //   ),
  // );

  // for testing, passing object doesn't supports hot reload, so url for testing purpose
  final videoId = movie.isMovie ? movie.id : movie.getEpisode(sNum!, eNum!)!.id;
  final resourceKey = CookiesManager.resourceKey!;
  late String url;
  if (SettingsOptions.fastModeByAudio || SettingsOptions.fastModeByVideo) {
    final masterPlaylist = await getMasterHls(videoId, resourceKey, movie.ott);
    final List<String> audiosCodecs = SettingsOptions.fastModeByAudio
        ? ref.read(audioTrackProvider).map((e) => e["language"]!).toList()
        : [];
    final String? resolution = SettingsOptions.fastModeByVideo
        ? SettingsOptions.defaultResolution
        : null;
    final simplifiedPlaylist = fastPlaylist(
      masterPlaylist,
      audiosCodecs,
      resolution,
    );
    // log("sourceStr: \n$simplifiedPlaylist");
    // write to file
    final basedir = Directory(
      isDesk
          ? p.join((await getDownloadsDirectory())!.path, "netmirror", "temp")
          : "/storage/emulated/0/Download/netmirror/temp",
    );
    if (!await basedir.exists()) {
      await basedir.create(recursive: true);
    }
    final file = File("${basedir.path}/$videoId.m3u8");
    await file.writeAsString(simplifiedPlaylist);
    url = file.path;
  } else {
    url = '$apiUrl/${movie.ott.url}hls/$videoId.m3u8?in=$resourceKey';
  }
  GoRouter.of(context).push(
    "/player",
    extra: (
      movie: movie,
      watchHistory: wh,
      seasonNumber: sNum,
      episodeNumber: eNum,
      url: url,
    ),
  );
  // .then((val) {
  //   Future.delayed(Duration(milliseconds: 400)).then((_) {
  //     getWatchHistory(movie, sIndex).then((_) {
  //       setState(() {});
  //     });
  //   });
  // });
}
