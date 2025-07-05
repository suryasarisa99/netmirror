import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

List<Widget> windowItems() {
  if (Platform.isLinux || Platform.isWindows) {
    return [
      WindowButton(
        icon: Icons.remove,
        onPressed: () async {
          await windowManager.minimize();
        },
      ),
      WindowButton(
        icon: Icons.crop_square,
        onPressed: () async {
          if (await windowManager.isMaximized()) {
            await windowManager.unmaximize();
          } else {
            await windowManager.maximize();
          }
        },
      ),
      WindowButton(
        icon: Icons.close,
        onPressed: () async {
          await windowManager.close();
        },
      ),
    ];
  } else {
    // return [SizedBox(width: 100)];
    return [];
  }
}

Widget windowDragArea({withWindowItems = true}) {
  return GestureDetector(
    onPanStart: (details) {
      windowManager.startDragging();
    },
    onDoubleTap: () async {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    },
    child: Container(
      height: kToolbarHeight,
      color: Colors.transparent,
      // color: Colors.red,
      child: withWindowItems
          ? Row(children: [const Spacer(), ...windowItems()])
          : null,
    ),
  );
}

Widget windowDragAreaWithChild(
  List<Widget> children, {
  withWindowItems = true,
  List<Widget> actions = const [],
}) {
  if (Platform.isLinux || Platform.isWindows) {
    return GestureDetector(
      onPanStart: (details) {
        windowManager.startDragging();
      },
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Container(
        height: kToolbarHeight,
        color: Colors.transparent,
        // color: Colors.red,
        child: Row(
          children: [
            ...children,
            if (withWindowItems) ...[
              const Spacer(),
              ...actions,
              ...windowItems(),
            ],
          ],
        ),
      ),
    );
  } else {
    return Row(
      children: [
        if (Platform.isMacOS) SizedBox(width: 60), // For macOS titlebar spacing
        ...children, const Spacer(), ...actions,
      ],
    );
  }
}

class WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const WindowButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon, size: 16), onPressed: onPressed);
  }
}
