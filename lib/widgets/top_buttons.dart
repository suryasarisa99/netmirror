import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/constants.dart';

class TopbarButtons {
  static final TopbarButtons _instance = TopbarButtons._internal();
  factory TopbarButtons() => _instance;
  TopbarButtons._internal();

  static Widget settingsBtn(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.push("/settings");
      },
      icon: isDesk
          ? const Icon(Icons.settings, size: 18)
          : const Icon(Icons.settings, size: 24, color: Colors.white),
    );
  }

  static Widget downloadsBtn(BuildContext context) {
    return IconButton(
      onPressed: () {
        GoRouter.of(context).push("/downloads");
      },
      icon: isDesk
          ? const Icon(Icons.download, size: 20)
          : const Icon(
              HugeIcons.strokeRoundedDownload05,
              size: 30,
              color: Colors.white,
            ),
    );
  }

  static Widget searchBtn(BuildContext context, int ottId) {
    return IconButton(
      onPressed: () {
        GoRouter.of(context).push("/search/$ottId");
      },
      icon: isDesk
          ? const Icon(Icons.search, size: 20)
          : const Icon(Icons.search, size: 30, color: Colors.white),
    );
  }
}
