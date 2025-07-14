import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/screens/hotstar/hotstar_button.dart';
import 'package:netmirror/screens/hotstar/opacity_builder.dart';
import 'package:netmirror/screens/movie_ui_abstract.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_cast_section.dart';
import 'package:netmirror/utils/nav.dart';
import 'package:netmirror/widgets/pv_episode_widget.dart';
import 'package:netmirror/widgets/sticky_header_delegate.dart';
import 'package:shared_code/models/ott.dart';

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
      appBar: buildAppBar(movie?.title ?? ""),
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
    ];
  }

  Widget _buildTabBar() {
    // the extra padding, is for, we are using extendBodyBehindAppBar: true,
    // so it causes it sticks at the top, behind the appbar to fix it added padding at top and increased the height of the sliver header.
    if (movie == null) return SizedBox();
    const toolBarHeight = kToolbarHeight - 5;
    return SliverPersistentHeader(
      delegate: StickyHeaderDelegate(
        minHeight: 60 + toolBarHeight,
        maxHeight: 60 + toolBarHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF0F1014)),
          child: Padding(
            padding: const EdgeInsets.only(top: toolBarHeight),
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
      padding: const EdgeInsets.symmetric(horizontal: 22),
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

  PreferredSizeWidget buildAppBar(final String title) {
    return ScrollPercentBuilder(
      maxScroll: 80,
      minScroll: 30,
      scrollController: scrollController,
      builder: (opacity) {
        return AppBar(
          backgroundColor: bg.withValues(alpha: opacity),
          // backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          titleSpacing: 18,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: opacity),
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                iconSize: 22,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
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
