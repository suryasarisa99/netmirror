import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/db/db.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:netmirror/models/movie_model.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:netmirror/screens/initial_screen.dart';
import 'package:netmirror/screens/netflix/nf_home_screen/nf_home_screen.dart';
import 'package:netmirror/screens/netflix/nf_movie_screen/nf_movie_screen.dart';
import 'package:netmirror/screens/other/downloads_screen/download_screen.dart';
import 'package:netmirror/screens/other/profile_screen/profile_screen.dart';
import 'package:netmirror/screens/other/settings_screen/settings_screen.dart';
import 'package:netmirror/screens/player/mediakit_player.dart';
import 'package:netmirror/screens/prime_video/home_screen/pv_home_screen.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_movie_screen.dart';
import 'package:netmirror/screens/other/search_screen/search_screen.dart';
import 'package:netmirror/screens/other/settings_screen/audio_track_screen.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();

  if (isDesk) {
    await windowManager.ensureInitialized();
    const WindowOptions windowOptions = WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // if (isDesk) {
  //   databaseFactory = databaseFactoryFfi;
  // }

  await DB.instance.database;
  Downloader.instance;

  // if (!isDesk) {
  //   await Workmanager().initialize(
  //     callbackDispatcher,
  //     isInDebugMode: true,
  //   );
  // }

  runApp(ProviderScope(overrides: [], child: MainApp()));
}

const themeColor = Color.fromARGB(255, 171, 109, 105);
final darkScheme = ColorScheme.fromSeed(
  seedColor: themeColor,
  brightness: Brightness.dark,
);

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   log("============== App State: $state ==============");
  //   if (state == AppLifecycleState.detached ||
  //       state == AppLifecycleState.paused) {
  // pauseFlags.updateAll((key, value) => true);

  // runs when app closed
  // DownloadHelper.instance.continueDownloadAfterAppOpen();
  // log("Ids: $ids");
  // log("App closed");
  // Workmanager().registerOneOffTask(
  //   "downloadTask",
  //   "downloadTask",
  //   // inputData: {"downloadId": ids[0]},
  //   existingWorkPolicy: ExistingWorkPolicy.replace,
  // );
  // }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      key: GlobalKey(),
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(colorScheme: darkScheme),
      theme: ThemeData.dark(useMaterial3: true),
      // home: HomeScreen(),
      routerConfig: routes,
    );
  }
}

// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     if (task == "downloadTask") {
//       logger.f("Download task started");
//       final ids = await DownloadDb.instance.downloadingIds();
//       // final downloadId = inputData!["downloadId"]! as int;
//       await DownloadDb.instance.processDownload(ids[0]);
//       // await DownloadHelper.instance.continueDownloadAfterAppOpen();
//       return true;
//     }
//     return true;
//   });
// }

final GlobalKey<StatefulNavigationShellState> pvMainHomeKey =
    GlobalKey<StatefulNavigationShellState>();
final GlobalKey<StatefulNavigationShellState> nfMainHomeKey =
    GlobalKey<StatefulNavigationShellState>();

typedef PlayerScreenData = ({
  Movie movie,
  WatchHistory? watchHistory,
  String url,
  int? seasonIndex,
  int? episodeIndex,
});

final routes = GoRouter(
  navigatorKey: GlobalKey(),
  initialLocation: "/initial-screen",
  routes: [
    GoRoute(
      path: "/initial-screen",
      pageBuilder: (context, state) {
        return const MaterialPage(child: InitialScreen());
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) {
        return MaterialPage(
          child: Search(state.extra == null ? 0 : state.extra as int),
        );
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
            seasonIndex: data.seasonIndex,
            episodeIndex: data.episodeIndex,
          ),
        );
      },
    ),

    /// Netflix Routes
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
                return instantTransition(NfHomeScreen(tab), state);
              },
            ),
            GoRoute(
              path: "/nf-movie",
              pageBuilder: (context, state) {
                return slideFromRightTransition(
                  NfMovieScreen(state.extra as String),
                  state,
                );
              },
            ),
          ],
        ),
      ],
    ),

    /// Prime Video Routes
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
                log(("navigating to pv-home with tab $tab"));
                return instantTransition(PvHomeScreen(tab: tab), state);
              },
            ),
            GoRoute(
              path: "/pv-movie",
              pageBuilder: (context, state) {
                return slideFromRightTransition(
                  PVMovieScreen(state.extra as String),
                  state,
                );
              },
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
