import 'dart:developer';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/dialogs/category_dialog.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/netmirror/netmirror_model.dart';
import 'package:netmirror/screens/netflix/nf_home_screen/nf_navbar.dart';
import 'package:netmirror/screens/movie_abstract.dart';
import 'package:netmirror/widgets/pv_episode_widget.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_skeletons.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NfMovieScreen extends MovieScreen {
  const NfMovieScreen(super.id, {super.key});

  @override
  ConsumerState<MovieScreen> createState() => NfMovieScreenState();
}

class NfMovieScreenState extends MovieScreenState {
  @override
  OTT ott = OTT.none;
  @override
  bool extraTabForCast = false;

  void openSeasonMenu() {
    if (movie!.isMovie) return;
    if (movie!.seasons.isEmpty) return;
    final items = movie!.seasons.map((e) => e.s).toList();

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return CategoryPopupScreen(
          getText: (x) => "Season $x",
          selected: seasonIndex,
          handleClick: (i) {
            handleSeasonChange(i);
          },
          items: items,
        );
      },
    );
  }

  @override
  Widget build(context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const NfNavBar(current: 0),
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        toolbarHeight: 48,
        title: windowDragAreaWithChild(
          [],
          actions: [
            IconButton(
              onPressed: () {
                GoRouter.of(context).push("/downloads");
              },
              icon: isDesk
                  ? Icon(Icons.download, size: 20)
                  : Icon(
                      HugeIcons.strokeRoundedDownload05,
                      size: 30,
                      color: Colors.white,
                    ),
            ),
            IconButton(
              onPressed: () {
                GoRouter.of(context).push("/search");
              },
              icon: isDesk
                  ? Icon(Icons.search, size: 20)
                  : Icon(Icons.search, size: 30, color: Colors.white),
            ),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: "https://imgcdn.media/poster/h/${widget.id}.jpg",
                  cacheManager: NfLargeCacheManager.instance,
                  fit: BoxFit.cover,
                  height: size.width / (16 / 9),
                  width: double.infinity,
                ),
                if (movie != null)
                  ...buildMainData(size)
                else
                  SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
        body: movie != null
            ? TabBarView(
                controller: tabController,
                children: [
                  if (movie!.isShow) buildEpisodes(),
                  _buildSuggestionsTab(),
                ],
              )
            : SizedBox(),
      ),
    );
  }

  Widget buildEpisodes() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  openSeasonMenu();
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 8, top: 8, bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 43, 43, 43),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Season ${movie!.seasons[seasonIndex].s}   (${movie!.seasons[seasonIndex].ep} Ep)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildEpisodes(),
      ],
    );
  }

  Widget _buildEpisodes() {
    if (seasonIndex == -1) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("Error:: Season Index is -1")),
      );
    }
    if (movie!.seasons[seasonIndex].episodes == null) {
      log("episodes is null");

      return const SkeletonEpisodesList();
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
          return EpisodeWidget(
            episode: episode,
            dEpisode: depisode,
            ott: movie!.ott.value,
            playEpisode: () => playEpisode(index),
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

  Widget _buildSuggestionsTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesk ? 2 : 3,
              childAspectRatio: OTT.none.aspectRatio,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final id = movie!.suggest[index].id;
              return GestureDetector(
                onTap: () {
                  GoRouter.of(context).push("/nf-movie", extra: id);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: movie!.ott.getImg(id),
                    cacheManager: NfSmallCacheManager.instance,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }, childCount: movie!.suggest.length),
          ),
        ),
      ],
    );
  }

  List<Widget> buildMainData(Size size) {
    return [
      buildDetails(),
      buildActionItems(),
      if (tabController != null && tabController!.length > 0)
        SizedBox(
          width: (size.width / 3) * tabController!.length,
          child: TabBar(
            controller: tabController,
            dividerColor: Colors.red,
            dividerHeight: 0,
            indicatorColor: Colors.red,
            indicatorWeight: 4,
            indicatorPadding: const EdgeInsets.only(bottom: 44),
            indicatorSize: TabBarIndicatorSize.tab,
            unselectedLabelColor: Colors.white70,
            labelColor: Colors.white,
            tabs:
                (tabController!.length == 2
                        ? ["Episodes", "More Like This"]
                        : ["More Like This"])
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(e),
                      ),
                    )
                    .toList(),
          ),
        ),
    ];
  }

  Widget buildDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Play Button
          FilledButton(
            onPressed: playMovie,
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(3),
                  ), // Removes the border radius
                ),
              ),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, size: 28, color: Colors.black),
                SizedBox(width: 5),
                Text(
                  "Play",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Download Button
          FilledButton(
            onPressed: () async {
              downloadMovie();
            },
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Color.fromARGB(255, 38, 38, 38),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  "Download",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Movie Title
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              movie!.title,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Movie Year, Reason, Seasons, Runtime, ID
          Row(
            children: [
              Text(movie!.year),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 72, 72, 72),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(movie!.ua, style: const TextStyle(fontSize: 12)),
              ),
              if (movie!.isShow && movie!.seasons.length > 1) ...[
                const SizedBox(width: 12),
                Text("${movie!.seasons.length} Seasons"),
              ],
              if (movie!.isMovie) ...[
                const SizedBox(width: 12),
                Text(movie!.runtime ?? "NaN m"),
              ],
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 6),
          // Movie Description
          Text(movie!.desc),
          const SizedBox(height: 8),
          // Movie Cast
          if (movie!.shortCast != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Starring: ",
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Expanded(
                  child: Text(
                    movie!.shortCast ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // showDialog(
                    //     context: context,
                    //     builder: (context) {
                    //       return const CastPopupScreen();
                    //     });
                  },
                  child: const Text(" more", style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          // Movie Directors
          if (movie!.director.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Directors: ",
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Expanded(
                  child: Text(
                    movie!.director,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget buildActionItems() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MovieScreenActionItem(
            LottieBuilder.asset(
              "assets/lottie/my-list-plus-to-check.json",
              reverse: true,
              animate: inWatchlist,
              repeat: repeat,
              // controller: _animationController,
            ),
            "Movie List",
            handleAddWatchlist,
          ),
          _MovieScreenActionItem(
            const Icon(HugeIcons.strokeRoundedThumbsUp, color: Colors.white),
            "Rate",
            () {},
          ),
          _MovieScreenActionItem(
            const Icon(Icons.share, color: Colors.white),
            "Share",
            () {
              Share.shareUri(Uri.parse("$API_URL/watch/${movie!.id}"));
            },
          ),
          _MovieScreenActionItem(
            const Icon(
              HugeIcons.strokeRoundedDownload04,
              size: 32,
              color: Colors.white,
            ),
            "Download",
            () {},
          ),
        ],
      ),
    );
  }
}

class _MovieScreenActionItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final void Function() onClick;

  const _MovieScreenActionItem(this.icon, this.label, this.onClick);

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
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
