import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
// import 'package:netmirror/better_player/better_player.dart';
import 'package:netmirror/db/db_helper.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:netmirror/models/netmirror/nm_movie_model.dart';
import 'package:netmirror/models/watch_model.dart';
// import 'package:netmirror/old/netflix/home_screen/home_screen.dart';
import 'package:netmirror/screens/initial_screen.dart';
import 'package:netmirror/screens/netflix/nf_home_screen/nf_home_screen.dart';
import 'package:netmirror/screens/netflix/nf_movie_screen/nf_movie_screen.dart';
import 'package:netmirror/screens/other/downloads_screen/download_screen.dart';
import 'package:netmirror/screens/other/settings_screen/settings_screen.dart';
// import 'package:netmirror/screens/player/chewie_player.dart';
import 'package:netmirror/screens/player/mediakit_player.dart';
// import 'package:netmirror/old/netflix/movie_screen/movie_screen.dart';
// import 'package:netmirror/screens/player/netmirror_player.dart';
// import 'package:netmirror/screens/player/online_player.dart';
// import 'package:netmirror/screens/player/source_picker.dart';
import 'package:netmirror/screens/prime_video/home_screen/pv_home_screen.dart';
import 'package:netmirror/screens/prime_video/movie_screen/pv_movie_screen.dart';
import 'package:netmirror/screens/other/search_screen/search_screen.dart';
import 'package:netmirror/screens/other/settings_screen/audio_track_screen.dart';
import 'package:shared_code/models/movie_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();

  // if (isDesk) {
  //   databaseFactory = databaseFactoryFfi;
  //   // await windowManager.ensureInitialized();

  //   const WindowOptions windowOptions = WindowOptions(
  //     size: Size(800, 600),
  //     center: true,
  //     backgroundColor: Colors.transparent,
  //     skipTaskbar: false,
  //     titleBarStyle: TitleBarStyle.hidden,
  //   );
  //   windowManager.waitUntilReadyToShow(windowOptions, () async {
  //     await windowManager.show();
  //     await windowManager.focus();
  //   });
  // }

  await DBHelper.instance.database;
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
  WatchHistoryModel? watchHistory,
  int? seasonIndex,
  int? episodeIndex,
});

final routes = GoRouter(
  initialLocation: "/initial-screen",
  routes: [
    // GoRoute(
    //     path: '/search',
    //     pageBuilder: (context, state) {
    //       return MaterialPage(child: CupertinoContextMenuDemo());
    // }),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) {
        return MaterialPage(
          child: Search(state.extra == null ? 0 : state.extra as int),
        );
      },
    ),
    GoRoute(
      path: "/pv-movie",
      pageBuilder: (context, state) {
        return MaterialPage(child: PVMovieScreen(state.extra as String));
      },
    ),
    StatefulShellRoute.indexedStack(
      key: nfMainHomeKey,
      builder: (context, state, shell) => NfMainHomeScreen(shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nf-home',
              pageBuilder: (context, state) {
                final tab = state.extra == null ? 0 : state.extra as int;
                return MaterialPage(child: NfHomeScreen(tab));
              },
            ),
          ],
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      key: pvMainHomeKey,
      builder: (context, state, shell) => PvMainHomeScreen(shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pv-home',
              pageBuilder: (context, state) {
                final tab = state.extra == null ? 0 : state.extra as int;
                log(("navigating to pv-home with tab $tab"));
                return MaterialPage(child: PvHomeScreen(tab: tab));
              },
            ),
          ],
        ),
      ],
    ),
    // GoRoute(
    //     path: "/pv-home",
    //     pageBuilder: (context, state) {
    //       final tab = state.extra == null ? 0 : state.extra as int;
    //       return MaterialPage(child: PvHomeScreen(tab: tab));
    //     }),
    // GoRoute(
    //     path: "/nf-home",
    //     pageBuilder: (context, state) {
    //       // final tab = state.extra == null ? 0 : state.extra as int;
    //       return MaterialPage(child: NfHomeScreen());
    //     }),
    GoRoute(
      path: "/nm-player",
      pageBuilder: (context, state) {
        // final data = state.extra as PlayerScreenData;
        return MaterialPage(
          child: MediaKitPlayer(
            url: state.extra as String,
            // data: data.movie,
            // wh: data.watchHistory,
            // seasonIndex: data.seasonIndex,
            // episodeIndex: data.episodeIndex,
          ),
        );
      },
    ),

    GoRoute(
      path: "/initial-screen",
      pageBuilder: (context, state) {
        return const MaterialPage(child: InitialScreen());
      },
    ),
    // GoRoute(
    //   path: "/source-picker",
    //   pageBuilder: (context, state) {
    //     return MaterialPage(
    //       child: SourcePicker(state.extra as BetterPlayerController),
    //     );
    //     // return const MaterialPage(child: BetterPlayerPage(title: "Sample"));
    //   },
    // ),
    GoRoute(
      path: "/downloads",
      pageBuilder: (context, state) {
        return MaterialPage(
          child: DownloadsScreen(seriesId: state.extra as String?),
        );
      },
    ),
    // GoRoute(
    //     path: "/downloads-episodes",
    //     pageBuilder: (context, state) {
    //       return const MaterialPage(child: DownloadsScreen());
    //     }),
    // GoRoute(
    //     path: "/profile",
    //     pageBuilder: (context, state) {
    //       return const MaterialPage(child: ProfileScreen());
    //     }),
    // GoRoute(
    //     path: "/offline-player",
    //     pageBuilder: (context, state) {
    //       return MaterialPage(child: OfflinePlayer(id: state.extra as int));
    //       // return MaterialPage(child: BetterPlayerPage(id: state.extra as int));
    //     }),
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
    // GoRoute(
    //   path: "/player",
    //   pageBuilder: (context, state) {
    //     final (playerData, watchHistory) =
    //         state.extra as (PlayerData, WatchHistoryModel?);
    //     return MaterialPage(
    //       child: BetterPlayerScreen(data: playerData, wh: watchHistory),
    //     );
    //   },
    // ),
    // GoRoute(
    //   path: "/",
    //   pageBuilder: (context, state) {
    //     int id = 0;
    //     String? genre;
    //     String? genreName;

    //     try {
    //       var (a, b, c) = state.extra as (int, String?, String?);
    //       id = a;
    //       genre = b;
    //       genreName = c;
    //     } catch (_) {}

    //     final isHome = id == 0;
    //     final isTvShows = id == 1;
    //     final isMovies = id == 2;
    //     final isCategory = id == 3;

    //     return MaterialPage(
    //         child: HomeScreen(
    //       isCategory: isCategory,
    //       isMovies: isMovies,
    //       isTvshows: isTvShows,
    //       categoryId: genre,
    //       isHome: isHome,
    //       categoryName: genreName,
    //       index: id,
    //     ));
    //   },
    // ),
    GoRoute(
      path: "/nf-movie",
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: NfMovieScreen(state.extra as String),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset(0.0, 0.0);
            const curve = Curves.ease;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
      },
    ),
  ],
);
