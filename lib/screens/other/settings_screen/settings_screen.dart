import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/data/options.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _resolutionController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium;
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
            FilledButton(
              onPressed: () async {
                PermissionStatus status = await Permission.manageExternalStorage
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
          ],
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
}
