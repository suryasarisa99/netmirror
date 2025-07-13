import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:netmirror/downloader/download_models.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:netmirror/screens/movie_abstract.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_skeletons.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';
import 'package:shared_code/models/movie_model.dart';
import 'package:skeletonizer/skeletonizer.dart';

abstract class MovieScreenUi extends MovieScreen {
  const MovieScreenUi(super.id, {super.key});
}

abstract class MovieScreenUiState extends MovieScreenState {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  // Track scroll state
  bool _isRefreshing = false;
  double _previousPixels = 0.0;
  bool _wasAtTop = true;
  bool _hasTriggeredRefresh = false;
  double _accumulatedOverscroll = 0.0;
  static const double _refreshThreshold = 80.0;

  bool _handleScrollNotification(ScrollNotification notification) {
    // Handle ScrollStartNotification
    if (notification is ScrollStartNotification) {
      final currentPixels = notification.metrics.pixels;
      _wasAtTop = (currentPixels <= 0);
      _hasTriggeredRefresh = false;
      _accumulatedOverscroll = 0.0; // Reset accumulated overscroll
    }

    // Handle ScrollUpdateNotification to track position
    if (notification is ScrollUpdateNotification) {
      final currentPixels = notification.metrics.pixels;

      // Update _wasAtTop BEFORE updating _previousPixels
      _wasAtTop = (_previousPixels <= 0);
      _previousPixels = currentPixels;

      // Reset refresh trigger and accumulated overscroll when we're not at top anymore
      if (currentPixels > 10) {
        _hasTriggeredRefresh = false;
        _accumulatedOverscroll = 0.0;
      }
    }

    // Handle OverscrollNotification
    if (notification is OverscrollNotification) {
      final currentPixels = notification.metrics.pixels;
      final overscroll = notification.overscroll;

      // Update _wasAtTop if we haven't tracked it yet
      if (_previousPixels == 0.0 && currentPixels <= 0) {
        _wasAtTop = true;
      }

      // Accumulate overscroll when pulling down from top
      if (_wasAtTop && overscroll < 0 && currentPixels <= 0) {
        _accumulatedOverscroll += overscroll.abs();
      }

      // Log for debugging
      log(
        "Overscroll: $overscroll, Accumulated: $_accumulatedOverscroll, Current: $currentPixels, Previous: $_previousPixels, WasAtTop: $_wasAtTop",
      );

      // Check if we've accumulated enough overscroll
      if (_wasAtTop &&
          overscroll < 0 &&
          currentPixels <= 0 &&
          _accumulatedOverscroll > _refreshThreshold &&
          !_isRefreshing &&
          !_hasTriggeredRefresh) {
        log(
          "Triggering refresh - accumulated overscroll: $_accumulatedOverscroll",
        );
        _hasTriggeredRefresh = true;
        _refreshIndicatorKey.currentState?.show();
        return true;
      }
    }

    // Handle ScrollEndNotification
    if (notification is ScrollEndNotification) {
      // Reset accumulated overscroll when scroll ends
      _accumulatedOverscroll = 0.0;
    }

    return false;
  }

  Future<void> _handleRefresh() async {
    _isRefreshing = true;
    try {
      await loadDataFromOnline();
    } finally {
      _isRefreshing = false;
      _hasTriggeredRefresh = false;
      _accumulatedOverscroll = 0.0;
    }
  }

  Widget screenBuilder({
    Widget? tabBar,
    required List<Widget> tabs,
    PreferredSizeWidget? appBar,
    Widget? sliverAppbar,
    required Color bg,
    required List<Widget> headers,
    required Widget poster,
    bool extendBodyBehindAppBar = false,
  }) {
    return DesktopWrapper(
      child: Scaffold(
        backgroundColor: bg,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar,
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          child: NotificationListener(
            onNotification: _handleScrollNotification,
            child: DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (context, f) {
                  return [
                    ?sliverAppbar,
                    SliverToBoxAdapter(child: poster),
                    if (movie != null)
                      ...headers
                    else
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 400,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ];
                },
                body: movie != null
                    ? TabBarView(controller: tabController, children: tabs)
                    : SizedBox(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMainPlayBtn(Widget Function(String text) builder) {
    late String text;
    if (watchHistory != null) {
      text = "Resume";
    } else if (seasonWatchHistory.isNotEmpty) {
      final watchHist = seasonWatchHistory.first;
      final episode = movie!.getEpisode(
        watchHist.seasonNumber!,
        watchHist.episodeNumber!,
      );
      text = "Resume ${episode.s}:${episode.ep}";
    } else {
      text = "Play";
    }
    return builder(text);
  }

  Widget toSlivers(List<Widget> widgets, {bool center = true}) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget? buildProgressBar(Color color) {
    WatchHistory? currWatchHistory;

    if (movie!.isMovie) {
      currWatchHistory = watchHistory;
    } else {
      currWatchHistory = seasonWatchHistory.firstOrNull;
    }
    if (currWatchHistory == null) {
      return null;
    }
    final double progress =
        currWatchHistory.current / currWatchHistory.duration;
    int inMinutes =
        ((currWatchHistory.duration - currWatchHistory.current) / 1000 / 60)
            .toInt();
    if (inMinutes <= 0) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$inMinutes min left",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget episodesBuilder(
    Widget Function(Episode ep, MiniDownloadItem? dEp, WatchHistory? wh)
    builder,
  ) {
    if (seasonNumber == -1) {
      return const Center(child: Text("Error:: Season Number is -1"));
    }

    final season = movie!.getSeason(seasonNumber);
    if (season.episodes == null) {
      return Skeletonizer(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
      final episodesMap = movie!.getSeasonEpisodes(seasonNumber);
      final episodes = episodesMap.values.toList();
      final currentEpisodesCount = episodes.length;
      final extraThere = season.ep > currentEpisodesCount;
      final episodeCount = extraThere
          ? currentEpisodesCount + 1
          : currentEpisodesCount;

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: episodeCount,
        itemBuilder: (context, index) {
          if (index == episodeCount - 4 && !episodesLoading && extraThere) {
            loadMoreEpisodes();
          }

          if (index == episodeCount - 1 && extraThere) {
            return const Skeletonizer(child: SkeletonEpisodeWidget());
          }

          final episode = episodes[index];
          final dEpisode = downloads[episode.id];
          final whEpisode = seasonWatchHistory
              .where((wh) => wh.episodeNumber == episode.epNum)
              .firstOrNull;
          return builder(episode, dEpisode, whEpisode);
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
}
