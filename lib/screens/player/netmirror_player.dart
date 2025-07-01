import 'dart:async';
import 'dart:developer';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netmirror/api/playlist/get_source.dart';
// import 'package:netmirror/better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/models/netmirror/nm_movie_model.dart';
import 'package:netmirror/models/watch_model.dart';
import 'package:netmirror/provider/AudioTrackProvider.dart';

class NetmirrorPlayer extends ConsumerStatefulWidget {
  const NetmirrorPlayer({super.key, required this.data, required this.wh});
  final NmMovie data;
  final WatchHistoryModel? wh;

  @override
  ConsumerState<NetmirrorPlayer> createState() => _BetterPlayerScreenState();
}

class _BetterPlayerScreenState extends ConsumerState<NetmirrorPlayer> {
  BetterPlayerController? _betterPlayerVideoController;
  bool controlsVisible = true;
  int fitValue = 0;
  final GlobalKey _betterPlayerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (!CookiesManager.isValidResourceKey) {
      log("Invalid resource key");
      await getSource(id: widget.data.id, ott: widget.data.ott);
    }
    final resourceKey = CookiesManager.resourceKey;

    final url =
        '$API_URL/${widget.data.ott.url}hls/${widget.data.id}.m3u8?in=$resourceKey';

    final betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: BetterPlayerVideoFormat.hls,
      cacheConfiguration: BetterPlayerCacheConfiguration(
        maxCacheFileSize: 200 * 1024 * 1024, // 200mb
        maxCacheSize: 5 * 1024 * 1024 * 1024, // 5gb
        preCacheSize: 100 * 1024 * 1024, // 100mb
        key: widget.data.id,
        useCache: true,
      ),
      videoExtension: "m3u8",
      headers: {...headers, 'cookie': 'hd=on'},
      // playerData: widget.data, //@me: added by me
      subtitles: [
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.network,
          name: "English",
          selectedByDefault: true,
          urls: [
            // "https://subs.nfmirrorcdn.top/files/${widget.data.id}/${widget.data.id}-en.srt"
          ],
        ),
      ],
      // notificationConfiguration: BetterPlayerNotificationConfiguration(
      //   showNotification: true,
      //   title: widget.data.title,
      //   // author: "Some author",
      //   imageUrl: widget.data.img,
      //   activityName: "MainActivity",
      // ),
    );

    final controlsConfiguration = BetterPlayerControlsConfiguration(
      backgroundColor: Colors.black,
      enableFullscreen: true,
      progressBarHandleColor: Colors.red,
      progressBarPlayedColor: Colors.red,
      enableSubtitles: true,
      enableSkips: false,
      pipMenuIcon: Icons.picture_in_picture_alt,
      enablePip: true,
      loadingColor: Colors.red,
      controlBarColor: Colors.black.withOpacity(0.2),
      overflowModalColor: Colors.black,
      overflowModalTextColor: Colors.white,
      overflowMenuIconsColor: Colors.white,
      playerTheme: BetterPlayerTheme.material,
    );

    _betterPlayerVideoController = BetterPlayerController(
      // scale: widget.wh != null
      //     ? Size(widget.wh!.scaleX, widget.wh!.scaleY)
      //     : const Size(1, 1),
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
        fullScreenByDefault: true,
        allowedScreenSleep: false,
        fit: BoxFit.cover,
        expandToFill: true,
        placeholderOnTop: true,
        useRootNavigator: true,
        controlsConfiguration: controlsConfiguration,
      ),
      betterPlayerPlaylistConfiguration:
          const BetterPlayerPlaylistConfiguration(initialStartIndex: 0),
      betterPlayerDataSource: betterPlayerDataSource,
    )..setBetterPlayerGlobalKey(_betterPlayerKey);

    _betterPlayerVideoController!.addEventsListener((event) {
      if (event.betterPlayerEventType ==
          BetterPlayerEventType.controlsHiddenEnd) {
        setState(() {
          controlsVisible = false;
        });
      } else if (event.betterPlayerEventType ==
          BetterPlayerEventType.controlsVisible) {
        setState(() {
          controlsVisible = true;
        });
      } else if (event.betterPlayerEventType ==
          BetterPlayerEventType.initialized) {
        log("INItialised");

        final audioTracks =
            _betterPlayerVideoController!.betterPlayerAsmsAudioTracks;
        final qualityTracks =
            _betterPlayerVideoController!.betterPlayerAsmsTracks;
        // betterPlayerAudioController!.setSpeed(200);

        if (audioTracks != null) {
          final preferredAudioTrack = ref
              .read(audioTrackProvider.notifier)
              .pickPreferred(audioTracks);
          _betterPlayerVideoController!.setAudioTrack(preferredAudioTrack);
          if (audioTracks.length > 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      "Selected Audio ${preferredAudioTrack.label ?? preferredAudioTrack.language}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                width: 220,
                backgroundColor: const Color.fromARGB(255, 34, 34, 34),
                duration: const Duration(milliseconds: 3000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    25.0,
                  ), // Adjust radius as needed
                ),
              ),
            );
          }
        }
        // if (widget.wh != null &&
        //     (widget.data.isShow
        //         ? widget.data.currentEpisode!.id == widget.wh!.videoId
        //         : true)) {
        //   log("need to bee seek to :  ${widget.wh!.current / 1000 / 60} min");
        //   _betterPlayerVideoController!.setSpeed(widget.wh!.speed);
        //   _betterPlayerVideoController!
        //       .seekTo(Duration(milliseconds: widget.wh!.current));
        //   _betterPlayerVideoController!.play();
        // } else {
        //   log("wath history is null");
        //   // log("${widget.data.currentEpisode} ${widget.wh!.episodeIndex}");
        // }

        // log("tracks len: ${qualityTracks.length}");
        // final preferedQuality = qualityTracks.firstWhere((track) {
        //   log("b: ${track.bitrate} | f : ${track.frameRate} | s : ${track.height} | w: ${track.width}");
        //   return (track.height != null && track.height == 480);
        // }, orElse: () => qualityTracks.first);
        // log("selected Q: ${preferedQuality.height}");
        // _betterPlayerVideoController!.setTrack(preferedQuality);
      }
    });

    // _betterPlayerVideoController!.addEventsListener((event) {});

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _betterPlayerVideoController != null
            ? BetterPlayer(
                controller: _betterPlayerVideoController!,
                key: _betterPlayerKey,
              )
            : const CircularProgressIndicator(color: Colors.red),
      ),
    );
  }

  @override
  void dispose() {
    _betterPlayerVideoController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
