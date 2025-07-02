import 'dart:developer' as dev;

// class L {
//   static const red = '\x1B[31m';
//   static const green = '\x1B[32m';
//   static const blue = '\x1B[34m';
//   static const reset = '\x1B[0m';

//   static void error(String message, {String? n}) {
//     log('$red$message$reset', name: n ?? 'error');
//   }

//   static void info(String message, {String? n}) {
//     log('$blue$message$reset', name: n ?? 'info');
//   }

//   static void success(String message, {String? n}) {
//     log('$green$message$reset', name: n ?? 'success');
//   }
// }

class L {
  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const blue = '\x1B[34m';
  static const reset = '\x1B[0m';

  final String? name;
  const L(this.name);

  void error(String message, {String? n}) {
    dev.log('$red$message$reset', name: n ?? name ?? 'error');
  }

  void info(String message, {String? n}) {
    dev.log('$blue$message$reset', name: n ?? name ?? 'info');
  }

  void success(String message, {String? n}) {
    dev.log('$green$message$reset', name: n ?? name ?? 'success');
  }

  void log(String message, {String? n}) {
    dev.log(message, name: n ?? name ?? 'log');
  }
}
