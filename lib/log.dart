import 'dart:developer' as dev;

enum LogLevel { debug, info, success, warning, error }

class L {
  static const _red = '\x1B[38;5;198m';
  static const _green = '\x1B[32m';
  static const _blue = '\x1B[34m';
  static const _reset = '\x1B[0m';
  static const _orange = '\x1B[38;5;208m';
  static const _gray = '\x1B[38;5;245m';
  // static const _lightRed = '\x1B[31m';
  // static const _magenta = '\x1B[35m';
  // static const _cyan = '\x1B[36m';
  // static const _yellow = '\x1B[33m';

  final String? name;
  const L(this.name);

  static List<String> only = [];
  static LogLevel logLevel = LogLevel.debug;
  static bool stackStrace = false;

  static bool check(String? n) {
    if (only.isEmpty || n == null) return true;
    return only.contains(n);
  }

  void _log(
    String color,
    String message, {
    String? n,
    LogLevel level = LogLevel.info,
  }) {
    // return;
    if (level.index < logLevel.index && !check(n)) return;
    final prefix = n ?? name ?? 'log';
    if (!stackStrace) {
      dev.log('$color$message$_reset', name: prefix, level: level.index);
      return;
    }
    final stackTraceLine = StackTrace.current.toString().split('\n')[2].trim();
    final stackTracePackage = stackTraceLine.split('package')[1];
    dev.log(stackTracePackage, name: ":");
    dev.log('\t$color$message$_reset', name: prefix);
  }

  void error(String message, {String? n}) {
    _log(_red, "‼️ $message", n: n ?? name ?? 'error', level: LogLevel.error);
  }

  void warn(String message, {String? n}) {
    _log(
      _orange,
      "⚠️ $message",
      n: n ?? name ?? 'warning',
      level: LogLevel.warning,
    );
  }

  void debug(String message, {String? n}) {
    _log(_gray, "🐛 $message", n: n ?? name ?? 'debug', level: LogLevel.debug);
  }

  void info(String message, {String? n}) {
    _log(_blue, "ℹ $message", n: n ?? name ?? 'info', level: LogLevel.info);
  }

  void success(String message, {String? n}) {
    _log(
      _green,
      "✅ $message",
      n: n ?? name ?? 'success',
      level: LogLevel.success,
    );
  }

  void log(String message, {String? n}) {
    _log("", message, n: n ?? name ?? 'log', level: LogLevel.info);
  }
}
