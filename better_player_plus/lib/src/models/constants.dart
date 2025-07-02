import 'dart:io';

final isDesk = Platform.isWindows ||
    Platform.isLinux ||
    Platform.isMacOS ||
    Platform.isFuchsia;
