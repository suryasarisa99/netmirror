import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/dialogs/category_dialog.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/screens/movie_ui_abstract.dart';
import 'package:netmirror/utils/nav.dart';
import 'package:netmirror/widgets/pv_episode_widget.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';
import 'package:shared_code/shared_code.dart' hide isDesk;

class NfMovieScreen extends MovieScreenUi {
  const NfMovieScreen(super.id, {super.key});

  @override
  NfMovieScreenState createState() => NfMovieScreenState();
}

const l = L("nf_movie_screen");

class NfMovieScreenState extends MovieScreenUiState {
  @override
  OTT ott = OTT.netflix;
  @override
  bool extraTabForCast = false;

  void openSeasonMenu() {
    if (movie!.isMovie) return;
    if (movie!.seasons.isEmpty) return;
    final seasonNumbers = movie!.seasonNumbers; // Get sorted season numbers

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return CategoryPopupScreen(
          getText: (seasonNum) => "Season $seasonNum",
          selected: seasonNumber,
          handleClick: (seasonNum) {
            handleSeasonChange(seasonNumbers[seasonNum]);
          },
          items: seasonNumbers,
        );
      },
    );
  }

  @override
  Widget build(context) {
    final size = MediaQuery.sizeOf(context);
    return screenBuilder(
      tabs: [if (movie?.isShow ?? false) buildEpisodes(), buildRelated()],
      appBar: buildAppBar(),
      bg: Colors.black,
      poster: CachedNetworkImage(
        imageUrl: "https://imgcdn.media/poster/h/${widget.id}.jpg",
        cacheManager: NfLargeCacheManager.instance,
        fit: BoxFit.cover,
        height: size.width / (16 / 9),
        width: double.infinity,
      ),
      headers: [toSlivers(buildMovieDetails(size), center: false)],
    );
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
      automaticallyImplyLeading: !isDesk,
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
              GoRouter.of(context).push("/search/${ott.id}");
            },
            icon: isDesk
                ? Icon(Icons.search, size: 20)
                : Icon(Icons.search, size: 30, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget buildEpisodes() {
    if (movie == null) return const SizedBox();
    return episodesBuilder((ep, dEp, whEp) {
      return EpisodeWidget(
        episode: ep,
        ott: ott.value,
        dEpisode: dEp,
        playEpisode: () => playEpisode(ep.epNum),
        downloadEpisode: () => downloadEpisode(ep.epNum, seasonNumber),
        wh: whEp,
      );
    });
  }

  Widget buildRelated() {
    if (movie == null) return SizedBox();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesk ? 2 : 3,
          childAspectRatio: OTT.netflix.aspectRatio,
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
                cacheManager: NfSmallCacheManager.instance,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> buildMovieDetails(Size size) {
    if (movie == null) return [];
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
          buildMainPlayBtn((text) {
            return FilledButton(
              onPressed: playMovieOrEpisode,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 28, color: Colors.black),
                  SizedBox(width: 5),
                  Text(
                    text,
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ],
              ),
            );
          }),
          ?buildProgressBar(Colors.red),
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
              // "assets/lottie/hotstar/watchlist_animation_blue.json",
              "assets/lottie/my-list-plus-to-check.json",
              controller: watchlistAnimationController,
              height: 40,
              onLoaded: (composition) {
                // Set initial state based on inWatchlist
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
          _MovieScreenActionItem(
            const Icon(HugeIcons.strokeRoundedThumbsUp, color: Colors.white),
            "Rate",
            () {},
          ),
          _MovieScreenActionItem(
            const Icon(Icons.share, color: Colors.white),
            "Share",
            shareDeepLinkUrl,
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
