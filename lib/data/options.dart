import 'package:netmirror/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsOptions {
  static final SettingsOptions _instance = SettingsOptions._internal();
  factory SettingsOptions() => _instance;
  SettingsOptions._internal();

  static String _currentScreen = "/nf-home";
  static bool _externalPlayer = false;
  static bool _externalDownloadPlayer = false;

  static void initialize(SharedPreferences sp) {
    externalPlayer = sp.getBool('externalPlayer') ?? false;
    externalDownloadPlayer = sp.getBool('externalDownloadPlayer') ?? false;
    currentScreen = sp.getString('currentScreen') ?? "/nf-home";
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
}
