import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/global_shorcuts.dart';
import 'package:netmirror/models/movie_model.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:netmirror/screens/hotstar/hotstar_home/hotstar_home_screen.dart';
import 'package:netmirror/screens/hotstar/hotstar_movie/hotstar_movie_screen.dart';
import 'package:netmirror/screens/hotstar/hotstar_studio/hotstar_studio_screen.dart';
import 'package:netmirror/screens/initial_screen.dart';
import 'package:netmirror/screens/netflix/nf_home_screen/nf_home_screen.dart';
import 'package:netmirror/screens/netflix/nf_movie_screen/nf_movie_screen.dart';
import 'package:netmirror/screens/other/downloads_screen/download_screen.dart';
import 'package:netmirror/screens/other/profile_screen/profile_screen.dart';
import 'package:netmirror/screens/other/search_screen/search_screen.dart';
import 'package:netmirror/screens/other/settings_screen/audio_track_screen.dart';
import 'package:netmirror/screens/other/settings_screen/settings_screen.dart';
import 'package:netmirror/screens/player/mediakit_player.dart';
import 'package:netmirror/screens/prime_video/home_screen/pv_home_screen.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_movie_screen.dart';

final GlobalKey<StatefulNavigationShellState> pvMainHomeKey =
    GlobalKey<StatefulNavigationShellState>();
final GlobalKey<StatefulNavigationShellState> nfMainHomeKey =
    GlobalKey<StatefulNavigationShellState>();
final GlobalKey<StatefulNavigationShellState> hotstarMainHomeKey =
    GlobalKey<StatefulNavigationShellState>();

typedef PlayerScreenData = ({
  Movie movie,
  WatchHistory? watchHistory,
  String url,
  int? seasonNumber,
  int? episodeNumber,
  String? subtitleUrl,
});

final routes = GoRouter(
  navigatorKey: GlobalKey(),
  initialLocation: "/initial-screen",
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        // This builder's context is a descendant of MaterialApp
        return GlobalShortcuts(child: child);
      },
      routes: [
        GoRoute(
          path: "/initial-screen",
          pageBuilder: (context, state) {
            return const MaterialPage(child: InitialScreen());
          },
        ),
        GoRoute(
          path: '/search/:ottId',
          pageBuilder: (context, state) {
            final ottId = int.parse(state.pathParameters['ottId']!);
            return MaterialPage(child: Search(ottId));
          },
        ),
        GoRoute(
          path: "/downloads",
          pageBuilder: (context, state) {
            return MaterialPage(
              child: DownloadsScreen(seriesId: state.extra as String?),
            );
          },
        ),
        GoRoute(
          path: "/settings",
          pageBuilder: (context, state) {
            return const MaterialPage(child: SettingsScreen());
          },
        ),
        GoRoute(
          path: "/settings-audio-tracks",
          pageBuilder: (context, state) {
            return const MaterialPage(child: AudioTrackSelectionScreen());
          },
        ),
        GoRoute(
          path: "/profile",
          pageBuilder: (context, state) {
            return const MaterialPage(child: ProfileScreen());
          },
        ),
        GoRoute(
          path: "/player",
          pageBuilder: (context, state) {
            final data = state.extra as PlayerScreenData;
            return MaterialPage(
              child: MediaKitPlayer(
                url: data.url,
                data: data.movie,
                wh: data.watchHistory,
                seasonNumber: data.seasonNumber,
                episodeNumber: data.episodeNumber,
                subtitleUrl: data.subtitleUrl,
              ),
            );
          },
        ),

        GoRoute(
          path: "/movie/:ottId/:movieId",
          pageBuilder: (context, state) {
            final ottId = int.parse(state.pathParameters['ottId']!);
            final movieId = state.pathParameters['movieId']!;
            // return slideFromRightTransition(switch (ottId) {
            //   0 => NfMovieScreen(movieId),
            //   1 => PVMovieScreen(movieId),
            //   2 => HotstarMovieScreen(movieId),
            //   _ => NfMovieScreen(movieId), // Default to Netflix if ottId is unknown
            // }, state);
            return switch (ottId) {
              0 => slideFromRightTransition(NfMovieScreen(movieId), state),
              1 => slideFromRightTransition(PVMovieScreen(movieId), state),
              2 => slideFromBottomTransition(
                HotstarMovieScreen(movieId),
                state,
              ),
              _ => slideFromRightTransition(NfMovieScreen(movieId), state),
            };
          },
        ),

        // <================== Home Screens ==================>
        // Netflix Home
        StatefulShellRoute.indexedStack(
          key: nfMainHomeKey,
          builder: (context, state, shell) => NfMain(shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/nf-home',
                  pageBuilder: (context, state) {
                    final tab = state.extra == null ? 0 : state.extra as int;
                    // return NoTransitionPage(child: NfHomeScreen(tab));
                    return instantTransition(NfHomeScreen(tab: tab), state);
                  },
                ),
              ],
            ),
          ],
        ),

        /// PrimeVideo Home
        StatefulShellRoute.indexedStack(
          key: pvMainHomeKey,
          builder: (context, state, shell) => PvMain(shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/pv-home',
                  pageBuilder: (context, state) {
                    final tab = state.extra == null ? 0 : state.extra as int;
                    return instantTransition(PvHomeScreen(tab: tab), state);
                  },
                ),
              ],
            ),
          ],
        ),

        StatefulShellRoute.indexedStack(
          key: hotstarMainHomeKey,
          builder: (context, state, shell) => HotstarMain(shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/hotstar-home',
                  pageBuilder: (context, state) {
                    final tab = state.extra == null ? 0 : state.extra as int;
                    final studio = state.uri.queryParameters['studio'];
                    return instantTransition(
                      studio != null
                          ? HotstarStudioScreen(studioName: studio, tab: tab)
                          : HotstarHomeScreen(tab: tab),
                      state,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

CustomTransitionPage<T> slideFromRightTransition<T extends Object?>(
  Widget child,
  GoRouterState state, {
  Duration duration = const Duration(milliseconds: 300),
  Curve curve = Curves.easeInOut,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Start from right
      const end = Offset.zero; // End at center

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: duration,
  );
}

CustomTransitionPage<T> slideFromBottomTransition<T extends Object?>(
  Widget child,
  GoRouterState state, {
  Duration duration = const Duration(milliseconds: 600),
  Curve curve = Curves.easeInOut,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // Start from bottom
      const end = Offset.zero; // End at center

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: duration,
  );
}

// by default,there is NoTransitionPage, for instant transition(without animation between screens), but disables hero widget animation between screens
// so this animatin takes transitionDuration,but no visual transition
CustomTransitionPage<T> instantTransition<T extends Object?>(
  Widget child,
  GoRouterState state, {
  Duration duration = const Duration(
    milliseconds: 500,
  ), // Duration for Hero animations
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Return child directly without any visual transition
      return child;
    },
    transitionDuration: duration, // Keep duration for Hero animations
  );
}
