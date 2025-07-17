import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netmirror/provider/AudioTrackProvider.dart';

class AudiosPreviewWidget extends ConsumerWidget {
  const AudiosPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audios = ref.watch(audioTrackProvider);
    log('Audios: $audios');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: audios
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(a['label']!, style: TextStyle(color: Colors.grey)),
              ),
            )
            .toList(),
      ),
    );
  }
}
