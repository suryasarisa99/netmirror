import 'dart:convert';
import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    const style = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w300,
      color: Colors.white70,
    );
    const hStyle = TextStyle(
        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          surfaceTintColor: Colors.black,
          title: windowDragAreaWithChild(
            [
              const Text("Preffer Audio Track"),
            ],
          ),
        ),
        body: Column(
          children: [
            _selectedAudioTracks.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: _selectedAudioTracks.mapIndexed((i, t) {
                      return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAudioTracks.removeAt(i);
                              });
                            },
                            child: Row(
                              children: [
                                Text("${i + 1}"),
                                const SizedBox(width: 8),
                                Text(_audioTracks[t]["language"]!,
                                    textAlign: TextAlign.center, style: style),
                              ],
                            ),
                          ));
                    }).toList()),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                    child: Text("Not Selected",
                        style: TextStyle(color: Colors.white70, fontSize: 17)),
                  ),
            Container(
              height: 0.8,
              color: const Color.fromARGB(255, 54, 54, 54),
              width: double.infinity,
            ),
            Expanded(
                child: ListView.builder(
              itemBuilder: (context, i) {
                final t = _audioTracks[i];
                final alreadySelected = _selectedAudioTracks.contains(i);
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        padding: const EdgeInsets.all(8),
                        child: Text(t["label"]!,
                            textAlign: TextAlign.center,
                            style: alreadySelected ? hStyle : style)),
                  ),
                );
              },
              itemCount: _audioTracks.length,
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () {
                      GoRouter.of(context).pop();
                    },
                    style: ButtonStyle(
                        backgroundColor: const WidgetStatePropertyAll(
                            Color.fromARGB(255, 72, 72, 72)),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 32))),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 20),
                  FilledButton(
                    onPressed: () {
                      ref.read(audioTrackProvider.notifier).set(
                          _selectedAudioTracks
                              .map((i) => _audioTracks[i])
                              .toList());
                      GoRouter.of(context).pop();
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            const WidgetStatePropertyAll(Colors.white),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 32))),
                    child: const Text("Save",
                        style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
