import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/cookies_manager.dart';
import 'package:netmirror/provider/AudioTrackProvider.dart';
import 'package:netmirror/data/options.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _initial();
  }

  void _initial() async {
    sp = await SharedPreferences.getInstance();
    ref.read(audioTrackProvider.notifier).initial();
    SettingsOptions.initialize(sp!);
    CookiesManager.initialize();
    await CookiesManager.validate();
    Future.delayed(const Duration(milliseconds: 300)).then((_) {
      // GoRouter.of(context).go("/");
      // GoRouter.of(context).go("/pv-home");
      // GoRouter.of(context).go("/nm-search");
      GoRouter.of(context).go(SettingsOptions.currentScreen, extra: 0);
    });
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
      body: Center(
        child: Image.asset(
          "assets/logos/netflix.png",
          height: 120,
          width: 120,
        ),
      ),
    );
  }
}
