import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

var random = Random();

class SkeletonEpisodeWidget extends StatelessWidget {
  final String k;
  const SkeletonEpisodeWidget({
    super.key,
    this.k = "yy",
  });

  @override
  Widget build(BuildContext context) {
    // random string
    return Container(
      width: double.infinity,
      color: Colors.black38,
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: 75,
            width: 130,
            child: DecoratedBox(
                decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(4),
            )),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("a" * (12 + random.nextInt(10))),
                const SizedBox(height: 4),
                Text("a" * (8 + random.nextInt(10))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonEpisodesList extends StatelessWidget {
  const SkeletonEpisodesList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      child: SliverList.separated(
        itemCount: 8,
        itemBuilder: (context, index) {
          return const SkeletonEpisodeWidget();
        },
        separatorBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Divider(
              color: Colors.white24,
              height: 1,
            ),
          );
        },
      ),
    );
  }
}
