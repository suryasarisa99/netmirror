import 'dart:developer';
import 'dart:io';

import 'package:netmirror/constants.dart';

class ExternalPlayer {
  // Private constructor
  ExternalPlayer._();

  // Static instances for different player types
  static final _PlayerCommand onlineUrl = _PlayerCommand._('online-url');
  static final _PlayerCommand onlineFile = _PlayerCommand._('online-file');
  static final _PlayerCommand offlineFile = _PlayerCommand._('offline-file');
}

const _userAgent =
    'Mozilla/5.0 AppleWebKit/537.36 Chrome/127.0.0.0 Safari/537.36';

class _PlayerCommand {
  final String type;

  // Private constructor
  _PlayerCommand._(this.type);

  Future<void> mpv(String url) async {
    switch (type) {
      case 'online-url':
        print('MPV playing online URL: $url');
        Process.start('mpv', [
          '--no-config',
          '--demuxer=lavf',
          '--user-agent=$_userAgent',
          '--http-header-fields=${headers2.join(',')}',
          '--force-window=yes',
          '--cache=yes',
          url,
        ], mode: ProcessStartMode.detached);
        break;
      case 'online-file':
        print('MPV playing online file: $url');
        Process.start('mpv', [
          '--no-config',
          '--demuxer=lavf',
          '--force-window=yes',
          '--cache=yes',
          url,
        ], mode: ProcessStartMode.detached);
        break;
      case 'offline-file':
        print('MPV playing offline file: $url');
        Process.start('mpv', [
          '--no-config',
          '--demuxer=lavf',
          '--force-window=yes',
          url,
        ], mode: ProcessStartMode.detached);
        // await Process.run('mpv', ['--no-cache', url]);
        break;
    }
  }

  Future<void> vlc(String url) async {
    final linuxEnv = {'LD_PRELOAD': '/lib/x86_64-linux-gnu/libpthread.so.0'};
    switch (type) {
      case 'online-url':
        Process.start(
          'vlc',
          [
            '--network-caching=${20 * 60 * 60 * 1000}',
            '--fullscreen',
            '--file-caching=yes',
          ],
          mode: ProcessStartMode.detached,
          environment: Platform.isWindows ? null : linuxEnv,
        );
        break;
      case 'online-file':
        Process.start(
          'vlc',
          [
            '--network-caching=${20 * 60 * 60 * 1000}',
            '--fullscreen',
            '--file-caching=yes',
            url,
          ],
          mode: ProcessStartMode.detached,
          environment: Platform.isWindows ? null : linuxEnv,
        );
        break;
      case 'offline-file':
        Process.start(
          "vlc",
          ["--fullscreen", url],
          mode: ProcessStartMode.detached,
          environment: Platform.isWindows ? null : linuxEnv,
        );
        log("vlc --fullscreen $url");

        print('VLC playing offline file: $url');
        break;
    }
  }

  Future<void> iina(String url) async {
    Process.start('open', ['-a', 'IINA', url], mode: ProcessStartMode.detached);
  }
}
