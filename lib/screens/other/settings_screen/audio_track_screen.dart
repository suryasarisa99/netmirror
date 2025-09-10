import 'dart:convert';
import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/provider/AudioTrackProvider.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';

class AudioTrackSelectionScreen extends ConsumerStatefulWidget {
  const AudioTrackSelectionScreen({super.key});

  @override
  ConsumerState<AudioTrackSelectionScreen> createState() =>
      _AudioTrackSelectionScreenState();
}

class _AudioTrackSelectionScreenState
    extends ConsumerState<AudioTrackSelectionScreen> {
  List<Map<String, String>> _audioTracks = [];
  List<int> _selectedAudioTracks = [];

  @override
  void initState() {
    super.initState();
    initial();
  }

  void initial() async {
    final raw = await rootBundle.loadString("assets/audio-tracks.json");
    final json = jsonDecode(raw) as List;
    final selected = ref.read(audioTrackProvider);
    setState(() {
      _audioTracks = json.map((e) {
        return {
          "label": e["label"] as String,
          "language": e["language"] as String,
        };
      }).toList();
      if (selected.isNotEmpty) {
        _selectedAudioTracks = selected.map((selectedItem) {
          final audioTrackIndex = _audioTracks.indexWhere((x) {
            return x["language"] == selectedItem["language"];
          });
          return audioTrackIndex >= 0 ? audioTrackIndex : 0;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !isDesk,
        title: windowDragAreaWithChild([
          const Text("Audio Language Preferences"),
        ]),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with selected languages
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          190,
                          190,
                          190,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.language,
                        color: Color.fromARGB(255, 255, 255, 255),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Selected Languages",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          152,
                          152,
                          152,
                        ).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${_selectedAudioTracks.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _selectedAudioTracks.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _selectedAudioTracks.mapIndexed((i, t) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                255,
                                246,
                                245,
                                245,
                              ).withValues(alpha: 0.85),
                              // color: const Color(0xFFDC1A28).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAudioTracks.removeAt(i);
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${i + 1}",
                                        style: const TextStyle(
                                          color: Color.fromARGB(255, 0, 0, 0),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _audioTracks[t]["label"]!,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.close,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "No languages selected yet",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
          // Available languages section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                const Text(
                  "Available Languages",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  "${_audioTracks.length} available",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, i) {
                final t = _audioTracks[i];
                final alreadySelected = _selectedAudioTracks.contains(i);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: alreadySelected
                        ? const Color.fromARGB(
                            255,
                            165,
                            165,
                            165,
                          ).withValues(alpha: 0.5)
                        : const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: alreadySelected
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          if (!alreadySelected) {
                            _selectedAudioTracks.add(i);
                          } else {
                            log("removed at $i");
                            _selectedAudioTracks.removeWhere((x) => x == i);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: alreadySelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: alreadySelected
                                      ? Colors.white
                                      : Colors.white54,
                                  width: 2,
                                ),
                              ),
                              child: alreadySelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      size: 12,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t["label"]!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: alreadySelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  // const SizedBox(height: 2),
                                  // Text(
                                  //   t["language"]!,
                                  //   style: TextStyle(
                                  //     color: alreadySelected
                                  //         ? Colors.white70
                                  //         : Colors.white54,
                                  //     fontSize: 11,
                                  //     fontWeight: FontWeight.w400,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            if (alreadySelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "#${_selectedAudioTracks.indexOf(i) + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              itemCount: _audioTracks.length,
            ),
          ),
          // Bottom action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 120,
                  // height: 32,
                  child: OutlinedButton(
                    onPressed: () {
                      GoRouter.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  // height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(audioTrackProvider.notifier)
                          .set(
                            _selectedAudioTracks
                                .map((i) => _audioTracks[i])
                                .toList(),
                          );
                      GoRouter.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
