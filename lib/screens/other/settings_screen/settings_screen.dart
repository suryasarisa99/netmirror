import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:netmirror/data/options.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        surfaceTintColor: Colors.black,
        backgroundColor: Colors.black,
        title: windowDragAreaWithChild([Text('Settings')]),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            buildPlayerRow(false),
            buildPlayerRow(true),
            FilledButton(
              onPressed: () async {
                PermissionStatus status = await Permission.manageExternalStorage
                    .request();
                if (status.isGranted) {}
              },
              child: Text("permission"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlayerRow(bool forDownload) {
    final text = forDownload ? 'Download' : 'Stream';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text('Use External Player for $text'),
          Switch(
            value: forDownload
                ? SettingsOptions.externalDownloadPlayer
                : SettingsOptions.externalPlayer,
            onChanged: (value) {
              if (forDownload) {
                SettingsOptions.externalDownloadPlayer =
                    !SettingsOptions.externalDownloadPlayer;
              } else {
                SettingsOptions.externalPlayer =
                    !SettingsOptions.externalPlayer;
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
