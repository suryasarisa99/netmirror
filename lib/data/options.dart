import 'package:netmirror/constants.dart';
import 'package:netmirror/downloader/downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsOptions {
  static final SettingsOptions _instance = SettingsOptions._internal();
  factory SettingsOptions() => _instance;
  SettingsOptions._internal();

  static String _currentScreen = "/nf-home";
  static bool _externalPlayer = false;
  static bool _externalDownloadPlayer = false;
  static bool _fastModeByAudio = false;
  static bool _fastModeByVideo = false;
  static String? _defaultResolution;

  static void initialize(SharedPreferences sp) {
    externalPlayer = sp.getBool('externalPlayer') ?? false;
    externalDownloadPlayer = sp.getBool('externalDownloadPlayer') ?? false;
    currentScreen = sp.getString('currentScreen') ?? "/nf-home";
    _fastModeByAudio = sp.getBool('fastModeByAudio') ?? false;
    _fastModeByVideo = sp.getBool('fastModeByVideo') ?? false;
    _defaultResolution = sp.getString('defaultResolution');
  }

  static String get currentScreen => _currentScreen;
  static set currentScreen(String value) {
    _currentScreen = value;
    sp!.setString('currentScreen', value);
  }

  static bool get externalPlayer => _externalPlayer;
  static set externalPlayer(bool value) {
    _externalPlayer = value;
    sp!.setBool('externalPlayer', value);
  }

  static bool get externalDownloadPlayer => _externalDownloadPlayer;
  static set externalDownloadPlayer(bool value) {
    _externalDownloadPlayer = value;
    sp!.setBool('externalDownloadPlayer', value);
  }

  static bool get fastModeByAudio => _fastModeByAudio;
  static set fastModeByAudio(bool value) {
    _fastModeByAudio = value;
    sp!.setBool('fastModeByAudio', value);
  }

  static bool get fastModeByVideo => _fastModeByVideo;
  static set fastModeByVideo(bool value) {
    _fastModeByVideo = value;
    sp!.setBool('fastModeByVideo', value);
  }

  static String? get defaultResolution => _defaultResolution;
  static set defaultResolution(String? value) {
    _defaultResolution = value;
    if (value != null) {
      sp!.setString('defaultResolution', value);
    } else {
      sp!.remove('defaultResolution');
    }
  }

  static set maxDownloadLimit(int value) {
    Downloader.maxDownloadLimit = value;
    sp!.setInt('maxDownloadLimit', value);
  }
}
