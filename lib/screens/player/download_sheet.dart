// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:netmirror/api/playlist/get_master_hls.dart';
// import 'package:collection/collection.dart';
// import 'package:netmirror/constants.dart';
// import 'package:netmirror/models/download.dart';
// import 'package:netmirror/models/player_data_model.dart';

// Future<void> downloadConfigure(MovieModel data, int seasonIndex,
//     int? episodeIndex, BuildContext context) async {
//   final PlayerData playerData =
//       movieDetailsToEpisode(data, null, seasonIndex, episodeIndex);

//   late final String sourceRaw;

//   final x = await DatabaseHelper.instance.getHslPlaylist(playerData.videoId);
//   if (x == null) {
//     sourceRaw = await getMasterHls(playerData.videoId);
//     DatabaseHelper.instance.addHslPlaylist(playerData.videoId, sourceRaw);
//   } else {
//     sourceRaw = x;
//   }
//   final sources = await parseMasterHls(sourceRaw);

//   int qualityIndex = -1;
//   int audioIndex = -1;
//   bool status = false;

//   if (sources.videos.length > 1 || sources.audios.length > 1) {
//     await showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         // backgroundColor: const Color.fromARGB(255, 22, 20, 20),
//         backgroundColor: Colors.black,
//         builder: (context) {
//           return DownloadSheet(
//               sources: sources,
//               download: (int a, int v, bool s) {
//                 qualityIndex = v;
//                 audioIndex = a;
//                 status = s;
//               });
//         });
//     if (status) {
//       final videoDownloader = VideoDownloader();
//       videoDownloader.startDownload(
//           playerData, sourceRaw, sources, audioIndex, qualityIndex);
//     } else {
//       log("status: $status");
//     }
//   } else {
//     final videoDownloader = VideoDownloader();
//     videoDownloader.startDownload(playerData, sourceRaw, sources, 0, 0);
//   }
// }

// class DownloadSheet extends StatefulWidget {
//   const DownloadSheet({
//     super.key,
//     required this.sources,
//     required this.download,
//   });

//   final void Function(int, int, bool) download;

//   final MasterPlayList sources;

//   @override
//   State<DownloadSheet> createState() => _DownloadSheetState();
// }

// class _DownloadSheetState extends State<DownloadSheet> {
//   bool _isExpanded = false;
//   late int _videoIndex = widget.sources.videos.length <= 2 ? 0 : -1;
//   late int _audioIndex = widget.sources.audios.length == 1 ? 0 : -1;
//   final selectedColor = Colors.white60;

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       expand: false,
//       builder: (context, scrollController) {
//         return NotificationListener(
//           onNotification: (notificaion) {
//             if (notificaion is ScrollMetricsNotification) {
//               setState(() {
//                 _isExpanded = scrollController.offset > 0;
//               });
//             }
//             return true;
//           },
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Stack(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (_isExpanded) const SizedBox(height: 50),
//                     const Padding(
//                         padding: EdgeInsets.only(left: 25, top: 30, bottom: 12),
//                         child: Text("Qualities",
//                             style: TextStyle(
//                                 fontSize: 20, fontWeight: FontWeight.bold))),
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: widget.sources.videos.mapIndexed((i, q) {
//                           return InkWell(
//                             onTap: () {
//                               setState(() {
//                                 _videoIndex = i;
//                               });
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 20, vertical: 8),
//                               margin: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(8),
//                                 color: _videoIndex == i
//                                     // ? const Color.fromARGB(255, 77, 46, 44)
//                                     ? selectedColor
//                                     : Colors.white.withOpacity(0.12),
//                               ),
//                               child: Text(q.quality,
//                                   style: TextStyle(
//                                       color: _videoIndex == i
//                                           ? Colors.black
//                                           : Colors.white)),
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                     Padding(
//                         padding: const EdgeInsets.only(
//                             left: 25, top: 20, bottom: 16),
//                         child: Row(
//                           children: [
//                             const Text("Audio Tracks",
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 )),
//                             const Expanded(child: SizedBox()),
//                             (_videoIndex == -1 ||
//                                     (_audioIndex == -1 &&
//                                         widget.sources.audios.isNotEmpty))
//                                 ? const Text(
//                                     "Please Select",
//                                     style: TextStyle(color: Colors.red),
//                                   )
//                                 : Text(
//                                     "${_audioIndex != -1 ? widget.sources.audios[_audioIndex].name : ""} - ${widget.sources.videos[_videoIndex].quality}",
//                                     style: TextStyle(color: selectedColor),
//                                   ),
//                             // Container(child: Text("Tel")),
//                             const SizedBox(width: 8)
//                           ],
//                         )),
//                     Expanded(
//                       child: ListView(
//                         controller: scrollController,
//                         padding: const EdgeInsets.only(bottom: 60),
//                         children: widget.sources.audios.mapIndexed((i, e) {
//                           return InkWell(
//                             borderRadius: BorderRadius.circular(8),
//                             onTap: () {
//                               setState(() {
//                                 _audioIndex = i;
//                               });
//                             },
//                             child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 16, vertical: 12),
//                                 margin: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(8),
//                                   // color: _audioIndex == i
//                                   //     // ? const Color.fromARGB(255, 77, 46, 44)
//                                   //     // : Colors.white.withOpacity(0.05),
//                                   //     ? selectedColor
//                                   //     : Colors.black,
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     const Icon(Icons.audiotrack),
//                                     const SizedBox(width: 20),
//                                     Text(e.name,
//                                         style: const TextStyle(fontSize: 16)),
//                                     if (_audioIndex == i) ...[
//                                       const Spacer(),
//                                       const Icon(
//                                         Icons.check,
//                                       )
//                                     ]
//                                   ],
//                                 )),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ],
//                 ),
//                 Positioned(
//                   bottom: 12,
//                   left: 0,
//                   right: 13,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       SizedBox(
//                         height: 36,
//                         child: FilledButton(
//                             onPressed: () {
//                               Navigator.of(context).pop();
//                             },
//                             style: ButtonStyle(
//                               backgroundColor: const WidgetStatePropertyAll(
//                                   Color.fromARGB(255, 33, 32, 32)),
//                               shape: WidgetStatePropertyAll(
//                                 RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8)),
//                               ),
//                             ),
//                             child: const Text(
//                               "Cancel",
//                               style: TextStyle(color: Colors.white),
//                             )),
//                       ),
//                       const SizedBox(width: 20),
//                       SizedBox(
//                         height: 36,
//                         child: FilledButton(
//                             onPressed: () {
//                               String mssg = "";
//                               if (_audioIndex == -1 &&
//                                   widget.sources.audios.isNotEmpty) {
//                                 mssg = "Please Select Audio Track";
//                               } else if (_videoIndex == -1 &&
//                                   widget.sources.videos.isNotEmpty) {
//                                 mssg = "Please Select Video Quality";
//                               }
//                               if (mssg.isNotEmpty) {
//                                 log("snakbar");
//                                 ScaffoldMessenger.of(context)
//                                     .showSnackBar(SnackBar(
//                                   content: Text(mssg),
//                                   duration: const Duration(milliseconds: 5000),
//                                   behavior: SnackBarBehavior.floating,
//                                   width: 200,
//                                 ));
//                               } else {
//                                 log("download");
//                                 widget.download(_audioIndex, _videoIndex, true);
//                                 Navigator.of(context).pop();
//                               }
//                             },
//                             style: ButtonStyle(
//                               backgroundColor:
//                                   const WidgetStatePropertyAll(Colors.white),
//                               shape: WidgetStatePropertyAll(
//                                 RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8)),
//                               ),
//                             ),
//                             child: const Text("Download",
//                                 style: TextStyle(color: Colors.black))),
//                       ),
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
