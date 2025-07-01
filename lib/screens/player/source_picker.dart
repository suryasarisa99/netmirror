import 'dart:developer';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:netmirror/better_player/better_player.dart';
import 'package:collection/collection.dart';

class SourcePicker extends StatefulWidget {
  const SourcePicker(
    this.controller, {
    super.key,
  });
  final BetterPlayerController controller;
  // const SourcePicker({
  //   super.key,
  //   required this.audioTracks,
  //   required this.qualities,
  //   required this.subtitles,
  // });
  // final List<BetterPlayerAsmsAudioTrack> audioTracks;
  // final List<BetterPlayerAsmsTrack> qualities;
  // final List<BetterPlayerSubtitlesSource> subtitles;

  @override
  State<SourcePicker> createState() => _SourcePickerState();
}

class _SourcePickerState extends State<SourcePicker> {
  int audioIndex = -1;
  int videoIndex = -1;
  int subtitleIndex = -1;

  @override
  void initState() {
    super.initState();

    final audioTracks = widget.controller.betterPlayerAsmsAudioTracks ?? [];
    final qualities = widget.controller.betterPlayerAsmsTracks;
    final subtitles = widget.controller.betterPlayerSubtitlesSourceList;

    // audio tracks
    if (audioTracks.length > 1 &&
        widget.controller.betterPlayerAsmsAudioTrack != null) {
      audioIndex =
          audioTracks.indexOf(widget.controller.betterPlayerAsmsAudioTrack!);
    }

    // qualities
    if (qualities.length > 1 &&
        widget.controller.betterPlayerAsmsTrack != null) {
      videoIndex = qualities.indexOf(widget.controller.betterPlayerAsmsTrack!);
    }

    // subtitles
    if (subtitles.length > 1 &&
        widget.controller.betterPlayerSubtitlesSource != null) {
      subtitleIndex =
          subtitles.indexOf(widget.controller.betterPlayerSubtitlesSource!);
    }
  }

  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildItem(String text, bool selected) {
    return Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 10),
        child: Row(
          children: [
            selected
                ? const Padding(
                    padding: EdgeInsets.only(right: 5),
                    child:
                        SizedBox(width: 35, child: Icon(Icons.check, size: 30)),
                  )
                : const SizedBox(width: 40),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: selected
                    ? Colors.white
                    : const Color.fromARGB(255, 135, 135, 135),
                fontWeight: selected ? FontWeight.bold : null,
              ),
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    // final captions = widget.sources.tracks.where((t) => t.kind == "captions");
    final size = MediaQuery.of(context).size;
    final isHorizontal = size.width > size.height;
    final dash = Container(
      height: 0.8,
      color: const Color.fromARGB(255, 54, 54, 54),
      width: double.infinity,
    );

    final audioTracks = widget.controller.betterPlayerAsmsAudioTracks ?? [];
    final qualities = widget.controller.betterPlayerAsmsTracks;
    final subtitles = widget.controller.betterPlayerSubtitlesSourceList;

    final children = [
      if (audioTracks.length > 1)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle("Audio"),
                dash,
                const SizedBox(height: 12),
                Expanded(
                    child: SizedBox(
                  width: isHorizontal ? size.width * 0.4 : size.width * 0.8,
                  child: Center(
                    child: ListView.builder(
                      itemBuilder: (context, i) {
                        return InkWell(
                            onTap: () {
                              setState(() {
                                audioIndex = i;
                              });
                            },
                            child: _buildItem(
                                audioTracks[i].label ??
                                    audioTracks[i].language ??
                                    "Unknown",
                                audioIndex == i));
                      },
                      itemCount: audioTracks.length,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      if (qualities.length > 1)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle("Quality"),
                dash,
                const SizedBox(height: 18),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: qualities.mapIndexed((i, src) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          videoIndex = i;
                        });
                      },
                      child: _buildItem(
                          "${src.height == 0 ? "Auto" : src.height}",
                          videoIndex == i),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        ),
      if (subtitles.length > 1)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle("Subtitles"),
                dash,
                const SizedBox(height: 18),
                ...subtitles.mapIndexed((i, src) {
                  return InkWell(
                      onTap: () {
                        subtitleIndex = i;
                      },
                      child: _buildItem(src.name ?? "", i == subtitleIndex));
                })
              ],
            ),
          ),
        ),
    ];
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
              // mainAxisAlignment: MainAxisAlignment.center,
            ),
            // Positioned(
            //   bottom: 0,
            //   left: 0,
            //   right: 0,
            //   child: Container(
            //     height: 80,
            //     decoration: BoxDecoration(
            //         gradient: LinearGradient(colors: [
            //       Colors.transparent,
            //       Colors.black.withOpacity(0.6),
            //     ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            //   ),
            // ),
            Positioned(
                bottom: 8,
                right: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 35,
                        child: FilledButton(
                          onPressed: () {
                            GoRouter.of(context).pop();
                          },
                          style: ButtonStyle(
                              backgroundColor: const WidgetStatePropertyAll(
                                  Color.fromARGB(255, 72, 72, 72)),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(horizontal: 25))),
                          child: const Text("Cancel",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        height: 35,
                        child: FilledButton(
                          onPressed: () {
                            log("a: $audioIndex | v: $videoIndex | s: $subtitleIndex");
                            if (audioIndex != -1) {
                              widget.controller
                                  .setAudioTrack(audioTracks[audioIndex]);
                              log("done 1");
                            }
                            if (videoIndex != -1) {
                              widget.controller.setTrack(qualities[videoIndex]);
                              log("done 2");
                            }
                            if (subtitleIndex != -1) {
                              widget.controller.setupSubtitleSource(
                                  subtitles[subtitleIndex]);
                            }
                            GoRouter.of(context).pop();
                          },
                          style: ButtonStyle(
                              backgroundColor:
                                  const WidgetStatePropertyAll(Colors.white),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(horizontal: 25))),
                          child: const Text("Save",
                              style: TextStyle(color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                ))
          ],
        ));
  }
}
