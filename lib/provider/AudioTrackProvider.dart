import 'dart:convert';
import 'dart:developer';

import 'package:media_kit/media_kit.dart';
import 'package:netmirror/constants.dart';
import 'package:riverpod/riverpod.dart';
import 'package:collection/collection.dart';

class AudioTrackProvider extends StateNotifier<List<Map<String, String>>> {
  AudioTrackProvider() : super([]);

  void initial() async {
    log("initited");
    state = (jsonDecode(sp!.getString("audioTracks") ?? "[]") as List)
        .map(
          (e) => {
            "language": e["language"] as String,
            "label": e["label"] as String,
          },
        )
        .toList();
  }

  void set(List<Map<String, String>> n) {
    state = n;
    sp!.setString("audioTracks", jsonEncode((n)));
  }

  AudioTrack pickPreferred(List<AudioTrack> tracks) {
    // Iterate over the preferred tracks first, to prioritize in the given order
    for (var preferredTrack in state) {
      // Check if any track matches the preferred language or label
      final matchingTrack = tracks.firstWhereOrNull(
        (track) => track.language == preferredTrack["language"],
      );

      if (matchingTrack != null) {
        return matchingTrack;
      } else {
        log(
          "track ${preferredTrack["language"]} | ${preferredTrack["label"]} is Not There",
        );
      }
    }

    // If no preferred match is found, fall back to the first track
    return tracks.first;
  }
}

final audioTrackProvider =
    StateNotifierProvider<AudioTrackProvider, List<Map<String, String>>>(
      (ref) => AudioTrackProvider(),
    );
