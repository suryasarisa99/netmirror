import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/screens/movie_abstract.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_cast_section.dart';
import 'package:netmirror/widgets/pv_episode_widget.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_season_selector_bottom_sheet.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_skeletons.dart';
import 'package:netmirror/widgets/sticky_header_delegate.dart';
import 'package:netmirror/widgets/top_buttons.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PVMovieScreen extends MovieScreen {
  const PVMovieScreen(super.id, {super.key});

  @override
  ConsumerState<MovieScreen> createState() => _PVMovieScreenState();
}

class _PVMovieScreenState extends MovieScreenState {
  @override
  OTT ott = OTT.pv;
  @override
  bool extraTabForCast = true;

  int maxDescLines = 3;
  int tabIndex = 0;

  void handleTabChange(int index) {
    if (movie!.isShow && tabIndex == 0 && index == 0) {
      showModalBottomSheet(
        context: context,
        builder: (x) {
          return SeasonSelectorBottomSheet(
            seasons: movie!.seasons,
            selectedSeason: seasonIndex,
            onTap: (seasonNum) {
              log("selected season index: $seasonNum");
              handleSeasonChange(seasonNum);
            },
          );
        },
      );
    } else {
      setState(() {
        tabIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return RefreshIndicator(
      onRefresh: loadDataFromOnline,
      edgeOffset: 50,
      displacement: 60,
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(
          // no bounce
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.black,
              // forceMaterialTransparency: false,
              forceElevated: false,
              title: windowDragAreaWithChild(
                [],
                actions: [
                  TopbarButtons.settingsBtn(context),
                  TopbarButtons.downloadsBtn(context),
                  TopbarButtons.searchBtn(context),
                ],
              ),
              floating: false,
              pinned: true,
              expandedHeight: 60,
            ),
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: CachedNetworkImage(
                      // imageUrl: isDesk
                      //     ? "https://imgcdn.media/pv/c/${widget.id}.jpg"
                      //     : OTT.pv.getImg(widget.id, largeImg: true),
                      imageUrl: OTT.pv.getImg(widget.id, largeImg: true),
                      cacheManager: PvLargeCacheManager.instance,
                      width: size.width,
                      fit: BoxFit.cover,
                      height: size.width / 2.052,
                      // height: OTT.pv
                      // height: 230,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Colors.black, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (movie != null)
              ...buildMainData()
            else
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 450,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildMainData() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                movie!.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.verified, color: Colors.blue, size: 16),
                  SizedBox(width: 5),
                  Text(
                    "Include with Prime",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // play button
              buildMainPlayBtn((text) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: playMovieOrEpisode,
                    style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.white),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ), // Removes the border radius
                        ),
                      ),
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.black),
                        SizedBox(width: 5),
                        Text(
                          text,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Roboto",
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (seasonWatchHistory.isNotEmpty)
                ?buildProgressBar(Colors.white),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    downloadMovie();
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      Color.fromARGB(255, 51, 54, 61),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(8),
                        ), // Removes the border radius
                      ),
                    ),
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        HugeIcons.strokeRoundedDownload04,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        "Download",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: "Roboto",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  MovieScreenActionItem(
                    const Icon(Icons.add, size: 26, color: Colors.white),
                    "Watchlist",
                    () {},
                  ),
                  MovieScreenActionItem(
                    const Icon(
                      HugeIcons.strokeRoundedThumbsUp,
                      size: 26,
                      color: Colors.white,
                    ),
                    "Like",
                    () {},
                  ),
                  MovieScreenActionItem(
                    const Icon(
                      HugeIcons.strokeRoundedShare08,
                      size: 26,
                      color: Colors.white,
                    ),
                    "Share",
                    () {},
                  ),
                  MovieScreenActionItem(
                    const Icon(
                      Icons.flag_outlined,
                      size: 26,
                      color: Colors.white,
                    ),
                    "Reports",
                    () {},
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // description
              GestureDetector(
                onTap: () {
                  setState(() {
                    maxDescLines = maxDescLines == 3 ? 100 : 3;
                  });
                },
                child: Text(
                  movie!.desc,
                  maxLines: maxDescLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // genres
              Row(
                children: [
                  ...movie!.genre.take(3).expandIndexed((i, e) {
                    return [
                      Text(
                        e,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontFamily: "Roboto",
                        ),
                      ),
                      if (i < 2 && i < movie!.genre.length - 1)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          // margin: const EdgeInsets.symmetric(horizontal: 5),
                          margin: const EdgeInsets.only(
                            top: 4,
                            left: 7,
                            right: 7,
                          ),
                        ),
                    ];
                  }),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "${movie!.year}    ${movie!.runtime ?? ""}",
                style: const TextStyle(fontSize: 16, color: Colors.white60),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850]!,
                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      movie!.ua,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850]!,
                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      movie!.hdsd,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (tabController != null)
        SliverPersistentHeader(
          delegate: StickyHeaderDelegate(
            minHeight: 60.0,
            maxHeight: 60.0,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.black),
              child: TabBar(
                controller: tabController,
                indicatorWeight: 1.0,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: Colors.white,
                labelStyle: const TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelColor: Colors.grey,
                labelColor: Colors.white,
                onTap: handleTabChange,
                tabs: [
                  if (movie!.isShow)
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "S${movie!.seasons[seasonIndex].s} E${movie!.seasons[seasonIndex].ep}",
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.expand_more_rounded),
                        ],
                      ),
                    ),
                  // Text("Hi"),
                  if (movie!.suggest.isNotEmpty) const Tab(text: 'Related'),
                  const Tab(text: 'Details'),
                ],
              ),
            ),
          ),
          pinned: true,
        ),
      ...buildsTabSections(),
    ];
  }

  List<Widget> buildCast() {
    return [
      const SizedBox(height: 10),
      CastSection("Genres", movie!.genreStr ?? ''),
      CastSection(
        "Director",
        movie!.director ?? movie!.creator ?? movie!.writer,
      ),
      CastSection("Cast", movie!.cast),
      CastSection("Maturity rating", movie!.ua),
      const CastSection(
        "Viewing rights",
        "Prime Video: Prime Video titles are available for watching by tapping Watch now if you're an Amazon Prime member. Some Prime Video titles are also available to download. Watcha  downloaded Prime Video title as long as it remains in Prime Video. Additional restrictions apply. Please see the Prime Video Usage Rule for more information.",
      ),
      CastSection("Content advisory", movie!.mReason),
      const CastSection(
        "Customer reviews",
        "We don't have any customer reviews.",
      ),
    ];
  }

  Widget buildEpisodes() {
    if (seasonIndex == -1) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("Error:: Season Index is -1")),
      );
    }
    if (movie!.seasons[seasonIndex].episodes == null) {
      log("episodes is null");

      return Skeletonizer.sliver(
        child: SliverList.separated(
          itemCount: 8,
          itemBuilder: (context, index) {
            return const SkeletonEpisodeWidget();
          },
          separatorBuilder: (context, index) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Divider(color: Colors.white24, height: 1),
            );
          },
        ),
      );
    } else {
      final currentEpisodesCount = movie!.seasons[seasonIndex].episodes!.length;
      final extraThere = movie!.seasons[seasonIndex].ep > currentEpisodesCount;
      final episodeCount = extraThere
          ? currentEpisodesCount + 1
          : currentEpisodesCount;

      return SliverList.separated(
        itemCount: episodeCount,
        itemBuilder: (context, index) {
          if (index == episodeCount - 4 && !episodesLoading && extraThere) {
            loadMoreEpisodes();
          }

          if (index == episodeCount - 1 && extraThere) {
            return const Skeletonizer(child: SkeletonEpisodeWidget());
          }
          final episode = movie!.seasons[seasonIndex].episodes![index];
          final depisode = downloads[episode.id];
          final whEpisode = seasonWatchHistory
              .where((wh) => wh.episodeIndex == index)
              .firstOrNull;
          return EpisodeWidget(
            episode: episode,
            dEpisode: depisode,
            wh: whEpisode,
            playEpisode: () => playEpisode(index),
            ott: movie!.ott.value,
            downloadEpisode: () => downloadEpisode(index, seasonIndex),
          );
        },
        separatorBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Divider(color: Colors.white24, height: 1),
          );
        },
      );
    }
  }

  Widget buildRelated() {
    return SliverPadding(
      padding: const EdgeInsets.all(22),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final id = movie!.suggest[index].id;
          return GestureDetector(
            onTap: () {
              GoRouter.of(context).push("/pv-movie", extra: id);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: movie!.ott.getImg(id),
                cacheManager: PvSmallCacheManager.instance,
                fit: BoxFit.cover,
              ),
            ),
          );
        }, childCount: movie!.suggest.length),
      ),
    );
  }

  Widget buildRowRelated() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "     Customers also watched",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              scrollDirection: Axis.horizontal,
              itemCount: movie!.suggest.length,
              itemBuilder: (context, i) {
                final id = movie!.suggest[i].id;
                return GestureDetector(
                  onTap: () {
                    GoRouter.of(context).push("/pv-movie", extra: id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: movie!.ott.getImg(id),
                        cacheManager: PvSmallCacheManager.instance,
                        width: 200,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> buildsTabSections() {
    if (movie!.isShow) {
      return [
        if (tabIndex == 0) buildEpisodes(),
        if (tabIndex == 1 && movie!.suggest.isNotEmpty) buildRelated(),
        if ((movie!.suggest.isNotEmpty && tabIndex == 2) ||
            (movie!.suggest.isEmpty && tabIndex == 1))
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverList.list(children: buildCast()),
          ),
      ];
    } else {
      return [
        if (tabIndex == 0 && movie!.suggest.isNotEmpty) buildRelated(),
        if ((movie!.suggest.isNotEmpty && tabIndex == 1) ||
            (movie!.suggest.isEmpty && tabIndex == 0))
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverList.list(children: buildCast()),
          ),
      ];
    }
  }
}

class MovieScreenActionItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final void Function() onClick;

  const MovieScreenActionItem(this.icon, this.label, this.onClick, {super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 50,
      onPressed: onClick,
      icon: Column(
        children: [
          icon,
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
