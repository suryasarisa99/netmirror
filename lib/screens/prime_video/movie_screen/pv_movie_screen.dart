import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/screens/movie_abstract.dart';
import 'package:netmirror/screens/movie_ui_abstract.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_cast_section.dart';
import 'package:netmirror/utils/nav.dart';
import 'package:netmirror/widgets/pv_episode_widget.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_season_selector_bottom_sheet.dart';
import 'package:netmirror/widgets/sticky_header_delegate.dart';
import 'package:netmirror/widgets/top_buttons.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';

class PVMovieScreen extends MovieScreenUi {
  const PVMovieScreen(super.id, {super.key});

  @override
  ConsumerState<MovieScreen> createState() => _PVMovieScreenState();
}

class _PVMovieScreenState extends MovieScreenUiState {
  @override
  OTT ott = OTT.pv;
  @override
  bool extraTabForCast = true;

  int maxDescLines = 3;

  void handleTabChange(int index) {
    if (movie!.isShow && tabIndex == 0 && index == 0) {
      showModalBottomSheet(
        context: context,
        builder: (x) {
          return SeasonSelectorBottomSheet(
            seasons: movie!.seasons,
            selectedSeason: seasonNumber,
            onTap: (seasonNum) {
              log("selected season number: $seasonNum");
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
    return screenBuilder(
      bg: Colors.black,
      sliverAppbar: buildSliverAppbar(),
      poster: buildPoster(),
      headers: buildMovieDetails(),
      tabs: [
        if (movie?.isShow ?? false) buildEpisodes(),
        buildRelated(),
        buildCast(),
      ],
    );
  }

  Widget buildSliverAppbar() {
    return SliverAppBar(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
      automaticallyImplyLeading: !isDesk,
      toolbarHeight: isDesk ? 28 : 48,
      forceElevated: false,
      title: windowDragAreaWithChild(
        [],
        actions: [
          TopbarButtons.settingsBtn(context),
          TopbarButtons.downloadsBtn(context),
          TopbarButtons.searchBtn(context, ott.id),
        ],
      ),
      floating: false,
      pinned: true,
      // expandedHeight: 60,
    );
  }

  Widget buildPoster() {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: CachedNetworkImage(
            imageUrl: OTT.pv.getImg(widget.id, largeImg: true),
            cacheManager: PvLargeCacheManager.instance,
            width: size.width,
            fit: BoxFit.cover,
            height: size.width / 2.052,
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
    );
  }

  List<Widget> buildMovieDetails() {
    if (movie == null) return [];
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
                  // MovieScreenActionItem(
                  //   const Icon(Icons.add, size: 26, color: Colors.white),
                  //   "Watchlist",
                  //   () {},
                  // ),
                  SizedBox.square(
                    // dimension: 80,
                    child: MovieScreenActionItem(
                      LottieBuilder.asset(
                        // "assets/lottie/hotstar/watchlist_animation_blue.json",
                        "assets/lottie/my-list-plus-to-check.json",
                        controller: watchlistAnimationController,
                        height: 40,
                        onLoaded: (composition) {
                          if (inWatchlist) {
                            watchlistAnimationController.value = 1.0;
                          } else {
                            watchlistAnimationController.value = 0.0;
                          }
                        },
                      ),
                      "My List",
                      handleAddWatchlist,
                    ),
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
                    shareDeepLinkUrl,
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
                  if (movie!.hdsd != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[850]!,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        movie!.hdsd!,
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
                            "S$seasonNumber E${movie!.getSeason(seasonNumber).ep}",
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
      // ...buildsTabSections(),
    ];
  }

  Widget buildCast() {
    if (movie == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            CastSection("Genres", movie!.genreStr ?? ''),
            CastSection("Director", movie!.director),
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
          ],
        ),
      ),
    );
  }

  Widget buildEpisodes() {
    return episodesBuilder((ep, dEp, whEp) {
      return EpisodeWidget(
        episode: ep,
        dEpisode: dEp,
        wh: whEp,
        playEpisode: () => playEpisode(ep.epNum),
        ott: movie!.ott.value,
        downloadEpisode: () => downloadEpisode(ep.epNum, seasonNumber),
      );
    });
  }

  Widget buildRelated() {
    if (movie == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(22),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: movie!.suggest.length,
        itemBuilder: (context, index) {
          final id = movie!.suggest[index].id;
          return GestureDetector(
            onTap: () {
              goToMovie(context, ott.id, id);
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
        },
      ),
    );
  }

  List<Widget> buildsTabSections() {
    if (movie!.isShow) {
      return [
        if (tabIndex == 0) buildEpisodes(),
        if (tabIndex == 1 && movie!.suggest.isNotEmpty) buildRelated(),
        // if ((movie!.suggest.isNotEmpty && tabIndex == 2) ||
        //     (movie!.suggest.isEmpty && tabIndex == 1))
        // SliverPadding(
        //   padding: const EdgeInsets.symmetric(horizontal: 22),
        //   sliver: SliverList.list(children: buildCast()),
        // ),
      ];
    } else {
      return [
        // if (tabIndex == 0 && movie!.suggest.isNotEmpty) buildRelated(),
        // if ((movie!.suggest.isNotEmpty && tabIndex == 1) ||
        //     (movie!.suggest.isEmpty && tabIndex == 0))
        //   SliverPadding(
        //     padding: const EdgeInsets.symmetric(horizontal: 22),
        //     sliver: SliverList.list(children: buildCast()),
        //   ),
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
