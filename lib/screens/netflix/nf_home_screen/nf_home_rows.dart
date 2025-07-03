import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/prime_video/pv_home_model.dart';
import 'package:shared_code/models/ott.dart';

class NfHomeRow extends StatelessWidget {
  const NfHomeRow({super.key, required this.tray});

  final PvHomeTray tray;

  @override
  Widget build(BuildContext context) {
    final double imageHeight = isDesk ? 120 : 185;
    final imageWidth = imageHeight * OTT.none.aspectRatio;

    return SizedBox(
      height: imageHeight + 23 + 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            "     ${tray.title}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20),
              scrollDirection: Axis.horizontal,
              itemCount: tray.postIds.length,
              itemBuilder: (c, j) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () {
                        GoRouter.of(
                          context,
                        ).push("/nf-movie", extra: tray.postIds[j]);
                      },
                      child: CachedNetworkImage(
                        imageUrl: OTT.none.getImg(tray.postIds[j]),
                        // "https://imgcdn.media/poster/v/${tray.postIds[j]}.jpg",
                        // width: 208,
                        // height: 208 / 1.79, // 116.2
                        width: imageWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        cacheManager: PvSmallCacheManager.instance,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NfHomeTop10Row extends StatelessWidget {
  const NfHomeTop10Row({super.key, required this.tray});

  final PvHomeTray tray;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116.2 + 23 + 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            "     ${tray.title}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20),
              scrollDirection: Axis.horizontal,
              itemCount: tray.postIds.length,
              itemBuilder: (c, j) {
                return SizedBox(
                  width: 208 + 8 + 55, // child + padding + svg num
                  child: Stack(
                    children: [
                      Positioned(
                        left: 35,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GestureDetector(
                              onTap: () {
                                GoRouter.of(
                                  context,
                                ).push("/nf-movie", extra: tray.postIds[j]);
                              },
                              child: CachedNetworkImage(
                                imageUrl:
                                    "https://imgcdn.media/poster/v/${tray.postIds[j]}.jpg",
                                width: 208,
                                //because width is 1.79 times of height
                                height: 208 / 1.79,
                                fit: BoxFit.cover,
                                cacheManager: PvSmallCacheManager.instance,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: SvgPicture.asset(
                          "assets/nums/pv/${j + 1}.svg",
                          width: 55,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
