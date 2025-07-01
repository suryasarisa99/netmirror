// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:netmirror/better_player/better_player.dart';
// import 'package:path/path.dart' as p;

// class OfflinePlayer extends StatefulWidget {
//   // const OfflinePlayer({Key? key, required this.data}) : super(key: key);
//   // final PlayerData data;
//   const OfflinePlayer({super.key, required this.id});
//   final int id;

//   @override
//   State<OfflinePlayer> createState() => _OfflinePlayerState();
// }

// class _OfflinePlayerState extends State<OfflinePlayer> {
//   BetterPlayerController? _betterPlayerVideoController;
//   final GlobalKey _betterPlayerKey = GlobalKey();

//   @override
//   void initState() {
//     super.initState();
//     _initializeVideo();
//   }

//   Future<void> _initializeVideo() async {
//     final download = await DatabaseHelper.instance.getDownload(widget.id);

//     final path = p.join(download!['file_path']! as String, "playlist.m3u8");
//     log(path);
//     final betterPlayerDataSource = BetterPlayerDataSource(
//       BetterPlayerDataSourceType.file,
//       path,
//       videoFormat: BetterPlayerVideoFormat.hls,
//       videoExtension: "m3u8",
//       subtitles: [
//         BetterPlayerSubtitlesSource(
//           type: BetterPlayerSubtitlesSourceType.network,
//           name: "English",
//           selectedByDefault: true,
//           urls: [
//             "https://subs.nfmirrorcdn.top/files/${widget.id}/${widget.id}-en.srt"
//           ],
//         ),
//       ],
//     );

//     _betterPlayerVideoController = BetterPlayerController(
//       BetterPlayerConfiguration(
//         autoPlay: true,
//         looping: true,
//         fullScreenByDefault: true,
//         fit: BoxFit.cover,
//         expandToFill: true,
//         placeholderOnTop: false,
//         useRootNavigator: true,
//         controlsConfiguration: BetterPlayerControlsConfiguration(
//           backgroundColor: Colors.black,
//           enableFullscreen: true,
//           progressBarHandleColor: Colors.red,
//           progressBarPlayedColor: Colors.red,
//           enableSubtitles: true,
//           enablePip: true,
//           enableSkips: false,
//           // enableAudioTracks: false,
//           pipMenuIcon: Icons.picture_in_picture_alt,
//           loadingColor: Colors.red,
//           overflowModalColor: Colors.black,
//           overflowModalTextColor: Colors.white,
//           overflowMenuIconsColor: Colors.white,
//           controlBarColor: Colors.black
//               .withOpacity(0.2), // its actually controls background color
//           overflowMenuCustomItems: [
//             BetterPlayerOverflowMenuItem(
//               Icons.picture_in_picture_alt,
//               "Enter PiP Mode",
//               () => _enterPipMode(),
//             ),
//           ],
//         ),
//       ),
//       betterPlayerDataSource: betterPlayerDataSource,
//     )..setBetterPlayerGlobalKey(_betterPlayerKey);

//     // ..getFit();
//     // _betterPlayerVideoController!.addEventsListener((event) {
//     //   if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
//     //     final _audioTracks =
//     //         _betterPlayerVideoController!.betterPlayerAsmsAudioTracks;
//     //     // final _qualityTracks =
//     //     //     _betterPlayerVideoController!.betterPlayerAsmsTracks;
//     //     log("length of audioTracks: ${_audioTracks?.length}");
//     //     _audioTracks?.forEach((track) {
//     //       log("${track.language}   ||  ${track.label}");
//     //     });
//     //   }
//     // });

//     // betterPlayerAudioController!.setSpeed(200);

//     // ..setAudioTrack(audioTrack);

//     setState(() {});
//   }

//   void _enterPipMode() {
//     _betterPlayerVideoController?.enablePictureInPicture(_betterPlayerKey);
//   }

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setPreferredOrientations(
//         [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
//     return AnnotatedRegion(
//       value: const SystemUiOverlayStyle(
//         statusBarIconBrightness: Brightness.dark,
//       ),
//       child: Scaffold(
//           backgroundColor: Colors.black,
//           body: Center(
//             child: _betterPlayerVideoController != null
//                 ? BetterPlayer(
//                     controller: _betterPlayerVideoController!,
//                     key: _betterPlayerKey,
//                   )
//                 : const CircularProgressIndicator(color: Colors.red),
//           )),
//     );
//   }

//   @override
//   void dispose() {
//     _betterPlayerVideoController?.dispose();
//     SystemChrome.setPreferredOrientations(
//         [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
//     super.dispose();
//   }
// }
