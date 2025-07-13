import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/screens/hotstar/hotstar_button.dart';
import 'package:netmirror/screens/hotstar/hotstar_movie_appbar.dart';
import 'package:netmirror/screens/movie_abstract.dart';
import 'package:netmirror/screens/movie_ui_abstract.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_cast_section.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_skeletons.dart';
import 'package:netmirror/utils/nav.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';
import 'package:netmirror/widgets/pv_episode_widget.dart';
import 'package:netmirror/widgets/sticky_header_delegate.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HotstarMovieScreen extends MovieScreenUi {
  const HotstarMovieScreen(super.id, {super.key});

  @override
  MovieScreenUiState createState() => _HoststarMovieScreenState();
}

const l = L("hotstar_movie_screen");

class _HoststarMovieScreenState extends MovieScreenUiState {
  @override
  OTT ott = OTT.hotstar;
  @override
  bool extraTabForCast = true;

  ScrollController? scrollController;

  // static vars
  static final bg = Color(0xFF0F1014);

  void handleTabChange(int index) {
    // if (movie!.isShow && tabIndex == 0 && index == 0) {
    // showModalBottomSheet(
    //   context: context,
    //   builder: (x) {
    //     return SeasonSelectorBottomSheet(
    //       seasons: movie!.seasons,
    //       selectedSeason: seasonNumber,
    //       onTap: (seasonNum) {
    //         handleSeasonChange(seasonNum);
    //       },
    //     );
    //   },
    // );
    // } else {
    //   setState(() {
    //     tabIndex = index;
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return screenBuilder(
      tabs: [
        if (movie?.isShow ?? false) buildEpisodes(),
        buildRelated(),
        buildCast(),
      ],
      appBar: HotstarMovieAppbar(
        scrollController: scrollController,
        maxScroll: 80,
        color: bg,
        title: movie?.title ?? '',
      ),
      bg: bg,
      extendBodyBehindAppBar: true,
      poster: _buildMoviePoster(),
      headers: [toSlivers(buildMovieDetails(size)), _buildTabBar()],
      getController: (controller) {
        if (scrollController == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                scrollController = controller;
              });
            }
          });
        }
      },
    );
  }

  List<Widget> buildMovieDetails(Size size) {
    if (movie == null) return [];
    return [
      HotstarButton(text: "Watch Now", onPressed: playMovieOrEpisode),
      SizedBox(height: 16),
      _buildActions(),
      SizedBox(height: 16),

      // Genre Tags
      SizedBox(
        width: size.width,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: movie!.genre.mapIndexed((index, genre) {
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      genre,
                      style: TextStyle(
                        color: Color(0xFFe0e4ed),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Add gray line separator, but not after the last item
                  if (index < movie!.genre.length - 1)
                    Container(
                      width: 1,
                      height: 12,
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),

      SizedBox(height: 16),

      // Movie Description
      Text(
        movie!.desc,
        textAlign: TextAlign.justify,
        style: TextStyle(color: Color(0xFFe0e4ed), fontSize: 14),
      ),

      //
    ];
  }

  Widget _buildTabBar() {
    if (movie == null) return SizedBox();
    return SliverPersistentHeader(
      delegate: StickyHeaderDelegate(
        minHeight: 60.0,
        maxHeight: 60.0,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF0F1014)),
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
              if (movie!.suggest.isNotEmpty) const Tab(text: 'Related'),
              const Tab(text: 'Details'),
            ],
          ),
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildMoviePoster() {
    final size = MediaQuery.sizeOf(context);
    final paddingTop = MediaQuery.paddingOf(context).top;
    return SizedBox(
      width: size.width,
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10, top: paddingTop),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Movie Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: "https://imgcdn.media/hs/h/700/${widget.id}.jpg",
                cacheManager: NfLargeCacheManager.instance,
                fit: BoxFit.cover,
                width: size.width,
              ),
            ),

            const SizedBox(height: 16),

            // Movie Title Image
            // w=1.788 of height
            CachedNetworkImage(
              imageUrl: "https://imgcdn.media/hs/n/${widget.id}.png",
              cacheManager: NfLargeCacheManager.instance,
              height: 80,
              width: 80 * 1.788,
            ),

            const SizedBox(height: 16),

            // Movie Description
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        spacing: 36,
        children: [
          _actionBtn(
            LottieBuilder.asset(
              "assets/lottie/hotstar/watchlist_animation_blue.json",
              // "assets/lottie/my-list-plus-to-check.json",
              controller: watchlistAnimationController,
              height: 24,
              onLoaded: (composition) {
                // Set initial state based on inWatchlist
                if (inWatchlist) {
                  watchlistAnimationController.value = 1.0;
                } else {
                  watchlistAnimationController.value = 0.0;
                }
              },
            ),
            "Watchlist",
            handleAddWatchlist,
          ),
          _actionBtn(
            _icon(HugeIcons.strokeRoundedDownload05),
            "Download",
            downloadMovie,
          ),
          _actionBtn(
            _icon(HugeIcons.strokeRoundedShare08),
            "Share",
            shareDeepLinkUrl,
          ),
          _actionBtn(
            _icon(HugeIcons.strokeRoundedFavourite, size: 19),
            "Share",
            shareDeepLinkUrl,
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(Widget icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          Text(label, style: TextStyle(color: Color(0xFFe0e4ed), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, {double size = 22}) {
    return Icon(icon, size: size, color: Color(0xFFe0e4ed));
  }

  Widget buildEpisodes() {
    return episodesBuilder((ep, dEp, wEp) {
      return EpisodeWidget(
        episode: ep,
        ott: ott.value,
        dEpisode: dEp,
        playEpisode: () => playEpisode(ep.epNum),
        downloadEpisode: () => downloadEpisode(ep.epNum, seasonNumber),
        wh: wEp,
      );
    });
  }

  Widget buildRelated() {
    if (movie == null) return SizedBox();
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

  Widget buildCast() {
    if (movie == null) return SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
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
}
