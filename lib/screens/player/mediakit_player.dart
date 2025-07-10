import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter/services.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/db/db.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/movie_model.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:netmirror/provider/AudioTrackProvider.dart';

const l = L("player");

class MediaKitPlayer extends ConsumerStatefulWidget {
  const MediaKitPlayer({
    super.key,
    required this.data,
    required this.wh,
    this.seasonNumber,
    this.episodeNumber,
    required this.url,
  });
  final Movie data;
  final WatchHistory? wh;
  final int? seasonNumber;
  final int? episodeNumber;
  final String url;

  @override
  ConsumerState<MediaKitPlayer> createState() => _MediaKitPlayerState();
}

class _MediaKitPlayerState extends ConsumerState<MediaKitPlayer>
    with WidgetsBindingObserver {
  Player? _player;
  VideoController? _controller;
  bool controlsVisible = true;
  bool _isInitialized = false;
  bool _isPipMode = false;
  bool _seeked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupPipListener();
    hideStatusBarAndNavigationBar();
    _initializeVideo();
  }

  void hideStatusBarAndNavigationBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  String get videoId {
    return widget.data.isMovie
        ? widget.data.id
        : widget.data
              .getEpisode(widget.seasonNumber!, widget.episodeNumber!)!
              .id;
  }

  Future<void> _initializeVideo() async {
    l.success("Playing video: ${widget.url}");
    final futureWatchHistory = DB.watchHistory.get(
      videoId: videoId,
      ottId: widget.data.ott.id,
      id: widget.data.id,
    );

    try {
      _player = Player(
        configuration: PlayerConfiguration(
          logLevel: MPVLogLevel.debug,
          ready: () {
            l.info("Player is ready");
          },
        ),
      );

      // _player?.stream.log.listen((log) {
      //   // l.info('MediaKit: [${log.level}] ${log.text}');
      // });

      // Create VideoController
      _controller = VideoController(
        _player!,
        configuration: VideoControllerConfiguration(
          enableHardwareAcceleration: true,
        ),
      );

      _player!.stream.duration.listen((duration) async {
        if (duration.inMicroseconds <= 0 || _seeked) {
          l.info("Video duration is invalid or seeked, skipping seek");
          return;
        }

        final wh = await futureWatchHistory;
        if (wh != null) {
          final seekPosition = Duration(milliseconds: wh.current);
          if (seekPosition.inMilliseconds > 0 &&
              seekPosition.inMilliseconds < duration.inMilliseconds) {
            _seeked = true;
            _player!
                .seek(seekPosition)
                .then((_) {
                  l.info(
                    "Seeking to saved position: ${seekPosition.inMinutes}:${(seekPosition.inSeconds % 60).toString().padLeft(2, '0')}",
                  );
                })
                .catchError((error) {
                  l.error("Error seeking to saved position: $error");
                });
          }
        }
      });

      // Add listeners for track changes
      _player!.stream.tracks.listen((tracks) {
        final audioTracks = tracks.audio
            .where((track) => track.channels != null)
            .toList();
        l.info("tracks length: ${tracks.audio.length}");
        if (audioTracks.isNotEmpty) {
          _selectPreferredAudioTrack(audioTracks);
        }
      });

      // Listen for playback state changes
      _player!.stream.playing.listen((playing) {
        l.info("Player state changed - Playing: $playing");
        if (!playing) {
          _savePlaybackProgress();
        }
      });

      // Listen for completion
      _player!.stream.completed.listen((completed) {
        if (completed) {
          l.info("Video completed - saving final progress");
          _savePlaybackProgress(isCompleted: true);
        }
      });

      // Listen for errors
      _player!.stream.error.listen((error) {
        l.error("Player error: $error");
        // Save progress before handling error
        _savePlaybackProgress();
      });

      // Open media with headers
      await _player!.open(
        Media(
          widget.url,
          httpHeaders: {...headers, 'cookie': 'hd=on', 'Range': 'none'},
        ),
        play: true,
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      l.error("Error initializing MediaKit player: $e");
    }
  }

  void _selectPreferredAudioTrack(List<AudioTrack> audioTracks) {
    // Simple preferred audio track selection
    AudioTrack preferredTrack = ref
        .read(audioTrackProvider.notifier)
        .pickPreferred(audioTracks);

    _selectAudioTrack(preferredTrack);

    if (audioTracks.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          content: Center(
            child: Text(
              "Selected Audio: ${preferredTrack.title ?? preferredTrack.language ?? 'Default'}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          width: 200,
          backgroundColor: const Color.fromARGB(255, 34, 34, 34),
          duration: const Duration(milliseconds: 3000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      );
    }
  } // PiP Mode Methods

  static const MethodChannel _pipChannel = MethodChannel('netmirror.pip');

  void _setupPipListener() {
    _pipChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged') {
        final bool isInPip = call.arguments as bool;
        setState(() {
          _isPipMode = isInPip;
        });
        l.info("PiP mode changed: $isInPip");
      }
    });
  }

  Future<bool> _isPipSupported() async {
    try {
      final bool supported = await _pipChannel.invokeMethod('isPipSupported');
      return supported;
    } catch (e) {
      l.error("Error checking PiP support: $e");
      return false;
    }
  }

  Future<void> _enterPipMode() async {
    try {
      if (!_isPipMode && !isDesk) {
        final bool supported = await _isPipSupported();
        if (!supported) {
          l.error("PiP mode not supported on this device");
          _showPipNotSupportedMessage();
          return;
        }
        l.success("pip supported, entering PiP mode");

        final bool success = await _pipChannel.invokeMethod('enterPip');
        if (!success) {
          _showPipNotSupportedMessage();
        }
      }
    } catch (e) {
      l.error("Failed to enter PiP mode: $e");
      _showPipNotSupportedMessage();
    }
  }

  void _showPipNotSupportedMessage() {
    l.error("Picture-in-Picture mode not supported on this device");
    if (mounted) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Picture-in-Picture mode not supported on this device'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      l.info("App detached - saving playback progress");
      _savePlaybackProgress();
    }

    if (state == AppLifecycleState.paused) {
      // App is going to background, attempt to enter PiP mode
      if (_player != null && _player!.state.playing) {
        _enterPipMode();
        l.info("Attempting to enter PiP mode due to app lifecycle change");
      }
    }
  }

  void _selectAudioTrack(AudioTrack track) {
    _player!.setAudioTrack(track);
    l.info("Selected audio track: ${track.id} - ${track.title}");
  }

  // Save playback progress method
  void _savePlaybackProgress({bool isCompleted = false}) async {
    if (_player == null) return;

    try {
      final position = _player!.state.position;
      final duration = _player!.state.duration;

      if (duration.inMilliseconds > 0) {
        final progressPercentage =
            (position.inMilliseconds / duration.inMilliseconds * 100).clamp(
              0.0,
              100.0,
            );

        l.info(
          "Saving playback progress: ${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')} / ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')} (${progressPercentage.toStringAsFixed(1)}%)",
        );

        // // Create WatchHistoryModel
        final watchHistory = WatchHistory(
          id: widget.data.id,
          ottId: widget.data.ott.id,
          videoId: widget.data.isMovie
              ? widget.data.id
              : widget.data
                    .getEpisode(widget.seasonNumber!, widget.episodeNumber!)!
                    .id,
          title: widget.data.title,
          url: widget.url,
          isShow: !widget.data.isMovie,
          duration: duration.inMilliseconds,
          current: isCompleted
              ? duration.inMilliseconds
              : position.inMilliseconds,
          scaleX: 1.0,
          scaleY: 1.0,
          speed: _player!.state.rate,
          fit: 'contain',
          episodeNumber: widget.data.isMovie ? null : widget.episodeNumber,
          seasonNumber: widget.data.isMovie ? null : widget.seasonNumber,
        );

        // // Save to database
        await DB.watchHistory.save(watchHistory);

        if (isCompleted) {
          l.success("Video completed - marked as watched");
        } else {
          l.info("Progress saved to database");
        }
      }
    } catch (e) {
      l.error("Error saving playback progress: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized && _controller != null
          ? Video(
              controller: _controller!,
              fit: BoxFit.cover,

              // onExitFullscreen: () async {
              //   hideStatusBarAndNavigationBar();
              // },
              // fill: Colors.green,
            )
          : Center(child: const CircularProgressIndicator(color: Colors.red)),
    );
  }

  @override
  void dispose() {
    // Save progress before disposing
    _savePlaybackProgress();

    WidgetsBinding.instance.removeObserver(this);
    _player?.dispose();
    // Restore system UI when leaving the player
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
