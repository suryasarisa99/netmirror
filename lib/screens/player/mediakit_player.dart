import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:netmirror/api/playlist/get_source.dart';
import 'package:flutter/services.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/netmirror/nm_movie_model.dart';
import 'package:netmirror/models/watch_model.dart';
import 'package:netmirror/provider/AudioTrackProvider.dart';

const l = L("player");

class MediaKitPlayer extends ConsumerStatefulWidget {
  const MediaKitPlayer({
    super.key,
    required this.data,
    required this.wh,
    this.seasonIndex,
    this.episodeIndex,
  });
  final Movie data;
  final WatchHistoryModel? wh;
  final int? seasonIndex;
  final int? episodeIndex;

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
  List<VideoTrack> _videoTracks = [];
  List<AudioTrack> _audioTracks = [];
  VideoTrack? _selectedVideoTrack;
  AudioTrack? _selectedAudioTrack;

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
      // App is going to background, attempt to enter PiP mode
      if (_player != null && _player!.state.playing) {
        _enterPipMode();
        l.info("Attempting to enter PiP mode due to app lifecycle change");
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is back in foreground
      setState(() {
        _isPipMode = false;
      });
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
      // Initialize MediaKit Player
      _player = Player();

      // Create VideoController
      _controller = VideoController(_player!);

      // Add listeners for track changes
      _player!.stream.tracks.listen((tracks) {
        setState(() {
          _videoTracks = tracks.video;
          _audioTracks = tracks.audio;
        });

        // Auto-select preferred audio track
        if (_audioTracks.isNotEmpty && _selectedAudioTrack == null) {
          _selectPreferredAudioTrack();
        }

        l.info(
          "Available tracks - Video: ${_videoTracks.length}, Audio: ${_audioTracks.length}",
        );
      });

      // Listen for playback state changes
      _player!.stream.playing.listen((playing) {
        l.info("Player state changed - Playing: $playing");
      });

      // Listen for position changes
      _player!.stream.position.listen((position) {
        // You can save watch progress here
      });

      // Listen for errors
      _player!.stream.error.listen((error) {
        if (error != null) {
          l.error("Player error: $error");
        }
      });

      // Open media with headers
      await _player!.open(
        Media(
          url,
          httpHeaders: {...headers, 'cookie': 'hd=on', 'Range': 'none'},
        ),
        play: true,
      );

      // Handle watch history if available
      if (widget.wh != null) {
        final seekPosition = Duration(milliseconds: widget.wh!.current);
        await _player!.seek(seekPosition);
        l.info("Seeking to position: ${seekPosition.inMinutes} minutes");
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      l.error("Error initializing MediaKit player: $e");
    }
  }

  void _selectPreferredAudioTrack() {
    if (_audioTracks.isEmpty) return;

    // Simple preferred audio track selection
    AudioTrack preferredTrack = _audioTracks.first;
    for (final track in _audioTracks) {
      if (track.language?.toLowerCase().contains('en') == true) {
        preferredTrack = track;
        break;
      }
    }

    _selectAudioTrack(preferredTrack);

    if (_audioTracks.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                "Selected Audio: ${preferredTrack.title ?? preferredTrack.language ?? 'Default'}",
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
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
      );
    }
  }

  void _selectVideoTrack(VideoTrack track) {
    _player!.setVideoTrack(track);
    setState(() {
      _selectedVideoTrack = track;
    });
    l.info("Selected video track: ${track.id} - ${track.title}");
  }

  void _selectAudioTrack(AudioTrack track) {
    _player!.setAudioTrack(track);
    setState(() {
      _selectedAudioTrack = track;
    });
    l.info("Selected audio track: ${track.id} - ${track.title}");
  }

  void _showTrackSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quality & Audio Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Video Quality Selection
              if (_videoTracks.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Video Quality:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                ...(_videoTracks.map(
                  (track) => ListTile(
                    title: Text(
                      track.title ?? 'Quality ${track.id}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${track.w ?? 'Unknown'}x${track.h ?? 'Unknown'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    leading: Radio<VideoTrack>(
                      value: track,
                      groupValue: _selectedVideoTrack,
                      onChanged: (value) {
                        if (value != null) _selectVideoTrack(value);
                        Navigator.pop(context);
                      },
                      activeColor: Colors.red,
                    ),
                    onTap: () {
                      _selectVideoTrack(track);
                      Navigator.pop(context);
                    },
                  ),
                )),
                const Divider(color: Colors.grey),
              ],

              // Audio Track Selection
              if (_audioTracks.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Audio Language:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                ...(_audioTracks.map(
                  (track) => ListTile(
                    title: Text(
                      track.title ?? track.language ?? 'Audio ${track.id}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Channels: ${track.channels?.toString() ?? "Unknown"}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    leading: Radio<AudioTrack>(
                      value: track,
                      groupValue: _selectedAudioTrack,
                      onChanged: (value) {
                        if (value != null) _selectAudioTrack(value);
                        Navigator.pop(context);
                      },
                      activeColor: Colors.red,
                    ),
                    onTap: () {
                      _selectAudioTrack(track);
                      Navigator.pop(context);
                    },
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
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
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: _isInitialized && _controller != null
                  ? Video(controller: _controller!)
                  : const CircularProgressIndicator(color: Colors.red),
            ),

            // Quality/Audio selection button
            if (_isInitialized &&
                (_videoTracks.isNotEmpty || _audioTracks.isNotEmpty))
              Positioned(
                top: 50,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.black54,
                  onPressed: _showTrackSelection,
                  child: const Icon(Icons.settings, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
