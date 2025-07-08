import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/db/db.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/routes.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();
  L.only = ["downloader"];
  L.logLevel = LogLevel.debug;
  // L.stackStrace = true;

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
