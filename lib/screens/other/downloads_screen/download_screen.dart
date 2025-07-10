import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/db/db.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:netmirror/downloader/download_db.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/screens/external_plyer.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:popover/popover.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key, this.seriesId});
  final String? seriesId;

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

const l = L("download_screen");

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<DownloadItem> downloads = [];
  StreamSubscription<DownloadProgress>? _progressSubscription;

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _progressSubscription = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadDownloads();
    _progressSubscription = Downloader.instance.progressStream.listen((update) {
      final downloadId = update.id;

      l.debug("download id: $downloadId");

      // when new download item added
      // handles both movie and series, in case of movie, both seriesId are null and became equal
      if (update.newItem && update.seriesId == widget.seriesId) {
        DownloadDb.instance.getDownloadItem(downloadId).then((x) {
          if (mounted) {
            setState(() {
              downloads.add(x);
            });
          }
        });
        return;
      }

      final currItem = downloads.firstWhereOrNull((e) => e.id == downloadId);

      if (currItem == null) return;

      final statusChanged =
          (update.status != null) && update.status != currItem.status;

      final progress = update;
      final progressChanged = progress.isAudio!
          ? (progress.progress != currItem.audioProgress)
          : (progress.progress != currItem.videoProgress);

      if ((progressChanged || update.progress == null || statusChanged) &&
          mounted) {
        if (update.totalEpisodesPlus != null) {
          log("Total episodes added in inside IF: ${update.totalEpisodesPlus}");
        }
        setState(() {
          currItem.update(progress);
        });
      }
    });
  }

  Future<void> loadDownloads() async {
    late final List<DownloadItem> x;
    if (widget.seriesId == null) {
      x = await DownloadDb.instance.getAllDownloads();
    } else {
      x = await DownloadDb.instance.getSeriesEpisodes(widget.seriesId!);
    }
    l.info("downloads count: ${x.length}");
    setState(() {
      downloads = x;
    });
  }

  void openMovie(String id, int ottId) {
    GoRouter.of(context).push("/movie/$ottId/$id");
  }

  static void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<bool> requestPermission() async {
    if (true) {
      final result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    }
  }

  Future<void> playWithAndroidVlc(String file) async {
    requestPermission();
    String subtitlePath = "/storage/emulated/0/Download/80243261-ar.srt";
    final intent = AndroidIntent(
      action: 'action_view',
      // data: file.replaceFirst(".mp4", ".m3u8"),
      data: file,
      type: "application/x-mpegURL",
      package: 'org.videolan.vlc',
      arrayArguments: {
        'subtitles_location': [subtitlePath],
        'sub_paths': [subtitlePath],
      },
      arguments: {
        'title': "Outlander",
        'from_start': true,
        'subtitles_location': subtitlePath,
        'sub_file': subtitlePath, // Alternative key that VLC might recognize
        'extra_subtitles_file_path': subtitlePath,
        'position': 1000,
        // 'extra_duration': 1000,
      },
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_GRANT_READ_URI_PERMISSION],
    );
    await intent.launch();
  }

  void delete(String id, String type, int index) {
    if (type == "series") {
      Downloader.deleteSeries(id);
    } else {
      Downloader.deleteItem(id);
    }
    setState(() {
      downloads.removeAt(index);
    });
  }

  void test() async {
    log("support: ${await getApplicationSupportDirectory()}");
    log("app doc: ${await getApplicationDocumentsDirectory()}");
    log("temp: ${await getTemporaryDirectory()}");
    log("ext stor: ${await getExternalStorageDirectory()}");
    log(" ${await getExternalStorageDirectories()}");
    log("downloads: ${await getDownloadsDirectory()}");
    log(" ${await FilePicker.platform.getDirectoryPath()}");
    // log("library: ${await getLibraryDirectory()}");
  }

  @override
  Widget build(BuildContext context) {
    // In your downloads screen
    return DesktopWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          surfaceTintColor: Colors.black,
          backgroundColor: Colors.black,
          automaticallyImplyLeading: !isDesk,
          title: windowDragAreaWithChild([
            const Text('Downloads', style: TextStyle(color: Colors.white)),
          ]),
        ),
        body: ListView.builder(
          itemCount: downloads.length,
          itemBuilder: (context, i) => buildDownloadItem(downloads[i], i),
        ),
      ),
    );
  }

  Widget _buildProgressAudioOrVideo(
    DownloadItem item,
    int firstNonDownloadAudioIndex,
  ) {
    int fndaIndex = firstNonDownloadAudioIndex;
    bool isAudioDownloading = fndaIndex != -1;
    bool showAudioCount = isAudioDownloading && item.audioLangs.length > 1;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: isAudioDownloading
                ? "Progress: Audio ${showAudioCount ? "${fndaIndex + 1}/${item.audioLangs.length}" : ""} $Dot  "
                : "Progress: Video $Dot  ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ), // Default color for the prefix
          ),
          TextSpan(
            text: isAudioDownloading
                ? "${item.audioProgress}%"
                : "${item.videoProgress}%",
            style: TextStyle(fontSize: 14), // Color for the status
          ),
        ],
      ),
    );
  }

  GestureDetector buildDownloadItem(DownloadItem item, int i) {
    final firstNonDownloadAudioIndex = item.audioLangs.indexWhere(
      (e) => !e.status,
    );
    final isAudioDownloading = firstNonDownloadAudioIndex != -1;
    return GestureDetector(
      onTap: () async {
        if (item.type == "series") {
          context.push("/downloads", extra: item.id);
          return;
        }

        l.debug("download id: ${item.id}, playlist path: ${item.playlistPath}");
        final id = item.seriesId ?? item.id;
        final movie = await DB.movie.get(id, item.ottId);
        if (movie == null) {
          log("Movie not found in DB for id: $id");
          return;
        }

        GoRouter.of(context).push(
          "/player",
          extra: (
            url: item.playlistPath,
            movie: movie,
            watchHistory: null,
            seasonNumber: item.seasonNumber,
            episodeNumber: item.episodeNumber,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 30, 30, 30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.thumbnail,
                    fit: BoxFit.cover,
                    width: 160,
                    height: 92,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: Icon(Icons.error, color: Colors.white),
                        ),
                      );
                    },
                    // cacheManager: MovieCacheManager.instance,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text("${item.title} ${item.id} || ${item.movieId}"),
                      Text(
                        item.title,
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),

                      if (item.type == "series") ...[
                        SizedBox(height: 6),
                        Text(
                          "Episodes: ${item.completedEpisodes}/${item.totalEpisodes}",
                        ),
                        SizedBox(height: 6),
                        if (item.completedEpisodes == item.totalEpisodes)
                          Text(
                            "Status: Completed",
                            style: TextStyle(color: DownloadColors.completed),
                          ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              if (item.type == "episode") ...[
                                buildContainer(
                                  "S${item.seasonNumber} $Dot E${item.episodeNumber!}",
                                ),
                              ],
                              buildContainer(item.resolution),
                              buildContainer(item.runtime ?? "Nan"),
                            ],
                          ),
                        ),
                        // Text("id: ${item.id}"),
                        // if (item.status == "downloading")
                        _buildProgressAudioOrVideo(
                          item,
                          firstNonDownloadAudioIndex,
                        ),

                        // else
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    'Status: ', // Default color for the prefix
                              ),
                              TextSpan(
                                text: item.status,
                                style: TextStyle(
                                  color: DownloadColors.fromStatus(item.status),
                                ), // Color for the status
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.type == "series")
                  SizedBox(
                    // color: Colors.red,
                    width: 30,
                    height: 100,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
              ],
            ),

            if (item.status != "completed") SizedBox(height: 2),
            if (item.status != "completed")
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // vertical dots menu
                    _buildIconButton(Icons.more_vert, () {
                      final player = ExternalPlayer.offlineFile;
                      showMenu(
                        position: RelativeRect.fromLTRB(100, 100, 0, 0),
                        context: context,
                        items: [
                          PopupMenuItem(
                            onTap: () => delete(item.id, item.type, i),
                            child: Text("Delete Download"),
                          ),
                          PopupMenuItem(onTap: () {}, child: Text("Select")),
                          PopupMenuItem(
                            onTap: () =>
                                openMovie(item.seriesId ?? item.id, item.ottId),
                            child: Text("Go to Page"),
                          ),

                          // Android specific
                          if (Platform.isAndroid)
                            PopupMenuItem(
                              onTap: () =>
                                  playWithAndroidVlc(item.playlistPath),
                              child: Text("Play With VLC"),
                            ),
                          // MacOS specific
                          if (Platform.isMacOS)
                            PopupMenuItem(
                              onTap: () => player.iina(item.playlistPath),
                              child: Text("Play With IINA"),
                            ),
                          // Windows specific
                          if (Platform.isWindows)
                            PopupMenuItem(
                              onTap: () => player.wmp(item.playlistPath),
                              child: Text("Play With Windows Media Player"),
                            ),

                          if (isDesk) ...[
                            PopupMenuItem(
                              onTap: () => player.vlc(item.playlistPath),
                              child: Text("VLC"),
                            ),
                            PopupMenuItem(
                              onTap: () => player.mpv(item.playlistPath),
                              child: Text("Mpv"),
                            ),
                            PopupMenuItem(
                              onTap: () => player.ffPlay(item.playlistPath),
                              child: Text("FfPlay"),
                            ),
                            PopupMenuItem(
                              onTap: () => player.mplayer(item.playlistPath),
                              child: Text("Mplayer"),
                            ),
                          ],
                          PopupMenuItem(
                            onTap: () => _launchUrl(item.playlistPath),
                            child: Text("Other"),
                          ),
                        ],
                      );
                    }),
                    if (item.status == "paused" || item.status == "failed")
                      _buildIconButton(Icons.play_arrow, () {
                        Downloader.instance.resumeDownload(item.id);
                      }),
                    if (item.status == "downloading" ||
                        item.status == "pending")
                      _buildIconButton(Icons.pause, () {
                        Downloader.instance.pauseDownload(item.id);
                      }),
                    SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value:
                            (item.audioPrefix.isNotEmpty &&
                                    item.audioProgress < 100
                                ? item.audioProgress
                                : item.videoProgress) /
                            100,
                        backgroundColor: Colors.grey[800],
                        color: isAudioDownloading
                            ? Color.fromARGB(255, 116, 116, 116)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton(
        color: Colors.white,
        // style: ButtonStyle(
        //   backgroundColor: WidgetStatePropertyAll(Colors.white10),
        // ),
        onPressed: onPressed,
        iconSize: 18,
        icon: Icon(icon),
      ),
    );
  }

  Widget buildContainer(String text) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: Colors.white)),
    );
  }
}
