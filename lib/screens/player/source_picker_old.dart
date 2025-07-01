// import 'package:flutter/material.dart';
// import 'package:netmirror/better_player/better_player.dart';
// import 'package:collection/collection.dart';
// import 'package:netmirror/better_player/src/controls/better_player_controls_state.dart';

// class SourcePicker extends StatefulWidget {
//   const SourcePicker({
//     super.key,
//     required this.audioTracks,
//     required this.qualities,
//     required this.subtitles,
//   });
//   final List<BetterPlayerAsmsAudioTrack> audioTracks;
//   final List<BetterPlayerAsmsTrack> qualities;
//   final List<BetterPlayerSubtitlesSource> subtitles;
//   // final void Function(int) selectAudio;

//   @override
//   State<SourcePicker> createState() => _SourcePickerState();
// }

// class _SourcePickerState extends State<SourcePicker> {
//   Widget _buildTitle(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 15, bottom: 10),
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w900,
//           fontSize: 20,
//         ),
//       ),
//     );
//   }

//   Widget _buildItem(String text) {
//     return Padding(
//         padding: const EdgeInsets.only(top: 15, bottom: 10),
//         child: Row(
//           children: [
//             const SizedBox(width: 50),
//             Text(
//               text,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                   fontSize: 18, color: Color.fromARGB(255, 135, 135, 135)),
//             )
//           ],
//         ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     // final captions = widget.sources.tracks.where((t) => t.kind == "captions");
//     final size = MediaQuery.of(context).size;
//     final isHorizontal = size.width > size.height;
//     const unselectedText =
//         TextStyle(color: Color.fromARGB(255, 135, 135, 135), fontSize: 18);

//     final qualities = widget.qualities.mapIndexed((i, src) {
//       return InkWell(
//         onTap: () {
//           setState(() {
//             // selectedQuality = i;
//           });
//           Navigator.of(context).pop();
//         },
//         child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
//             child: Text(src.height.toString())),
//       );
//     }).toList();

//     final children = [
//       if (widget.audioTracks.length > 1)
//         Container(
//           // padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 35),
//           color: Colors.black,
//           height: size.height,
//           width: isHorizontal ? size.width * 0.4 : size.width * 0.8,
//           // constraints: BoxConstraints(maxHeight: 360, minHeight: 80),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildTitle("Audio"),
//               Container(
//                 height: 1,
//                 color: Colors.grey,
//                 width: double.infinity,
//               ),
//               const SizedBox(height: 12),
//               Expanded(
//                   child: SizedBox(
//                 width: isHorizontal ? size.width * 0.4 : size.width * 0.8,
//                 child: Center(
//                   child: ListView.builder(
//                     itemBuilder: (context, i) {
//                       return InkWell(
//                         onTap: () {
//                           // widget.selectAudio(i);
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 30, vertical: 12),
//                           child: Text(widget.audioTracks[i].label ?? "",
//                               textAlign: TextAlign.start,
//                               style: unselectedText),
//                         ),
//                       );
//                     },
//                     itemCount: widget.audioTracks.length,
//                   ),
//                 ),
//               )),
//             ],
//           ),
//         ),
//       if (widget.qualities.length > 1)
//         Container(
//           color: Colors.red,
//           height: size.height,
//           width: isHorizontal ? size.width * 0.22 : size.width * 0.8,
//           child: Column(
//             children: [
//               _buildTitle("Quality"),
//               const SizedBox(height: 18),
//               isHorizontal
//                   ? Column(
//                       children: qualities,
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     )
//                   : Row(
//                       children: qualities,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                     ),
//             ],
//           ),
//         ),
//       // if (captions.length > 1)
//       //   Column(
//       //     mainAxisAlignment: MainAxisAlignment.center,
//       //     children: captions.map((src) {
//       //       return Container(
//       //           padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
//       //           child: Text(src.label ?? ""));
//       //     }).toList(),
//       //   ),
//     ];
//     return Scaffold(
//         backgroundColor: Colors.black,
//         body: size.width > size.height
//             ? Row(
//                 children: [const SizedBox(width: 40), ...children],
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 // mainAxisAlignment: MainAxisAlignment.center,
//               )
//             : Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: children,
//               ));
//   }
// }
