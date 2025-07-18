import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/watch_list_model.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:netmirror/utils/nav.dart';
import 'package:path/path.dart' as p;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/api/get_more_episodes.dart';
import 'package:netmirror/api/get_movie_details.dart';
import 'package:netmirror/api/playlist/get_master_hls.dart';
import 'package:netmirror/api/playlist/get_source.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/db/db.dart';
import 'package:netmirror/downloader/download_db.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:netmirror/models/movie_model.dart';
import 'package:netmirror/screens/external_plyer.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_code/models/movie_model.dart';
import 'package:shared_code/models/ott.dart';
import 'package:skeletonizer/skeletonizer.dart';

const l = L("moivie_abstract");

abstract class MovieScreen extends ConsumerStatefulWidget {
  const MovieScreen(this.id, {super.key});
  final String id;
}

abstract class MovieScreenState extends ConsumerState<MovieScreen>
    with TickerProviderStateMixin {
  abstract OTT ott;
  abstract bool extraTabForCast;

  bool inWatchlist = false;
  Movie? movie;
  Map<String, MiniDownloadItem> downloads = {};
  TabController? tabController;
  int seasonNumber = -1;
  bool episodesLoading = false;
  WatchHistory? watchHistory;
  List<WatchHistory> seasonWatchHistory = [];
  late AnimationController watchlistAnimationController;

  @override
  void initState() {
    super.initState();
    watchlistAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    loadData();
  }

  @override
  void dispose() {
    watchlistAnimationController.dispose();
    tabController?.dispose();
    super.dispose();
  }

  String get videoId {
    if (movie!.isMovie) return movie!.id;
    return movie!.getSeasonEpisodes(seasonNumber).entries.first.value.id;
  }

  Future<void> loadDownloads() async {
    final downloadList = await DownloadDb.instance.getMovieOrSeries(widget.id);
    final temp = Map.fromEntries(downloadList.map((e) => MapEntry(e.id, e)));
    setState(() {
      downloads = temp;
    });
  }

  Future<void> loadData() async {
    var localMovie = await DB.movie.get(widget.id, ott.id);

    loadDownloads();

    if (localMovie != null) {
      final List<dynamic> results = await Future.wait([
        getWatchHistory(localMovie),
        DB.watchList.isIn(localMovie.id, ott.id),
      ]);
      int tabLen = 0;
      if (localMovie.isShow) tabLen++;
      if (localMovie.suggest.isNotEmpty) tabLen++;
      if (extraTabForCast) tabLen++;
      tabController = TabController(length: tabLen, vsync: this);

      setState(() {
        inWatchlist = results[1] as bool;
        movie = localMovie;
        seasonNumber =
            localMovie.latestSeasonNumber; // Use latest season number
      });
      l.debug("movie got from db: ${localMovie.id}");
    }

    if (localMovie == null || localMovie.isStale) {
      loadDataFromOnline();
    }
  }

  Future<void> loadDataFromOnline() async {
    var onlineMovie = await getMovie(widget.id, ott);
    l.debug("movie got from online: ${onlineMovie.id}");
    if (tabController == null) {
      int tabLen = 0;
      if (onlineMovie.isShow) tabLen++;
      if (onlineMovie.suggest.isNotEmpty) tabLen++;
      if (extraTabForCast) tabLen++;

      tabController = TabController(length: tabLen, vsync: this);
      setState(() {
        movie = onlineMovie;
        seasonNumber =
            onlineMovie.latestSeasonNumber; // Use latest season number
      });
    } else {
      setState(() {
        movie = onlineMovie;
      });
    }

    DB.movie.add(widget.id, ott.id, onlineMovie);
  }

  Future<void> getWatchHistory(Movie? m, [int? seasonNum]) async {
    if (m == null) return;
    if (m.isMovie) {
      final result = await DB.watchHistory.get(
        id: m.id,
        ottId: ott.id,
        videoId: m.id,
      );
      watchHistory = result;
    } else {
      final result = await DB.watchHistory.getShowHistory(
        ottId: ott.id,
        seasonNumber: seasonNum ?? m.latestSeasonNumber, // Use season number
        seriesId: m.id,
      );
      l.debug("season watch history len: ${result.length}");
      seasonWatchHistory = result;
    }
  }

  void handleSeasonChange(int newSeasonNumber) async {
    l.debug("Changing season to $newSeasonNumber");

    setState(() {
      seasonNumber = newSeasonNumber;
    });
    final watchHistoryFuture = getWatchHistory(movie, newSeasonNumber);
    log("watch history: ${watchHistory?.id}, ${watchHistory?.current}");

    final season = movie!.getSeason(newSeasonNumber);
    if (season.episodes == null) {
      log("episodes are loading");
      final moreEpisodes = await getMoreEpisodes(
        s: season.id,
        series: widget.id,
        ott: movie!.ott,
      );
      await watchHistoryFuture;

      setState(() {
        // Update the season with episodes
        movie!.seasons[newSeasonNumber] = season.copyWithEpisodes(moreEpisodes);
      });
      DB.movie.add(widget.id, ott.id, movie!);
    } else {
      log("episodes already loaded");
    }
  }

  void shareDeepLinkUrl() {
    log("Sharing movie: ${movie!.id}");
    SharePlus.instance.share(
      ShareParams(
        uri: Uri.parse("https://netmirror.com/movie/${ott.id}/${movie!.id}"),
      ),
    );
  }

  void loadMoreEpisodes() async {
    if (episodesLoading) return;
    log("surya abstract class: loadMoreEpisodes()");

    log("loading more episodes");
    episodesLoading = true;
    final season = movie!.getSeason(seasonNumber);
    final currentEpisodes = movie!.getSeasonEpisodes(seasonNumber);
    final pageNum = currentEpisodes.length ~/ 10 + 1; // page number

    final moreEpisodes = await getMoreEpisodes(
      s: season.id,
      series: widget.id,
      page: pageNum,
      ott: movie!.ott,
    );

    setState(() {
      // Create new episodes map with existing and new episodes
      final currentEpisodesMap = season.episodes ?? <int, Episode>{};
      for (final episode in moreEpisodes) {
        currentEpisodesMap[episode.epNum] = episode;
      }

      movie!.seasons[seasonNumber] = Season(
        s: season.s,
        ep: season.ep,
        id: season.id,
        episodes: currentEpisodesMap,
      );
      episodesLoading = false;
      DB.movie.add(widget.id, ott.id, movie!);
    });
  }

  void launchExternalPlayer(String id, String resourceKey) async {
    late final String basedirPath;
    if (isDesk) {
      basedirPath = p.join(
        (await getDownloadsDirectory())!.path,
        "netmirror",
        "temp",
      );
    } else {
      basedirPath = "/storage/emulated/0/Download/netmirror/temp";
    }
    final basedir = Directory(basedirPath);
    log("basepath: ${basedir.path}");
    final sourceRaw = await getMasterHls(id, resourceKey, ott);
    // create temp file

    if (!await basedir.exists()) {
      await basedir.create(recursive: true);
    }
    final file = File("${basedir.path}/$id.m3u8");
    await file.writeAsString(sourceRaw);
    log("writed to file: ${file.path}");

    // final sourceRaw = await file.readAsString();
    final masterPlaylist = parseMasterHls(sourceRaw);
    final (qualityIndex, audioIndex, status, autoSelect) =
        await selectionConfigure(sourceRaw, context);
    if (!status) return;
    if (autoSelect) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Auto Selected"),
          duration: const Duration(milliseconds: 2000),
        ),
      );
    }
    final resolution = masterPlaylist.videos[qualityIndex].quality;
    final x = filterM3U8ByQuality(sourceRaw, resolution);
    final filterFile = await File(
      "${basedir.path}/${id}_filtered.m3u8",
    ).writeAsString(x);
    log("============= filtered =============");
    log(x);
    if (!isDesk) {
      final intent = AndroidIntent(
        action: 'action_view',
        data: filterFile.path,
        type: "application/x-mpegURL",
        package: 'org.videolan.vlc',
        flags: [
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_GRANT_READ_URI_PERMISSION,
        ],
      );
      await intent.launch();
    } else {
      if (Platform.isMacOS) {
        ExternalPlayer.onlineFile.iina(filterFile.path);
      }
      ExternalPlayer.onlineFile.vlc(filterFile.path);
    }
  }

  void playMovieOrEpisode() {
    if (movie!.isShow) {
      playEpisode(movie!.getFirstEpisdoe(seasonNumber).epNum);
    } else {
      playMovie();
    }
  }

  void playMovie() async {
    // if (!CookiesManager.isValidResourceKey) {
    l.error("Invalid resource key, ${CookiesManager.resourceKey}");
    await getSource(id: movie!.id, ott: movie!.ott);
    // }
    if (!CookiesManager.isValidResourceKey) {
      l.error("Resource key is still invalid after fetching source");
      return;
    }
    goToPlayer(movie: movie!);
    // if (!isDesk) {
    //   // log("resource id: ${x.resourceKey}");
    //   if (SettingsOptions.externalPlayer) {
    //     launchExternalPlayer(movie!.id, x.resourceKey);
    //     // launchExternalPlayer(movie!.id, "");
    //   } else {
    //     goToPlayer(movie: movie!);
    //   }
    // } else {
    //   launchExternalPlayer(movie!.id, x.resourceKey);
    // }
  }

  void playEpisode(int episodeNumber) async {
    final episode = movie!.getEpisode(seasonNumber, episodeNumber);
    final videoId = episode.id;
    l.info("play episode: episode number $episodeNumber, videoId: $videoId");
    if (!CookiesManager.isValidResourceKey) {
      l.error("Invalid resource key, ${CookiesManager.resourceKey}");
      await getSource(id: movie!.id, ott: movie!.ott);
    }
    if (!CookiesManager.isValidResourceKey) {
      l.error("Resource key is still invalid after fetching source");
      return;
    }
    goToPlayer(movie: movie!, eNum: episodeNumber);
    // if (SettingsOptions.externalPlayer || isDesk) {
    //   launchExternalPlayer(videoId, CookiesManager.resourceKey!);
    // } else {
    // }
  }

  // void goToPlayer({
  //   required Movie movie,
  //   WatchHistory? wh,
  //   int? sIndex,
  //   int? eIndex,
  // }) async {
  //   if (movie.isShow && eIndex == null) {
  //     l.error("Episode index is null for show");
  //     return;
  //   }
  //   // GoRouter.of(context).push(
  //   //   "/player",
  //   //   extra: (
  //   //     movie: movie,
  //   //     watchHistory: wh,
  //   //     seasonIndex: sIndex ?? seasonIndex,
  //   //     episodeIndex: eIndex,
  //   //   ),
  //   // );

  //   // for testing, passing object doesn't supports hot reload, so url for testing purpose
  //   final videoId = movie.isMovie
  //       ? movie.id
  //       : movie.seasons[sIndex ?? seasonIndex].episodes![eIndex!].id;
  //   final resourceKey = CookiesManager.resourceKey!;
  //   late String url;
  //   if (SettingsOptions.fastModeByAudio || SettingsOptions.fastModeByVideo) {
  //     final masterPlaylist = await getMasterHls(videoId, resourceKey, ott);
  //     final List<String> audiosCodecs = SettingsOptions.fastModeByAudio
  //         ? ref.read(audioTrackProvider).map((e) => e["language"]!).toList()
  //         : [];
  //     final String? resolution = SettingsOptions.fastModeByVideo
  //         ? SettingsOptions.defaultResolution
  //         : null;
  //     final simplifiedPlaylist = fastPlaylist(
  //       masterPlaylist,
  //       audiosCodecs,
  //       resolution,
  //     );
  //     log("sourceStr: \n$simplifiedPlaylist");
  //     // write to file
  //     final basedir = Directory(
  //       isDesk
  //           ? p.join((await getDownloadsDirectory())!.path, "netmirror", "temp")
  //           : "/storage/emulated/0/Download/netmirror/temp",
  //     );
  //     if (!await basedir.exists()) {
  //       await basedir.create(recursive: true);
  //     }
  //     final file = File("${basedir.path}/$videoId.m3u8");
  //     await file.writeAsString(simplifiedPlaylist);
  //     url = file.path;
  //   } else {
  //     url = '$newApiUrl/${movie.ott.url}hls/$videoId.m3u8?in=$resourceKey';
  //   }
  //   GoRouter.of(context)
  //       .push(
  //         "/player",
  //         extra: (
  //           movie: movie,
  //           watchHistory: wh ?? watchHistory,
  //           seasonIndex: sIndex ?? seasonIndex,
  //           episodeIndex: eIndex,
  //           url: url,
  //         ),
  //       )
  //       .then((val) {
  //         Future.delayed(Duration(milliseconds: 400)).then((_) {
  //           getWatchHistory(movie, seasonIndex).then((_) {
  //             setState(() {});
  //           });
  //         });
  //       });
  // }

  void goToPlayer({
    required Movie movie,
    WatchHistory? wh,
    int? sNum,
    int? eNum,
  }) {
    goToPlayerNew(
      context: context,
      ref: ref,
      movie: movie,
      wh: wh,
      sNum: sNum ?? seasonNumber,
      eNum: eNum,
    );
  }

  void downloadMovie() async {
    if (movie!.isShow) {
      // download season
      downloadSeason();
      return;
    }
    final x = await getSource(id: movie!.id, ott: ott);

    downloadConfigure(
      movie!.id,
      movie!.toMinifyMovie(),
      x.resourceKey,
      1,
      null,
      context,
    );
  }

  void downloadEpisode(int episodeNumber, int seasonNum) async {
    final episode = movie!.getEpisode(seasonNum, episodeNumber);
    if (episode == null) {
      l.error(
        "Episode not found: season $seasonNum, episode number $episodeNumber",
      );
      return;
    }

    final videoId = episode.id;
    final x = await getSource(id: videoId, ott: ott);

    downloadConfigure(
      videoId,
      movie!.toMinifyMovie(),
      x.resourceKey,
      seasonNum,
      episodeNumber,
      context,
    );
  }

  void downloadSeason() async {
    final x = await getSource(id: movie!.id, ott: ott);

    // all episodes of a season except downloaded ones
    final episodesMap = movie!.getSeasonEpisodes(seasonNumber);
    final episodes = episodesMap.values
        .where((e) => !downloads.containsKey(e.id))
        .toList();
    l.info("new episodes added: ${episodes.length}");

    final result = await seasonConfigure(
      movie!.toMinifyMovie(),
      x.resourceKey,
      seasonNumber,
      context,
    );
    if (result == null) return;
    final (qualityIndex, audioIndexes, sourceRaw) = result;
    Downloader.instance.startSeasonDownload(
      movie!.toMinifyMovie(),
      seasonNumber,
      episodes,
      qualityIndex,
      audioIndexes,
      sourceRaw,
      x.resourceKey,
    );
  }

  void handleAddWatchlist() async {
    if (inWatchlist) {
      log("Removing from watchlist");
      // Animate from added state to removed state (1.0 to 0.0)
      await watchlistAnimationController.reverse();
      setState(() {
        inWatchlist = false;
      });
      DB.watchList.delete(movie!.id, ott.id);
    } else {
      log("Adding to watchlist");
      // Animate from removed state to added state (0.0 to 1.0)
      await watchlistAnimationController.forward();
      setState(() {
        inWatchlist = true;
      });
      DB.watchList.add(
        WatchList(
          id: movie!.id,
          ottId: ott.id,
          title: movie!.title,
          isShow: movie!.isShow,
        ),
      );
    }
  }
}

Future<(int, List<int>, String)?> seasonConfigure(
  MinifyMovie movie,
  String key,
  int seasonNumber,
  BuildContext context,
) async {
  late final String sourceRaw;

  final season = movie.seasons[seasonNumber];
  if (season?.episodes == null || season!.episodes!.isEmpty) {
    log("No episodes found for season $seasonNumber");
    return null;
  }

  final firstEpisodeNumber = (season.episodes!.keys.toList()).first;
  final id = season.episodes![firstEpisodeNumber]!.id;

  // final x = await DatabaseHelper.instance.getHslPlaylist(movie.id);
  final x = null;
  if (x == null) {
    sourceRaw = await getMasterHls(id, key, movie.ott);
    // DatabaseHelper.instance.addHslPlaylist(movie.id, sourceRaw);
  } else {
    sourceRaw = x;
  }
  final sources = parseMasterHls(sourceRaw);

  int qualityIndex = -1;
  List<int> audioIndexes = [];
  bool status = false;
  log("sources: v:${sources.videos.length} A: ${sources.audios.length}");

  if (sources.videos.length > 1 || sources.audios.length > 1) {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      enableDrag: true,
      builder: (context) {
        return DownloadSheet(
          sources: sources,
          download: (List<int> a, int v, bool s) {
            qualityIndex = v;
            audioIndexes = a;
            status = s;
          },
        );
      },
    );
    if (status) {
      return (qualityIndex, audioIndexes, sourceRaw);
    } else {
      log("status: $status");
    }
  } else {
    return (0, <int>[], sourceRaw);
  }
  return null;
}

Future<(int q, int a, bool s, bool auto)> selectionConfigure(
  String sourceRaw,
  BuildContext context,
) async {
  final sources = parseMasterHls(sourceRaw);
  int qualityIndex = -1;
  List<int> audioIndexes = [];
  bool status = false;

  if (sources.videos.length > 1 || sources.audios.length > 1) {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      enableDrag: true,
      builder: (context) {
        return DownloadSheet(
          sources: sources,
          singleAudio: true,
          download: (List<int> a, int v, bool s) {
            qualityIndex = v;
            audioIndexes = a;
            status = s;
          },
        );
      },
    );
    if (status) {
      return (
        qualityIndex,
        sources.audios.length > 1 ? audioIndexes.first : 0,
        status,
        false,
      );
    } else {
      return (0, 0, status, false);
    }
  } else {
    return (0, 0, true, true);
  }
}

Future<void> downloadConfigure(
  String videoId,
  MinifyMovie movie,
  String key,
  int seasonNumber,
  int? episodeNumber,
  BuildContext context,
) async {
  late final String sourceRaw;
  log("seasons: ${movie.seasons.length}");

  // final x = await DatabaseHelper.instance.getHslPlaylist(movie.id);
  final x = null;
  if (x == null) {
    sourceRaw = await getMasterHls(videoId, key, movie.ott);
    // DatabaseHelper.instance.addHslPlaylist(movie.id, sourceRaw);
  } else {
    sourceRaw = x;
  }
  final sources = parseMasterHls(sourceRaw);

  int qualityIndex = -1;
  List<int> audioIndexes = [];
  bool status = false;
  log("sources: v:${sources.videos.length} A: ${sources.audios.length}");

  if (sources.videos.length > 1 || sources.audios.length > 1) {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // showDragHandle: true,
      // barrierColor: Colors.green,
      // barrierLabel: "Download",
      enableDrag: true,
      builder: (context) {
        return DownloadSheet(
          sources: sources,
          download: (List<int> a, int v, bool s) {
            qualityIndex = v;
            audioIndexes = a;
            status = s;
          },
        );
      },
    );
    if (status) {
      Downloader.instance.startDownload(
        movie,
        sourceRaw,
        audioIndexes,
        qualityIndex,
        key,
        sources,
        episodeNumber: episodeNumber,
        seasonNumber: seasonNumber,
      );
    } else {
      log("status: $status");
    }
  } else {
    Downloader.instance.startDownload(
      movie,
      sourceRaw,
      [],
      0,
      key,
      sources,
      episodeNumber: episodeNumber,
      seasonNumber: seasonNumber,
    );
  }
}

class DownloadSheet extends StatefulWidget {
  const DownloadSheet({
    super.key,
    required this.sources,
    required this.download,
    this.singleAudio = false,
  });

  final void Function(List<int>, int, bool) download;

  final MasterPlayList sources;
  final bool singleAudio;
  @override
  State<DownloadSheet> createState() => _DownloadSheetState();
}

// void openDownloadSheet(BuildContext context) {
// showModalBottomSheet(
//   context: context,
//   isDismissible: true,
//   // showDragHandle: true,
//   useSafeArea: true,
//   backgroundColor: Colors.transparent,
//   isScrollControlled: true,
//   shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//   // barrierColor: Colors.green,
//   // barrierLabel: "Download",
//   enableDrag: true,

//   builder: (context) => const DownloadSheet(),
// );
// }

// class _DownloadSheetState2 extends State<DownloadSheet> {
//   bool isExpanded = isDesk ? true : false;

//   List<Widget> buildTopBarItems() {
//     return [
//       IconButton(
//           onPressed: () {
//             context.pop();
//           },
//           icon: Icon(Icons.arrow_back)),
//       const SizedBox(width: 16),
//       Text("Download",
//           style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400)),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return NotificationListener<DraggableScrollableNotification>(
//       onNotification: (notification) {
//         // log("notification: ${notification.extent}");
//         if (notification.extent >= 1 && !isExpanded) {
//           log("expanded");
//           setState(() {
//             isExpanded = true;
//           });
//         } else if (notification.extent < 1 && isExpanded) {
//           setState(() {
//             isExpanded = false;
//           });
//         }
//         return true;
//       },
//       child: DraggableScrollableSheet(
//         initialChildSize: isDesk ? 1 : 0.55,
//         minChildSize: isDesk ? 1 : 0.55,
//         maxChildSize: 1.0,
//         // snap: true,
//         // snapSizes: const [0.55, 1.0],
//         expand: false,
//         builder: (context, scrollController) {
//           return Container(
//               decoration: const BoxDecoration(
//                 // color: Colors.black,
//                 color: Colors.black,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: Scaffold(
//                 // backgroundColor: Colors.black,
//                 // backgroundColor: Colors.red,
//                 backgroundColor: Colors.transparent,
//                 body: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     isDesk
//                         ? windowDragAreaWithChild(buildTopBarItems())
//                         : Padding(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 0),
//                             child: Row(children: buildTopBarItems()),
//                           ),
//                     Expanded(
//                       child: ListView.builder(
//                         controller: scrollController,
//                         itemCount: 20, // Add your actual item count
//                         itemBuilder: (context, index) {
//                           return Container(
//                             margin: const EdgeInsets.all(10),
//                             padding: const EdgeInsets.all(10),
//                             color: Colors.blue,
//                             height: 100, // Added height to make items visible
//                             child: Center(
//                               child: Text('Item $index'),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ));
//         },
//       ),
//     );
//   }
// }

class _DownloadSheetState extends State<DownloadSheet> {
  bool _isExpanded = isDesk ? true : false;
  late int _videoIndex = widget.sources.videos.length <= 2 ? 0 : -1;
  late List<int> _audioIndexs = widget.sources.audios.length == 1 ? [1] : [];
  final selectedColor = Colors.white60;

  List<Widget> buildTopBarItems() {
    return [
      IconButton(
        onPressed: () {
          context.pop();
        },
        icon: Icon(Icons.arrow_back),
      ),
      const SizedBox(width: 16),
      Text(
        widget.singleAudio ? "Play" : "Download",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final audioSelected =
        _audioIndexs.isNotEmpty || widget.sources.audios.isEmpty;
    final videoSelected = _videoIndex != -1;
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // log("notification: ${notification.extent}");
        if (notification.extent >= 1 && !_isExpanded) {
          log("expanded");
          setState(() {
            _isExpanded = true;
          });
        } else if (notification.extent < 1 && _isExpanded) {
          setState(() {
            _isExpanded = false;
          });
        }
        return true;
      },
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: isDesk ? 1 : 0.55,
        minChildSize: isDesk ? 1 : 0.55,
        maxChildSize: 1.0,
        // snap: true,
        // snapSizes: const [0.55, 1.0],
        builder: (context, scrollController) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isDesk
                          ? windowDragAreaWithChild(buildTopBarItems())
                          : Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              child: Row(children: buildTopBarItems()),
                            ),
                      const Padding(
                        padding: EdgeInsets.only(left: 25, top: 30, bottom: 12),
                        child: Text(
                          "Qualities",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: NeverScrollableScrollPhysics(),
                        child: Row(
                          children: widget.sources.videos.mapIndexed((i, q) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _videoIndex = i;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _videoIndex == i
                                      // ? const Color.fromARGB(255, 77, 46, 44)
                                      ? selectedColor
                                      : Colors.white.withOpacity(0.12),
                                ),
                                child: Text(
                                  q.quality,
                                  style: TextStyle(
                                    color: _videoIndex == i
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 25,
                          top: 20,
                          bottom: 16,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Audio Tracks",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Expanded(child: SizedBox()),

                            audioSelected
                                ? Text(
                                    _audioIndexs.isNotEmpty
                                        ? _audioIndexs
                                              .map(
                                                (i) => widget
                                                    .sources
                                                    .audios[i]
                                                    .name,
                                              )
                                              .join(", ")
                                        : "",
                                    style: TextStyle(color: selectedColor),
                                  )
                                : Text(
                                    "-",
                                    style: TextStyle(color: Colors.red),
                                  ),

                            if (widget.sources.audios.isNotEmpty) Text(" - "),
                            videoSelected
                                ? Text(
                                    widget.sources.videos[_videoIndex].quality,
                                  )
                                : Text(
                                    "-",
                                    style: TextStyle(color: Colors.red),
                                  ),
                            // Container(child: Text("Tel")),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 60),
                          children: widget.sources.audios.mapIndexed((i, e) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  if (widget.singleAudio) {
                                    _audioIndexs = [i];
                                  } else {
                                    if (_audioIndexs.contains(i)) {
                                      _audioIndexs.remove(i);
                                    } else {
                                      _audioIndexs.add(i);
                                    }
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  // color: _audioIndex == i
                                  //     // ? const Color.fromARGB(255, 77, 46, 44)
                                  //     // : Colors.white.withOpacity(0.05),
                                  //     ? selectedColor
                                  //     : Colors.black,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.audiotrack),
                                    const SizedBox(width: 20),
                                    Text(
                                      e.name,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    if (_audioIndexs.contains(i)) ...[
                                      const Spacer(),
                                      const Icon(Icons.check),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 13,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 36,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ButtonStyle(
                              backgroundColor: const WidgetStatePropertyAll(
                                Color.fromARGB(255, 33, 32, 32),
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          height: 36,
                          child: FilledButton(
                            onPressed: () {
                              String mssg = "";
                              if (!audioSelected) {
                                mssg = "Please Select Audio Track";
                              } else if (!videoSelected) {
                                mssg = "Please Select Video Quality";
                              }
                              if (mssg.isNotEmpty) {
                                log("snackbar");
                                final width = MediaQuery.sizeOf(context).width;
                                final margin = (width - 240) / 2;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      mssg,
                                      textAlign: TextAlign.center,
                                    ),
                                    duration: const Duration(
                                      milliseconds: 2500,
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    // width: 200,
                                    margin: EdgeInsets.symmetric(
                                      vertical: 80,
                                      horizontal: margin,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                );
                              } else {
                                log("download");
                                widget.download(
                                  _audioIndexs,
                                  _videoIndex,
                                  true,
                                );
                                Navigator.of(context).pop();
                              }
                            },
                            style: ButtonStyle(
                              backgroundColor: const WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                widget.singleAudio
                                    ? Icon(Icons.play_arrow)
                                    : Icon(Icons.download),
                                SizedBox(width: 8),
                                Text(
                                  widget.singleAudio ? "Play" : "Download",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
