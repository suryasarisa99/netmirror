import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/data/options.dart';
import 'package:netmirror/widgets/ott_drawer.dart';

class GlobalShortcuts extends StatefulWidget {
  final Widget child;
  // final GoRouter router;
  const GlobalShortcuts({
    required this.child,
    // required this.router,
    super.key,
  });

  @override
  State<GlobalShortcuts> createState() => _GlobalShortcutsState();
}

class _GlobalShortcutsState extends State<GlobalShortcuts> {
  late BuildContext _navigatorContext;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(handleKeyEvent);
    super.dispose();
  }

  bool handleKeyEvent(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    // final r = widget.router;
    final isMeta = Platform.isMacOS
        ? HardwareKeyboard.instance.isMetaPressed
        : HardwareKeyboard.instance.isControlPressed;
    final lk = e.logicalKey;
    final ottIndex = getOttIndexFromRoute(SettingsOptions.currentScreen);

    if ((lk == LogicalKeyboardKey.arrowUp || lk == LogicalKeyboardKey.keyO) &&
        isMeta) {
      debugPrint("Show OTT Drawer");
      showModalBottomSheet(
        context: _navigatorContext,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return OttDrawer(selectedOtt: ottIndex);
        },
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        _navigatorContext = ctx;
        return widget.child;
      },
    );
  }
}
