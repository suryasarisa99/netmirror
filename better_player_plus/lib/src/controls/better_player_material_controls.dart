import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:better_player_plus/src/configuration/better_player_controls_configuration.dart';
import 'package:better_player_plus/src/controls/better_player_clickable_widget.dart';
import 'package:better_player_plus/src/controls/better_player_controls_state.dart';
import 'package:better_player_plus/src/controls/better_player_material_progress_bar.dart';
import 'package:better_player_plus/src/controls/better_player_multiple_gesture_detector.dart';
import 'package:better_player_plus/src/controls/better_player_progress_colors.dart';
import 'package:better_player_plus/src/core/better_player_controller.dart';
import 'package:better_player_plus/src/core/better_player_utils.dart';
import 'package:better_player_plus/src/video_player/video_player.dart';
// Flutter imports:
import 'package:flutter/material.dart';

//@me: added by me
import 'dart:math';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:netmirror/constants.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';

class BetterPlayerMaterialControls extends StatefulWidget {
  ///Callback used to send information if player bar is hidden or not
  final Function(bool visbility) onControlsVisibilityChanged;

  ///Controls config
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const BetterPlayerMaterialControls({
    Key? key,
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BetterPlayerMaterialControlsState();
  }
}

//@me: added by me
final GlobalKey<_RotateAndSlideState> _rotateAndSlideForwardKey = GlobalKey();
final GlobalKey<_RotateAndSlideState> _rotateAndSlideBackwardKey = GlobalKey();

class _BetterPlayerMaterialControlsState
    extends BetterPlayerControlsState<BetterPlayerMaterialControls> {
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _displayTapped = false;
  bool _wasLoading = false;
  VideoPlayerController? _controller;
  BetterPlayerController? _betterPlayerController;
  StreamSubscription? _controlsVisibilityStreamSubscription;

  //@me: added by me
  bool _showVolume = false;
  bool _showBrightness = false;
  Timer? _volumeTimer;
  Timer? _brightnessTimer;
  double dragX = 0;
  Timer? _backwardTimer;
  Timer? _forwardTimer;
  bool _showBackwardBtn = false;
  bool _showForwardBtn = false;

  //@me: add this code to track double taps
  bool _isDoubleTapping = false;
  Timer? _doubleTapTimer;

  //@me: optimized vertical drag handler with debounce
  double _lastBrightnessUpdate = 0;
  double _lastVolumeUpdate = 0;
  double _brightnessUpdateThreshold = 0.01;
  double _volumeUpdateThreshold = 0.01;

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  BetterPlayerController? get betterPlayerController => _betterPlayerController;

  @override
  BetterPlayerControlsConfiguration get betterPlayerControlsConfiguration =>
      _controlsConfiguration;

  @override
  Widget build(BuildContext context) {
    return buildLTRDirectionality(_buildMainWidget());
  }

  //@me: add this modified skipForward method to BetterPlayerControlsState
  void skipForward() {
    if (latestValue != null) {
      // Always get the latest position from controller
      final currentPosition = _controller!.value.position;
      final end = latestValue!.duration!.inMilliseconds;
      final skip = (currentPosition +
              Duration(
                  milliseconds: betterPlayerControlsConfiguration
                      .forwardSkipTimeInMilliseconds))
          .inMilliseconds;
      betterPlayerController!.seekTo(Duration(milliseconds: min(skip, end)));

      // If controls are visible, restart the timer
      if (!controlsNotVisible) {
        // cancelAndRestartTimer();
      }
    }
  }

  //@me: add this modified skipBack method to BetterPlayerControlsState
  void skipBack() {
    if (latestValue != null) {
      // Always get the latest position from controller
      final currentPosition = _controller!.value.position;
      final beginning = const Duration().inMilliseconds;
      final skip = (currentPosition -
              Duration(
                  milliseconds: betterPlayerControlsConfiguration
                      .backwardSkipTimeInMilliseconds))
          .inMilliseconds;
      betterPlayerController!
          .seekTo(Duration(milliseconds: max(skip, beginning)));

      // If controls are visible, restart the timer
      if (!controlsNotVisible) {
        cancelAndRestartTimer();
      }
    }
  }

  //@me: added by me
  void handleForward() {
    if (latestValue == null) return;
    _forwardTimer?.cancel();

    // skipForward();
    skipForwardWithState();
    setState(() {
      _showForwardBtn = true;
    });
    _forwardTimer = Timer(const Duration(milliseconds: 2500), () {
      setState(() {
        _showForwardBtn = false;
      });
    });
  }

  //@me: added by me
  void handleBackward() {
    if (latestValue == null) return;
    _backwardTimer?.cancel();
    setState(() {
      _showBackwardBtn = true;
    });
    // skipBack();
    // skipBackWithState();
    _backwardTimer = Timer(const Duration(milliseconds: 2500), () {
      setState(() {
        _showBackwardBtn = false;
      });
    });
  }

  ///Builds main widget of the controls.
  Widget _buildMainWidget() {
    final size = MediaQuery.of(context).size; //@me: added by me
    _wasLoading = isLoading(_latestValue);
    if (_latestValue?.hasError == true) {
      return Container(
        color: Colors.black,
        child: _buildErrorWidget(),
      );
    }
    return GestureDetector(
      //@me: replace onDoubleTapDown with this optimized version
      onDoubleTapDown: (details) {
        final size = MediaQuery.of(context).size;
        double tapPosition = details.localPosition.dx;
        double y = details.localPosition.dy;

        if (latestValue == null) return;

        // Don't handle double taps at the screen edges
        if (y < 100 || y > (size.height - 50)) {
          return;
        }

        // Track that we're processing a double tap
        _isDoubleTapping = true;
        _doubleTapTimer?.cancel();
        _doubleTapTimer = Timer(const Duration(milliseconds: 500), () {
          _isDoubleTapping = false;
        });

        if (((size.width / 2 - 80 < tapPosition) &&
            (size.width / 2 + 80 > tapPosition))) {
          // Center double tap - toggle play/pause
          if (_controller == null) return;
          if (_latestValue!.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        } else if (tapPosition < size.width / 2) {
          // Left double tap - backward
          skipBack();
          _rotateAndSlideBackwardKey.currentState?.resetAndPlay();
          setState(() {
            _showBackwardBtn = true;
          });
          _backwardTimer?.cancel();
          _backwardTimer = Timer(const Duration(milliseconds: 2500), () {
            if (mounted) {
              setState(() {
                _showBackwardBtn = false;
              });
            }
          });
        } else {
          // Right double tap - forward
          skipForward();
          _rotateAndSlideForwardKey.currentState?.resetAndPlay();
          setState(() {
            _showForwardBtn = true;
          });
          _forwardTimer?.cancel();
          _forwardTimer = Timer(const Duration(milliseconds: 2500), () {
            if (mounted) {
              setState(() {
                _showForwardBtn = false;
              });
            }
          });
        }
      },

      //@me: modify onTap to respect double tapping
      onTap: () {
        // Skip if we're processing a double tap
        if (_isDoubleTapping) return;

        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onTap?.call();
        }
        controlsNotVisible
            ? cancelAndRestartTimer()
            : changePlayerControlsNotVisible(true);
      },
      //@me: added by me
      onHorizontalDragStart: (drag) {
        dragX = 0;
      },
      //@me: added by me
      onHorizontalDragUpdate: (drag) {
        dragX += drag.delta.dx;
      },
      //@me: added by me
      onHorizontalDragEnd: (drag) {
        if (latestValue != null) {
          final end = latestValue!.duration!.inMilliseconds;
          final skip = (latestValue!.position +
                  Duration(milliseconds: (dragX * 400).toInt()))
              .inMilliseconds;
          betterPlayerController!
              .seekTo(Duration(milliseconds: min(skip, end)));
        }
      },
      onVerticalDragUpdate: (drag) async {
        final width = context.size?.width ?? 800;
        const centerPercent = 0.3; // 30%
        const leftMin = 0.0;
        final leftMax = (width / 2) * (1 - centerPercent);
        final rightMin = (width / 2) * (1 + centerPercent);
        final rightMax = width;

        final globalX = drag.globalPosition.dx;
        final dy = drag.delta.dy;

        if (globalX >= leftMin && globalX <= leftMax) {
          // Brightness control
          final br = ScreenBrightness.instance;
          final curBrightness = await br.current;
          final newBrightness = (curBrightness - dy / 100).clamp(0.0, 1.0);

          // Only update if change is significant
          if ((newBrightness - curBrightness).abs() >
                  _brightnessUpdateThreshold ||
              DateTime.now().millisecondsSinceEpoch - _lastBrightnessUpdate >
                  100) {
            _lastBrightnessUpdate =
                DateTime.now().millisecondsSinceEpoch.toDouble();
            ScreenBrightness.instance.setScreenBrightness(newBrightness);

            // Update state less frequently
            _brightnessTimer?.cancel();
            setState(() {
              _showBrightness = true;
            });
            _brightnessTimer = Timer(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _showBrightness = false;
                });
              }
            });
          }
        } else if (globalX >= rightMin && globalX <= rightMax) {
          // Volume control with debounce
          final currentVolume = _latestVolume ?? 0.5;
          final newVolume = (currentVolume - dy / 300).clamp(0.0, 1.0);

          // Only update if change is significant
          if ((newVolume - currentVolume).abs() > _volumeUpdateThreshold ||
              DateTime.now().millisecondsSinceEpoch - _lastVolumeUpdate > 100) {
            _lastVolumeUpdate =
                DateTime.now().millisecondsSinceEpoch.toDouble();
            _controller!.setVolume(newVolume);

            // Update state less frequently
            _volumeTimer?.cancel();
            setState(() {
              _showVolume = true;
              _latestVolume = newVolume;
            });
            _volumeTimer = Timer(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _showVolume = false;
                });
              }
            });
          }
        }
      },
      onDoubleTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onDoubleTap?.call();
        }
        cancelAndRestartTimer();
      },
      onLongPress: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onLongPress?.call();
        }
      },
      child: AbsorbPointer(
        absorbing: controlsNotVisible,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_wasLoading)
              Center(child: _buildLoadingWidget())
            else
              _buildHitArea(),

            //@me: added by me
            if (_showBackwardBtn || !controlsNotVisible)
              Positioned(
                  left: 100,
                  top: size.height / 2 - 60,
                  child: RotateAndSlide(
                    forward: false,
                    key: _rotateAndSlideBackwardKey,
                    onInitial: _showBackwardBtn,
                    onPress: () {
                      skipBack();
                      handleBackward();
                    },
                  )),

            //@me: added by me
            if (_showForwardBtn || !controlsNotVisible)
              Positioned(
                  right: 100,
                  top: size.height / 2 - 60,
                  child: RotateAndSlide(
                    forward: true,
                    onInitial: _showForwardBtn,
                    key: _rotateAndSlideForwardKey,
                    onPress: () {
                      skipForward();
                      // cancelAndRestartTimer();
                      handleForward();
                      // _forwardTimer?.cancel();
                    },
                  )),

            //@me: added by me
            if (_showVolume)
              Positioned(
                  left: 26,
                  top: (MediaQuery.of(context).size.height - 200) / 2,
                  bottom: (MediaQuery.of(context).size.height - 200) / 2,
                  child:
                      _VerticalProgressIndicator(level: _latestVolume ?? 0.5)),

            //@me: added by me
            if (_showBrightness)
              Positioned(
                right: 26,
                top: (MediaQuery.of(context).size.height - 200) / 2,
                bottom: (MediaQuery.of(context).size.height - 200) / 2,
                child: FutureBuilder(
                  future: ScreenBrightness.instance.current,
                  builder: (context, snapshot) {
                    return _VerticalProgressIndicator(
                        level: snapshot.data ?? 0.5, isVolume: false);
                  },
                  initialData: 0.5,
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),
            //@me: added by me
            Positioned(
                bottom: 48, left: 10, right: 10, child: _buildBottomBar()),
            //@me: added by me
            Positioned(
                bottom: 6,
                left: 10,
                right: 10,
                child: _buildBottomOptionsBar()),
            //@me: commented by me
            // Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
            _buildNextVideoWidget(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _controller?.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _betterPlayerController;
    _betterPlayerController = BetterPlayerController.of(context);
    _controller = _betterPlayerController!.videoPlayerController;
    _latestValue = _controller!.value;

    if (_oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  //@me: added by me
  Widget _VerticalProgressIndicator(
      {required double level, bool isVolume = true}) {
    late IconData icon;
    if (isVolume) {
      if (level == 0) {
        icon = Icons.volume_mute;
      } else if (level < 0.6)
        icon = Icons.volume_down;
      else
        icon = Icons.volume_up;
    } else {
      if (level < 0.3) {
        icon = Icons.brightness_5;
      } else if (level < 0.6)
        icon = Icons.brightness_6;
      else
        icon = Icons.brightness_7;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text('${(level * 100).toStringAsFixed(0)}%'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 8,
              height: 130,
              color: const Color.fromARGB(255, 38, 38, 38),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 140 * level,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 214, 212, 210),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Icon(icon),
      ],
    );
  }

  Widget _buildErrorWidget() {
    final errorBuilder =
        _betterPlayerController!.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
          context,
          _betterPlayerController!
              .videoPlayerController!.value.errorDescription);
    } else {
      final textStyle = TextStyle(color: _controlsConfiguration.textColor);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: _controlsConfiguration.iconsColor,
              size: 42,
            ),
            Text(
              _betterPlayerController!.translations.generalDefaultError,
              style: textStyle,
            ),
            if (_controlsConfiguration.enableRetry)
              TextButton(
                onPressed: () {
                  _betterPlayerController!.retryDataSource();
                },
                child: Text(
                  _betterPlayerController!.translations.generalRetry,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
      );
    }
  }

  Widget _buildTopBar() {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }

    return Container(
      child: (_controlsConfiguration.enableOverflowMenu)
          ? AnimatedOpacity(
              opacity: controlsNotVisible ? 0.0 : 1.0,
              duration: _controlsConfiguration.controlsHideTime,
              onEnd: _onPlayerHide,
              child: Container(
                height: _controlsConfiguration.controlBarHeight,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_controlsConfiguration.enablePip)
                      _buildPipButtonWrapperWidget(
                          controlsNotVisible, _onPlayerHide)
                    else
                      const SizedBox(),
                    _buildMoreButton(),
                  ],
                ),
              ),
            )
          : const SizedBox(),
    );
  }

  Widget _buildPipButton() {
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        betterPlayerController!.enablePictureInPicture(
            betterPlayerController!.betterPlayerGlobalKey!);
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          betterPlayerControlsConfiguration.pipMenuIcon,
          color: betterPlayerControlsConfiguration.iconsColor,
        ),
      ),
    );
  }

  Widget _buildPipButtonWrapperWidget(
      bool hideStuff, void Function() onPlayerHide) {
    return FutureBuilder<bool>(
      future: betterPlayerController!.isPictureInPictureSupported(),
      builder: (context, snapshot) {
        //@me: added by me
        final bool isPipSupported = true;

        //@me: commented by me
        // final bool isPipSupported = snapshot.data ?? false;
        if (isPipSupported &&
            _betterPlayerController!.betterPlayerGlobalKey != null) {
          return AnimatedOpacity(
            opacity: hideStuff ? 0.0 : 1.0,
            duration: betterPlayerControlsConfiguration.controlsHideTime,
            onEnd: onPlayerHide,
            child: SizedBox(
              height: betterPlayerControlsConfiguration.controlBarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildPipButton(),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildMoreButton() {
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        onShowMoreClicked();
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          _controlsConfiguration.overflowMenuIcon,
          color: _controlsConfiguration.iconsColor,
        ),
      ),
    );
  }

  //@me: added by me
  Widget _buildBottomOptionsBar() {
    return AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        onEnd: _onPlayerHide,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                const Icon(HugeIcons.strokeRoundedDashboardSpeed02),
                const SizedBox(width: 14),
                Text("${_latestValue!.speed}x")
              ],
            ),
            // const Row(
            //   children: [
            //     Icon(Icons.lock_outline_rounded),
            //     SizedBox(width: 14),
            //     Text("Lock")
            //   ],
            // ),
            GestureDetector(
              onTap: () {
                GoRouter.of(context)
                    .push("/source-picker", extra: _betterPlayerController);
              },
              child: const Padding(
                // color: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.subtitles),
                    SizedBox(width: 14),
                    Text("Audio, Captions & Quality")
                  ],
                ),
              ),
            ),
            // Todo: for episodes, show next episode btn
            // if (_betterPlayerController
            //         ?.betterPlayerDataSource?.playerData?.hasNext ??
            //     false)
            //   GestureDetector(
            //       onTap: () {
            //         final playerData = _betterPlayerController!
            //             .betterPlayerDataSource!.playerData!;
            //         final nextPlayerData = playerData.nextEpisode();

            //         final url =
            //             '$API_URL/hls/${nextPlayerData.videoId}.m3u8?in=$key';

            //         _betterPlayerController!
            //             .setupDataSource(BetterPlayerDataSource(
            //           BetterPlayerDataSourceType.network,
            //           url,
            //           videoFormat: BetterPlayerVideoFormat.hls,
            //           cacheConfiguration: const BetterPlayerCacheConfiguration(
            //               maxCacheFileSize: 9999999),
            //           videoExtension: "m3u8",
            //           headers: {...headers, 'cookie': 'hd=on'},
            //           playerData: nextPlayerData,
            //           subtitles: [
            //             BetterPlayerSubtitlesSource(
            //               type: BetterPlayerSubtitlesSourceType.network,
            //               name: "English",
            //               selectedByDefault: true,
            //               urls: [
            //                 // "https://subs.nfmirrorcdn.top/files/${widget.data.id}/${widget.data.id}-en.srt"
            //               ],
            //             ),
            //           ],
            //         ));
            //       },
            //       child: const Row(
            //         children: [
            //           Text("Next Episode"),
            //           SizedBox(width: 8),
            //           Icon(Icons.chevron_right)
            //         ],
            //       ))
          ],
        ));
  }

  Widget _buildBottomBar() {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }
    return AnimatedOpacity(
      opacity: controlsNotVisible ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: Container(
        height: _controlsConfiguration.controlBarHeight + 20.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 75,
              child: Row(
                children: [
                  if (_controlsConfiguration.enablePlayPause)
                    _buildPlayPause(_controller!)
                  else
                    const SizedBox(),
                  if (_betterPlayerController!.isLiveStream())
                    _buildLiveWidget()
                  else
                    _controlsConfiguration.enableProgressText
                        ? Expanded(child: _buildPosition())
                        : const SizedBox(),
                  const Spacer(),
                  if (_controlsConfiguration.enableMute)
                    _buildMuteButton(_controller)
                  else
                    const SizedBox(),
                  if (_controlsConfiguration.enableFullscreen)
                    _buildExpandButton()
                  else
                    const SizedBox(),
                ],
              ),
            ),
            if (_betterPlayerController!.isLiveStream())
              const SizedBox()
            else
              _controlsConfiguration.enableProgressBar
                  ? _buildProgressBar()
                  : const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveWidget() {
    return Text(
      _betterPlayerController!.translations.controlsLive,
      style: TextStyle(
          color: _controlsConfiguration.liveTextColor,
          fontWeight: FontWeight.bold),
    );
  }

  Widget _buildExpandButton() {
    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: BetterPlayerMaterialClickableWidget(
        onTap: _onExpandCollapse,
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: _controlsConfiguration.controlsHideTime,
          child: Container(
            height: _controlsConfiguration.controlBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Icon(
                _betterPlayerController!.isFullScreen
                    ? _controlsConfiguration.fullscreenDisableIcon
                    : _controlsConfiguration.fullscreenEnableIcon,
                color: _controlsConfiguration.iconsColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }
    return Container(
      child: Center(
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: _controlsConfiguration.controlsHideTime,
          child: _buildMiddleRow(),
        ),
      ),
    );
  }

  Widget _buildMiddleRow() {
    return Container(
      color: _controlsConfiguration.controlBarColor,
      width: double.infinity,
      height: double.infinity,
      child: _betterPlayerController?.isLiveStream() == true
          ? const SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_controlsConfiguration.enableSkips)
                  Expanded(child: _buildSkipButton())
                else
                  const SizedBox(),
                Expanded(child: _buildReplayButton(_controller!)),
                if (_controlsConfiguration.enableSkips)
                  Expanded(child: _buildForwardButton())
                else
                  const SizedBox(),
              ],
            ),
    );
  }

  Widget _buildHitAreaClickableButton(
      {Widget? icon, required void Function() onClicked}) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 80.0, maxWidth: 80.0),
      //@me: replaced `BetterPlayerMaterialClickableWidget` with `GestureDetector`
      child: GestureDetector(
        onTap: onClicked,
        child: Align(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(48),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [icon!],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return _buildHitAreaClickableButton(
      icon: Icon(
        _controlsConfiguration.skipBackIcon,
        size: 24,
        color: _controlsConfiguration.iconsColor,
      ),
      onClicked: skipBack,
    );
  }

  Widget _buildForwardButton() {
    return _buildHitAreaClickableButton(
      icon: Icon(
        _controlsConfiguration.skipForwardIcon,
        size: 24,
        color: _controlsConfiguration.iconsColor,
      ),
      onClicked: skipForward,
    );
  }

  Widget _buildReplayButton(VideoPlayerController controller) {
    final bool isFinished = isVideoFinished(_latestValue);
    return _buildHitAreaClickableButton(
      icon: isFinished
          ? Icon(
              Icons.replay,
              size: 42,
              color: _controlsConfiguration.iconsColor,
            )
          : Icon(
              controller.value.isPlaying
                  ? _controlsConfiguration.pauseIcon
                  : _controlsConfiguration.playIcon,
              size: 42,
              color: _controlsConfiguration.iconsColor,
            ),
      onClicked: () {
        if (isFinished) {
          if (_latestValue != null && _latestValue!.isPlaying) {
            if (_displayTapped) {
              changePlayerControlsNotVisible(true);
            } else {
              cancelAndRestartTimer();
            }
          } else {
            _onPlayPause();
            changePlayerControlsNotVisible(true);
          }
        } else {
          _onPlayPause();
        }
      },
    );
  }

  Widget _buildNextVideoWidget() {
    return StreamBuilder<int?>(
      stream: _betterPlayerController!.nextVideoTimeStream,
      builder: (context, snapshot) {
        final time = snapshot.data;
        if (time != null && time > 0) {
          return BetterPlayerMaterialClickableWidget(
            onTap: () {
              _betterPlayerController!.playNextVideo();
            },
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: EdgeInsets.only(
                    bottom: _controlsConfiguration.controlBarHeight + 20,
                    right: 24),
                decoration: BoxDecoration(
                  color: _controlsConfiguration.controlBarColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "${_betterPlayerController!.translations.controlsNextVideoIn} $time...",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildMuteButton(
    VideoPlayerController? controller,
  ) {
    return BetterPlayerMaterialClickableWidget(
      onTap: () {
        cancelAndRestartTimer();
        if (_latestValue!.volume == 0) {
          _betterPlayerController!.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller!.value.volume;
          _betterPlayerController!.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: ClipRect(
          child: Container(
            height: _controlsConfiguration.controlBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              (_latestValue != null && _latestValue!.volume > 0)
                  ? _controlsConfiguration.muteIcon
                  : _controlsConfiguration.unMuteIcon,
              color: _controlsConfiguration.iconsColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPause(VideoPlayerController controller) {
    return BetterPlayerMaterialClickableWidget(
      key: const Key("better_player_material_controls_play_pause_button"),
      onTap: _onPlayPause,
      child: Container(
        height: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          controller.value.isPlaying
              ? _controlsConfiguration.pauseIcon
              : _controlsConfiguration.playIcon,
          color: _controlsConfiguration.iconsColor,
        ),
      ),
    );
  }

  Widget _buildPosition() {
    final position =
        _latestValue != null ? _latestValue!.position : Duration.zero;
    final duration = _latestValue != null && _latestValue!.duration != null
        ? _latestValue!.duration!
        : Duration.zero;

    return Padding(
      padding: _controlsConfiguration.enablePlayPause
          ? const EdgeInsets.only(right: 24)
          : const EdgeInsets.symmetric(horizontal: 22),
      child: RichText(
        text: TextSpan(
            text: BetterPlayerUtils.formatDuration(position),
            style: TextStyle(
              fontSize: 10.0,
              color: _controlsConfiguration.textColor,
              decoration: TextDecoration.none,
            ),
            children: <TextSpan>[
              TextSpan(
                text: ' / ${BetterPlayerUtils.formatDuration(duration)}',
                style: TextStyle(
                  fontSize: 10.0,
                  color: _controlsConfiguration.textColor,
                  decoration: TextDecoration.none,
                ),
              )
            ]),
      ),
    );
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    changePlayerControlsNotVisible(false);
    _displayTapped = true;
  }

  Future<void> _initialize() async {
    _controller!.addListener(_updateState);

    _updateState();

    if ((_controller!.value.isPlaying) ||
        _betterPlayerController!.betterPlayerConfiguration.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        changePlayerControlsNotVisible(false);
      });
    }

    _controlsVisibilityStreamSubscription =
        _betterPlayerController!.controlsVisibilityStream.listen((state) {
      changePlayerControlsNotVisible(!state);
      if (!controlsNotVisible) {
        cancelAndRestartTimer();
      }
    });
  }

  void _onExpandCollapse() {
    changePlayerControlsNotVisible(true);
    _betterPlayerController!.toggleFullScreen();
    _showAfterExpandCollapseTimer =
        Timer(_controlsConfiguration.controlsHideTime, () {
      setState(() {
        cancelAndRestartTimer();
      });
    });
  }

  void _onPlayPause() {
    bool isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue!.position >= _latestValue!.duration!;
    }

    if (_controller!.value.isPlaying) {
      changePlayerControlsNotVisible(false);
      _hideTimer?.cancel();
      _betterPlayerController!.pause();
    } else {
      cancelAndRestartTimer();

      if (!_controller!.value.initialized) {
      } else {
        if (isFinished) {
          _betterPlayerController!.seekTo(const Duration());
        }
        _betterPlayerController!.play();
        _betterPlayerController!.cancelNextVideoTimer();
      }
    }
  }

  void _startHideTimer() {
    if (_betterPlayerController!.controlsAlwaysVisible) {
      return;
    }
    _hideTimer = Timer(const Duration(milliseconds: 3000), () {
      changePlayerControlsNotVisible(true);
    });
  }

  void _updateState() {
    if (mounted) {
      if (!controlsNotVisible ||
          isVideoFinished(_controller!.value) ||
          _wasLoading ||
          isLoading(_controller!.value)) {
        setState(() {
          _latestValue = _controller!.value;
          if (isVideoFinished(_latestValue) &&
              _betterPlayerController?.isLiveStream() == false) {
            changePlayerControlsNotVisible(false);
          }
        });
      }
    }
  }

  Widget _buildProgressBar() {
    return Expanded(
      flex: 40,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: BetterPlayerMaterialVideoProgressBar(
          _controller,
          _betterPlayerController,
          onDragStart: () {
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            _startHideTimer();
          },
          onTapDown: () {
            cancelAndRestartTimer();
          },
          colors: BetterPlayerProgressColors(
              playedColor: _controlsConfiguration.progressBarPlayedColor,
              handleColor: _controlsConfiguration.progressBarHandleColor,
              bufferedColor: _controlsConfiguration.progressBarBufferedColor,
              backgroundColor:
                  _controlsConfiguration.progressBarBackgroundColor),
        ),
      ),
    );
  }

  void _onPlayerHide() {
    _betterPlayerController!.toggleControlsVisibility(!controlsNotVisible);
    widget.onControlsVisibilityChanged(!controlsNotVisible);
  }

  Widget? _buildLoadingWidget() {
    if (_controlsConfiguration.loadingWidget != null) {
      return Container(
        color: _controlsConfiguration.controlBarColor,
        child: _controlsConfiguration.loadingWidget,
      );
    }

    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.loadingColor),
    );
  }
}

//@me: improved Netflix-style animation class
class RotateAndSlide extends StatefulWidget {
  const RotateAndSlide({
    required this.forward,
    required this.onPress,
    super.key,
    required this.onInitial,
  });
  final bool forward;
  final void Function() onPress;
  final bool onInitial;
  @override
  _RotateAndSlideState createState() => _RotateAndSlideState();
}

class _RotateAndSlideState extends State<RotateAndSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Rotation animation - more subtle rotation for Netflix-like effect
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: widget.forward ? 0.12 : -0.12),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.forward ? 0.12 : -0.12, end: 0.0),
        weight: 70,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Scale animation for popup effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0),
        weight: 70,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Text slide animation
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end:
          Offset(widget.forward ? 1.2 : -1.2, -0.8), // Move slightly upward too
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Opacity animation
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // Start the animation if needed
    if (widget.onInitial) _controller.forward();
  }

  void resetAndPlay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        resetAndPlay();
        widget.onPress();
      },
      child: SizedBox(
        height: 120,
        width: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Combined animation for icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * pi,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.forward
                      ? HugeIcons.strokeRoundedGoForward10Sec
                      : HugeIcons.strokeRoundedGoBackward10Sec,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
            // Text animation
            FadeTransition(
              opacity: _opacityAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    // color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '10 sec',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
