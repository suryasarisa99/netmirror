import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/data/options.dart';
import 'package:netmirror/db/db.dart';
import 'package:netmirror/db/tables.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/movie_model.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

const l = L("Settings_Screen");

class _SettingsScreenState extends State<SettingsScreen> {
  final _resolutionController = TextEditingController();
  final _maxDownloadLimitController = TextEditingController(
    text: Downloader.maxDownloadLimit.toString(),
  );
  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium;
    return DesktopWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          surfaceTintColor: Colors.black,
          backgroundColor: Colors.black,
          automaticallyImplyLeading: !isDesk,
          title: windowDragAreaWithChild([Text('Settings')]),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildSwitch(
                "use External Player for Stream",
                SettingsOptions.externalPlayer,
                (value) {
                  SettingsOptions.externalPlayer = value;
                  setState(() {});
                },
              ),
              _buildSwitch(
                "use External Player for Download",
                SettingsOptions.externalDownloadPlayer,
                (value) {
                  SettingsOptions.externalDownloadPlayer = value;
                  setState(() {});
                },
              ),

              _buildSwitch(
                "Fast Mode, by filtering Audio",
                SettingsOptions.fastModeByAudio,
                (value) {
                  SettingsOptions.fastModeByAudio = value;
                  setState(() {});
                },
              ),
              _buildSwitch(
                "Fast Mode, by filtering Video",
                SettingsOptions.fastModeByVideo,
                (value) {
                  SettingsOptions.fastModeByVideo = value;
                  setState(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text("Default Quality", style: labelStyle),
                    const Spacer(),
                    DropdownMenu<String>(
                      controller: _resolutionController,
                      menuStyle: MenuStyle(),
                      enableFilter: false,
                      enableSearch: false,
                      width: 135,
                      alignmentOffset: const Offset(15, 8),
                      inputDecorationTheme: InputDecorationTheme(
                        isDense: true,
                        suffixIconConstraints: const BoxConstraints(
                          maxHeight: 42,
                          maxWidth: 40,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                          vertical: 0.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      trailingIcon: const Icon(
                        HugeIcons.strokeRoundedAbacus,
                        size: 20,
                      ),
                      // prevent to  show keyboard ( prevent edit text field )
                      requestFocusOnTap: false,
                      initialSelection: SettingsOptions.defaultResolution,
                      onSelected: (value) {
                        if (value != null) {
                          _resolutionController.text = value;
                          SettingsOptions.defaultResolution = value;
                        }
                      },
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(
                          value: "1080p",
                          label: "1080p",
                          trailingIcon: Icon(Icons.brightness_auto),
                        ),
                        DropdownMenuEntry(
                          value: "720p",
                          label: "720p",
                          trailingIcon: Icon(Icons.sunny),
                        ),
                        DropdownMenuEntry(
                          value: "480p",
                          label: "480p",
                          trailingIcon: Icon(Icons.brightness_3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text("Max Download Limit", style: labelStyle),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        showPopupTextField(
                          context,
                          "Max Download Limit",
                          _maxDownloadLimitController,
                          () {
                            SettingsOptions.maxDownloadLimit = int.parse(
                              _maxDownloadLimitController.text,
                            );
                            Navigator.of(context).pop();
                            setState(() {});
                            return true;
                          },
                        );
                      },
                      child: Text(Downloader.maxDownloadLimit.toString()),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () async {
                  PermissionStatus status = await Permission
                      .manageExternalStorage
                      .request();
                  if (status.isGranted) {}
                },
                child: Text("permission"),
              ),
              FilledButton(
                onPressed: () async {
                  GoRouter.of(context).push('/settings-audio-tracks');
                },
                child: Text("Audio Tracks"),
              ),
              FilledButton(
                onPressed: () async {
                  final db = await DB.instance.database;
                  final result = await db.query(Tables.movie);
                  log("result length: ${result.length}");
                  for (var item in result) {
                    final key = item['key'] as String;
                    final val = Movie.fromJson(
                      jsonDecode(item['value']! as String),
                      key,
                      null,
                    );
                    if (val.isMovie) continue;
                    for (final season in val.seasons.values) {
                      if (season.episodes != null &&
                          season.episodes!.isNotEmpty &&
                          season.ep < 6) {
                        final episodes = season.episodes!.values.toList();
                        for (final episode in episodes) {
                          if (int.parse(episode.time.substring(0, 2)) < 20) {
                            log(
                              "title: ${val.title}, ott: ${val.ott},ep:${season.ep} time: ${episode.time}",
                            );
                          }
                        }
                      }
                    }
                  }
                },
                child: Text("Audio Tracks"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isEnabled = true,
  }) {
    return SwitchListTile(
      activeColor: Theme.of(context).colorScheme.primary,
      title: Text(title),
      value: value,
      onChanged: isEnabled
          ? onChanged
          : null, // Disable the switch if isEnabled is false
    );
  }

  void showPopupTextField(
    BuildContext context,
    String title,
    TextEditingController controller,
    bool Function() onSave,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            controller: controller,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: "Type here...",
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (onSave()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
