import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netmirror/api/playlist/get_source.dart';
import 'package:flutter/services.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/movie_model.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:video_player/video_player.dart';

const l = L("player");

class ChewiePlayer extends ConsumerStatefulWidget {
  const ChewiePlayer({
    super.key,
    required this.data,
    required this.wh,
    this.seasonIndex,
    this.episodeIndex,
  });
  final Movie data;
  final WatchHistory? wh;
  final int? seasonIndex;
  final int? episodeIndex;

  @override
  ConsumerState<ChewiePlayer> createState() => _ChewiePlayerScreenState();
}

class _ChewiePlayerScreenState extends ConsumerState<ChewiePlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool controlsVisible = true;
  final GlobalKey _playerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    _initializeVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App is going to background, pause video
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        l.info("Video paused due to app lifecycle change");
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is back in foreground
      l.info("App resumed from background");
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.data.isShow && widget.episodeIndex == null) {
      l.error("Episode index is null");
    }
    l.info("resourceKey before: ${CookiesManager.resourceKey}");
    if (!CookiesManager.isValidResourceKey) {
      l.error("Invalid resource key, ${CookiesManager.resourceKey}");
      await getSource(id: widget.data.id, ott: widget.data.ott);
    }
    final resourceKey = CookiesManager.resourceKey;
    if (!CookiesManager.isValidResourceKey) {
      l.error("Invalid resource key after fetching, may t_hash_t is expired");
      return;
    }
    l.info("resourceKey after : $resourceKey");
    late String videoId;
    try {
      videoId = widget.data.isMovie
          ? widget.data.id
          : widget
                .data
                .seasons[widget.seasonIndex ?? 0]
                .episodes![widget.episodeIndex ?? 0]
                .id;
    } catch (e) {
      l.error(
        "Error episodes is null ${widget.data.seasons[widget.episodeIndex!]}, for season ${widget.seasonIndex}",
      );
      return;
    }

    final url =
        '$API_URL/${widget.data.ott.url}hls/$videoId.m3u8?in=$resourceKey';
    l.info("${widget.data.title} (${widget.data.id}) : video url: $url");

    try {
      // Initialize VideoPlayerController with network URL and headers
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: {...headers, 'cookie': 'hd=on'},
      );

      await _videoPlayerController!.initialize();

      // Create ChewieController with configuration
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightGreen,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.red),
          ),
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error: $errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        routePageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              provider,
            ) {
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  return Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Container(
                      alignment: Alignment.center,
                      color: Colors.black,
                      child: provider,
                    ),
                  );
                },
              );
            },
      );

      // Add listener for video player events
      _videoPlayerController!.addListener(_videoPlayerListener);

      // Handle watch history if available
      if (widget.wh != null) {
        final seekPosition = Duration(milliseconds: widget.wh!.current);
        await _videoPlayerController!.seekTo(seekPosition);
        l.info("Seeking to position: ${seekPosition.inMinutes} minutes");
      }

      setState(() {});
    } catch (e) {
      l.error("Error initializing video player: $e");
    }
  }

  void _videoPlayerListener() {
    if (_videoPlayerController != null) {
      if (_videoPlayerController!.value.hasError) {
        l.error(
          "Video player error: ${_videoPlayerController!.value.errorDescription}",
        );
      }

      // Update controls visibility based on player state
      if (_videoPlayerController!.value.isPlaying) {
        setState(() {
          controlsVisible = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        l.info("onPopInvokedWithResult: didPop: $didPop, result: $result");
        if (!didPop) {
          // Exit the video player completely
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child:
              _chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!, key: _playerKey)
              : const CircularProgressIndicator(color: Colors.red),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoPlayerController?.removeListener(_videoPlayerListener);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
