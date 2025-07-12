import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/home_models.dart';
import 'package:netmirror/screens/hotstar/hotstar_home/hotstar_home_screen.dart';
import 'package:shared_code/models/ott.dart';

class HotstarStudioList extends StatelessWidget {
  final String? curr;
  const HotstarStudioList({this.curr, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            "Studios",
            style: TextStyle(color: Color(0xFFe2e6f1), fontSize: 16),
          ),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: 16),
              ...studios.mapIndexed((i, e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: curr != e.studio
                        ? () {
                            GoRouter.of(context).push(
                              '/hotstar-home?studio=${e.studio}',
                              extra: 0,
                            );
                          }
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        "assets/hotstar/studio-lists/${e.studio}.png",
                        width: 115,
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class HotstarRows extends StatelessWidget {
  final List<HomeTray> trays;
  final OTT ott = OTT.hotstar;
  const HotstarRows({required this.trays, super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemBuilder: (context, index) {
        final tray = trays[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: buildRow(tray),
        );
      },
      itemCount: trays.length,
    );
  }

  Widget buildRow(HomeTray tray) {
    final height = 165.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            tray.title,
            style: TextStyle(color: Color(0xFFe2e6f1), fontSize: 16),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          height: height,
          child: ListView.separated(
            padding: EdgeInsets.only(left: 12),
            scrollDirection: Axis.horizontal,
            itemCount: tray.postIds.length,
            itemBuilder: (context, index) {
              final id = tray.postIds[index];
              return InkWell(
                onTap: () => GoRouter.of(context).push('/movie/${ott.id}/$id'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: ott.getImg(id),
                    cacheManager: PvSmallCacheManager.instance,
                    width: height * ott.aspectRatio,
                    height: height,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) {
              return SizedBox(width: 8);
            },
          ),
        ),
      ],
    );
  }
}
