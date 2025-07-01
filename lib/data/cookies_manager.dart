import 'dart:convert';
import 'dart:developer';
import 'package:netmirror/api/get_initial.dart';
import 'package:netmirror/constants.dart';

class CookiesManager {
  static final CookiesManager _instance = CookiesManager._internal();
  factory CookiesManager() => _instance;
  CookiesManager._internal();

  static String? _tHashT;
  static DateTime? _tHashTExpire;
  static String? _addhash;
  static String? _resourceKey;
  static DateTime? _resourceExpire;

  static Future<void> initialize() async {
    final cookiesJson = sp?.getString("cookies");
    if (cookiesJson != null && cookiesJson.isNotEmpty) {
      try {
        final data = jsonDecode(cookiesJson);
        _tHashT = data["tHashT"];
        _tHashTExpire = data["tHashTExpire"] != null
            ? DateTime.parse(data["tHashTExpire"])
            : null;
        _addhash = data["addhash"];
        _resourceKey = data["resourceKey"];
        _resourceExpire = data["resourceExpire"] != null
            ? DateTime.parse(data["resourceExpire"])
            : null;
      } catch (e) {
        log("Error parsing cookies JSON: $e");
        // _clearData();
      }
    }
  }

  // Getters
  static String? get tHashT => _tHashT;
  static String? get resourceKey => _resourceKey;

  static set tHashT(String? tHashT) {
    if (tHashT == null) throw Exception("tHashT cannot be null while setting");
    _tHashT = tHashT;
    _tHashTExpire = DateTime.now().add(const Duration(hours: 18, minutes: 30));
    _save();
  }

  static set resourceKey(String? resourceKey) {
    if (resourceKey == null) {
      throw Exception("resourceKey cannot be null while setting");
    }
    _resourceKey = resourceKey;
    _resourceExpire = DateTime.now().add(const Duration(days: 1));
    _save();
  }

  static set addHash(String addhash) {
    _addhash = addhash;
    _save();
  }

  static bool get isExpired {
    return _tHashT == null ||
        _tHashTExpire == null ||
        _tHashT!.isEmpty ||
        _tHashTExpire!.isBefore(DateTime.now());
  }

  static bool get isValidResourceKey =>
      _resourceKey != null &&
      _resourceExpire != null &&
      _resourceKey!.isNotEmpty &&
      _resourceKey!.length > 5 &&
      _resourceExpire!.isAfter(DateTime.now());

  static Future<void> validate() async {
    if (isExpired) {
      log("thasht is expired");
      addHash = await getInitial();

      await openAdd(_addhash!);

      await Future.delayed(const Duration(seconds: 35), () async {
        try {
          final newTHashT = await verifyAdd(_addhash!);
          log("new thash $newTHashT");
          if (newTHashT != null) {
            tHashT = newTHashT;
          }
        } catch (e) {
          log("exception in getting verify add $e");
        }
      });
    }
  }

  static Future<String> get validTHashT async {
    if (isExpired) {
      await validate();
    }
    return _tHashT!;
  }

  static void _save() {
    final data = {
      "tHashT": _tHashT,
      "tHashTExpire": _tHashTExpire?.toIso8601String(),
      "addhash": _addhash,
      "resourceKey": _resourceKey,
      "resourceExpire": _resourceExpire?.toIso8601String(),
    };
    sp?.setString("cookies", jsonEncode(data));
  }

  static void _clearData() {
    _tHashT = null;
    _tHashTExpire = null;
    _addhash = null;
    _resourceKey = null;
    _resourceExpire = null;
  }
}
