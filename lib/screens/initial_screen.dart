import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/api/get_initial.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/provider/AudioTrackProvider.dart';
import 'package:netmirror/data/options.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

const l = L("initial");

class _InitialScreenState extends ConsumerState<InitialScreen> {
  bool counterStarted = false;
  int counterSeconds = 35;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initial();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startCounter({Function? onFinish}) {
    setState(() {
      counterStarted = true;
      counterSeconds = 35;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (counterSeconds > 0) {
        setState(() {
          counterSeconds--;
        });
      } else {
        timer.cancel();
        onFinish?.call();
      }
    });
  }

  void _initial() async {
    sp = await SharedPreferences.getInstance();
    ref.read(audioTrackProvider.notifier).initial();
    SettingsOptions.initialize(sp!);
    CookiesManager.initialize();

    await CookiesManager.validate(
      onAddOpen: startCounter,
      handleAddOpenError: (String addHash) async {
        // show message to user

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error Open Add Automatically",
              textAlign: TextAlign.center,
            ),
            duration: const Duration(milliseconds: 2500),
            behavior: SnackBarBehavior.floating,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            // width: 200,
            margin: EdgeInsets.symmetric(vertical: 80, horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );

        final url = Uri.parse('$addUrl$addHash&a=y&t=0.2822303821745413');
        await launchUrl(url);
        startCounter(
          onFinish: () async {
            final newTHashT = await verifyAdd(addHash);
            if (newTHashT != null) {
              l.log("newTHashT: $newTHashT");
              CookiesManager.tHashT = newTHashT;
              GoRouter.of(context).go(SettingsOptions.currentScreen, extra: 0);
            }
          },
        );
      },
      onSuccess: () {
        GoRouter.of(context).go(SettingsOptions.currentScreen, extra: 0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        title: windowDragArea(),
        elevation: 0,
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/logos/netflix.png", height: 120, width: 120),
            const SizedBox(height: 20),

            // Show counter when ads are opened
            if (counterStarted) ...[
              const SizedBox(height: 30),
              Text(
                "Please wait...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$counterSeconds",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "seconds remaining",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ] else ...[
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: Colors.red),
              const SizedBox(height: 20),
              Text(
                "Loading...",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
