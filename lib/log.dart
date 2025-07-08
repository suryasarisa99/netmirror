import 'dart:developer' as dev;

class L {
  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const blue = '\x1B[34m';
  static const reset = '\x1B[0m';

  final String? name;
  const L(this.name);

  static List<String> only = [];

  static bool check(String? n) {
    if (only.isEmpty || n == null) return true;
    return only.contains(n);
  }

  void error(String message, {String? n}) {
    if (!check(name)) return;
    dev.log('$red$message$reset', name: n ?? name ?? 'error');
  }

  void info(String message, {String? n}) {
    if (!check(name)) return;
    dev.log('$blue$message$reset', name: n ?? name ?? 'info');
  }

  void success(String message, {String? n}) {
    if (!check(name)) return;
    dev.log('$green$message$reset', name: n ?? name ?? 'success');
  }

  void log(String message, {String? n}) {
    if (!check(name)) return;
    dev.log(message, name: n ?? name ?? 'log');
  }
}
