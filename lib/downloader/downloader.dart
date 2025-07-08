import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:netmirror/api/playlist/get_audio_hls.dart';
import 'package:netmirror/api/playlist/get_master_hls.dart';
import 'package:netmirror/api/playlist/get_video_hls.dart';
import 'package:netmirror/api/playlist/local_playlist.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/downloader/download_db.dart';
import 'package:netmirror/log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_code/models/movie_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

const l = L("downloader");

class Downloader {
  // singleton
  static final Downloader _instance = Downloader._internal();
  static bool _isInitialized = false;
  static final Future<Database> _db = DownloadDb.instance.database;
  final _progressController = StreamController<DownloadProgress>.broadcast();
  final _notifications = FlutterLocalNotificationsPlugin();
  static late final Directory downloadDir;

  static final int maxDownloadLimit = 2;
  static int currentDownloadItems = 0;

  Downloader._internal();
  static Downloader get instance {
    if (!_isInitialized) {
      _instance.initialize();
      _isInitialized = true;
    }
    return _instance;
  }

  factory Downloader() {
    if (!_isInitialized) {
      _instance.initialize();
      _isInitialized = true;
    }
    return _instance;
  }

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  int count = 0;
  Future<void> initializeNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notifications.initialize(initializationSettings);
  }

  void initialize() async {
    if (!isDesk) await initializeNotifications();
    // downloadDir = isDesk
    //     ? await getApplicationSupportDirectory()
    //     : Directory("/storage/emulated/0/Download/netmirror");
    late String downloadDirPath;
    if (isDesk) {
      downloadDirPath = p.join(
        (await getDownloadsDirectory())!.path,
        'netmirror',
      );
    } else {
      downloadDirPath = "/storage/emulated/0/Download/netmirror";
    }
    downloadDir = Directory(downloadDirPath);
    downloadDir.create(recursive: true);
    DownloadDb.instance.database;
    continueDownloadAfterAppOpen();
    // syncDownloadCounter();
  }

  Future<void> pauseDownload(String videoId) async {
    final db = await _db;
    pauseFlags[videoId] = true;
    DownloadDb.instance.getDownloadStatus(videoId).then((status) {
      if (status == "downloading") {
        decrementCurrentDownloadItems();
      }
    });
    // may be not required
    l.info("Paused Download: [$videoId]");
    _progressController.add(DownloadProgress.status(videoId, "paused"));
    await db.update(
      DownloadTables.downloads,
      {'status': 'paused'},
      where: 'id = ?',
      whereArgs: [videoId],
    );
    if (currentDownloadItems < maxDownloadLimit) {
      continueDownload();
    }
  }

  Future<void> moveToPending(String videoId) async {
    final db = await _db;
    _progressController.add(DownloadProgress.status(videoId, "pending"));
    await db.update(
      DownloadTables.downloads,
      {'status': 'pending'},
      where: 'id = ?',
      whereArgs: [videoId],
    );
  }

  Future<void> moveToDownloadingStatus(List<String> ids) async {
    final db = await _db;
    for (var id in ids) {
      _progressController.add(DownloadProgress.status(id, "downloading"));
    }
    await db.update(
      DownloadTables.downloads,
      {'status': DownloadStatus.downloading},
      where: 'id IN (${ids.map((id) => '?').join(', ')})',
      whereArgs: ids,
    );
  }

  Future<void> resumeDownload(String videoId) async {
    final db = await _db;
    l.debug("pause flags: $pauseFlags");

    // if (pauseFlags[videoId] == false) {
    //   l.warn("Download already in progress for $videoId");
    //   return;
    // }
    if (currentDownloadItems >= maxDownloadLimit) {
      moveToPending(videoId);
      return;
    }

    pauseFlags[videoId] = false;
    _progressController.add(DownloadProgress.status(videoId, "downloading"));
    await db.update(
      DownloadTables.downloads,
      {'status': 'downloading'},
      where: 'id = ?',
      whereArgs: [videoId],
    );

    currentDownloadItems++;
    l.info("Resume Download: ($currentDownloadItems >= $maxDownloadLimit)");
    processDownload(videoId);
  }

  static Future<void> deleteItem(String videoId) async {
    final db = await _db;
    l.info("Deleting: $videoId");
    pauseFlags[videoId] = true;
    final downloads = await db.query(
      DownloadTables.downloads,
      where: 'id = ?',
      whereArgs: [videoId],
    );

    if (downloads.isNotEmpty) {
      final item = downloads.first;
      if (item['status'] == 'downloading') {
        pauseFlags[videoId] = true;
        decrementCurrentDownloadItems();
      }
      final file = File(downloads.first['playlist_path'] as String);
      final downloadPath =
          "${downloads.first['download_path'] as String}/.${item['video_id']}";
      l.log("downloadPath: $downloadPath");
      if (await file.exists()) {
        await file.delete();
      }
      final directory = Directory(downloadPath);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
    db.delete(DownloadTables.downloads, where: 'id = ?', whereArgs: [videoId]);
  }

  static Future<void> deleteSeries(String id) async {
    final db = await _db;
    // pause all episodesFlags
    l.log("Deleting Series: $id");

    final episodes = (await db.query(
      DownloadTables.downloads,
      columns: ['id', 'download_path', 'playlist_path', 'status'],
      where: 'series_id = ? AND type = ?',
      whereArgs: [id, DownloadType.episode],
    ));

    for (int i = 0; i < episodes.length; i++) {
      final videoId = episodes[i]['id'] as String;
      final status = episodes[i]['status'] as String;
      if (status == "downloading") {
        pauseFlags[videoId] = true;
        decrementCurrentDownloadItems();
        l.info("Paused Item (because of series delete): $videoId");
      }
    }

    for (int i = 0; i < episodes.length; i++) {
      final episode = episodes[i];
      final file = File(episode['playlist_path'] as String);
      final downloadPath =
          "${episode['download_path'] as String}/.${episode['id']}";
      final directory = Directory(downloadPath);
      if (await file.exists()) {
        await file.delete();
      }
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
    await db.transaction((txn) async {
      await txn.delete(
        DownloadTables.downloads,
        where: 'series_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        DownloadTables.downloads,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<(List<String>, List<String>)> getDownloadingAndPendingIds() async {
    final db = await _db;
    const query = """
    SELECT id, status FROM downloads 
    WHERE (status = 'downloading' OR status = 'pending') AND (type != 'series')
    ORDER BY updated_at
    """;
    final result = await db.rawQuery(query);
    // separate downloading and pending
    final List<String> pendings = [];
    final List<String> downloadings = [];
    for (var item in result) {
      final id = item['id'] as String;
      item['status'] == 'downloading' ? downloadings.add(id) : pendings.add(id);
    }
    l.log("Downloading: ${downloadings.length}");
    return (downloadings, pendings);
  }

  Future<void> continueDownloadAfterAppOpen() async {
    final (downloading, pending) = await getDownloadingAndPendingIds();
    l.info(
      "Continue Download After Open: Downloading: ${downloading.length} || Pending: ${pending.length}",
    );
    int count = 0;
    for (final downloadId in downloading) {
      if (count >= maxDownloadLimit) break;
      processDownload(downloadId);
      count++;
    }
    for (final downloadId in pending) {
      if (count >= maxDownloadLimit) break;
      processDownload(downloadId);
      count++;
    }
    currentDownloadItems = count;
  }

  Future<List<String>> getPendingIds() async {
    final db = await _db;
    final result = await db.query(
      DownloadTables.downloads,
      columns: ["id"],
      where: 'status = ?',
      whereArgs: ['pending'],
    );
    return result.map((e) => e['id'] as String).toList();
  }

  Future<void> continueDownload() async {
    if (currentDownloadItems >= maxDownloadLimit) return;
    final pending = await getPendingIds();
    final remaining = (maxDownloadLimit - currentDownloadItems).clamp(
      0,
      maxDownloadLimit,
    );
    l.info(
      "Continue Download: Remaining:($maxDownloadLimit - $currentDownloadItems == $remaining)",
    );

    final idsToStart = pending.take(remaining).toList();
    moveToDownloadingStatus(idsToStart);

    for (final downloadId in idsToStart) {
      // Check if already downloading to prevent duplicates
      if (pauseFlags[downloadId] == false) {
        l.warn("Download already in progress for $downloadId");
        continue;
      }

      l.info("Continue Download: [$downloadId]");
      currentDownloadItems++;
      processDownload(downloadId);
    }
  }

  Future<void> _updateProgress({
    required int currentPart,
    required int totalParts,
    required String id,
    bool isAudio = false,
  }) async {
    final progress = (currentPart / totalParts * 100).toInt();
    _progressController.add(
      DownloadProgress(
        id: id,
        currentPart: currentPart,
        totalParts: totalParts,
        status: null,
        progress: progress,
        isAudio: isAudio,
      ),
    );
    await DownloadDb.instance.updateProgress(
      id,
      currentPart,
      progress,
      isAudio: isAudio,
    );
  }

  Future<void> updateAudioLangs(
    String videoId,
    List<DownloadAudioLangs> audioLangs,
  ) async {
    _progressController.add(DownloadProgress.audioLangs(videoId, audioLangs));
    await DownloadDb.instance.updateAudioLangs(videoId, audioLangs);
  }

  Future<void> updateNotification(
    int downloadId,
    int progress, {
    bool isAudio = false,
  }) async {
    if (isDesk) return;

    final androidDetails = AndroidNotificationDetails(
      'downloads_channel',
      'Downloads',
      channelDescription: 'Show download progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
    );

    await _notifications.show(
      downloadId,
      'Downloading ${isAudio ? ' Audio' : 'Video'}',
      'Progress: $progress%',
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> createLocalPlaylist({
    required String downloadPath,
    required String sourceRaw,
    required String videoSourceRaw,
    required String audioSourceRaw,
    required bool hasExternalAudio,
    required String videoId,
    required String playlistPath,
    required List<DownloadAudioLangs> audioLangs,
  }) async {
    // create local video playlist
    final videoHlsDirSuffixPath = p.join(downloadPath, ".$videoId", "videos");
    final videoHlsDir = Directory(p.join(downloadPath, videoHlsDirSuffixPath));
    await videoHlsDir.create(recursive: true);
    final videoHlsFile = File(p.join(videoHlsDir.path, "videoHls.m3u8"));
    final fixedVideoHlsData = makeLocalVideoPlaylist(videoSourceRaw);
    await videoHlsFile.writeAsString(fixedVideoHlsData);
    // await videoHlsFile.writeAsString(videoSourceRaw);

    // create local audio playlist
    if (hasExternalAudio) {
      final audioHlsData = makeLocalAudioPlaylist(audioSourceRaw);
      for (var audioLang in audioLangs) {
        final audioHlsDir = Directory(
          p.join(downloadPath, ".$videoId", "audios-${audioLang.audioIndex}"),
        );
        await audioHlsDir.create();
        final audioHlstFile = File(p.join(audioHlsDir.path, "audioHls.m3u8"));
        await audioHlstFile.writeAsString(audioHlsData);
        // await audioHlstFile.writeAsString(audioSourceRaw);
      }
    }
    // create main playlist
    final playlistFile = File(playlistPath);
    final fixedPlaylistData = makeLocalPlaylist(
      sourceRaw,
      videoId,
      audioLangs.map((e) => e.audioIndex).toList(),
    );
    await playlistFile.writeAsString(fixedPlaylistData);
    // await playlistFile.writeAsString(sourceRaw);
  }

  static Future<String> createDownloadDirectory() async {
    final baseDir = isDesk
        ? await getApplicationSupportDirectory()
        : Directory("/storage/emulated/0/Download");
    return p.join(baseDir.path, 'netmirror');
  }

  Future<(Map<String, dynamic>, int)> createDownloadItem({
    required String videoId,
    required int ottId,
    required String title,
    required bool isMovie,
    required String thumbnail,
    required String sourceRaw,
    required MasterPlayList masterPlaylist,
    required int qualityIndex,
    required List<int> audioIndexes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final playlistPath = p.join(
      downloadDir.path,
      "$title-$videoId.${isDesk ? "m3u8" : "mp4"}",
    );

    // Audio Management
    String audioExtension = "";
    String audioSuffix = "";
    String audioPrefix = "";
    final bool hasExternalAudio = masterPlaylist.audios.isNotEmpty;
    String audioHlsData = "";
    List<DownloadAudioLangs> audioLangs = [];

    if (hasExternalAudio) {
      audioHlsData = await getAudioHls(
        id: videoId,
        audioSrc: masterPlaylist.audios.first,
      );
      final audioSrc = masterPlaylist.audios.first;
      audioPrefix = audioSrc.prefix;
      audioSuffix = "a/${audioSrc.number}";
      audioHlsData.split("\n").any((elm) {
        if (elm.endsWith(".jpg")) {
          audioExtension = "jpg";
          return true;
        } else if (elm.endsWith(".js")) {
          audioExtension = "js";
          return true;
        } else {
          return false;
        }
      });

      audioLangs = audioIndexes.map((index) {
        final suffix = masterPlaylist.audios[index].suffix;
        return DownloadAudioLangs(
          audioSuffix: suffix,
          audioIndex: int.parse(masterPlaylist.audios[index].number),
          status: false,
        );
      }).toList();
    }

    // Video Management
    final videoSrc = masterPlaylist.videos[qualityIndex];
    final videoHlsData = await getVideoHls(
      id: videoId,
      src: masterPlaylist.videos[qualityIndex],
      isShow: !isMovie,
    );
    final lines = videoHlsData.split('\n');
    final videoUrls = lines.where((line) => line.endsWith('.jpg')).toList();
    if (videoUrls.isEmpty) {
      l.error("Error: Parsing videoHlsData failed, no video urls found");
      throw Exception(
        "Error: Parsing videoHlsData failed, no video urls found",
      );
    }
    final firstUrl = videoUrls.first;
    final lastUrl = videoUrls.last;
    final uniqueId = firstUrl.split('/').last.split('_').first;
    final totalParts = int.parse(lastUrl.split('_').last.split('.').first) + 1;
    final resolution = videoSrc.quality;
    final prefix = videoSrc.prefix;

    await createLocalPlaylist(
      downloadPath: downloadDir.path,
      sourceRaw: sourceRaw,
      videoSourceRaw: videoHlsData,
      audioSourceRaw: audioHlsData,
      hasExternalAudio: hasExternalAudio,
      videoId: videoId,
      audioLangs: audioLangs,
      playlistPath: playlistPath,
    );

    // Insert main download record
    final record = {
      'id': videoId,
      'ott_id': ottId,
      'title': title,
      'type': isMovie ? 'movie' : 'episode',
      'thumbnail': thumbnail,
      'status': currentDownloadItems < maxDownloadLimit
          ? 'downloading'
          : 'pending',
      'created_at': now,
      'updated_at': now,
      'download_path': downloadDir.path,
      'playlist_path': playlistPath,
      'resolution': resolution,
      'unique_id': uniqueId,
      'total_parts': totalParts,
      'video_prefix': prefix,
      'audio_prefix': audioPrefix,
      'audio_suffix': audioSuffix,
      'audio_ext': audioExtension,
      // 'run_time': runtime,
      'audio_langs': jsonEncode(audioLangs.map((e) => e.toJson()).toList()),
    };

    return (record, totalParts);
  }

  //* @startSeasonDownload
  Future<void> startSeasonDownload(
    MinifyMovie movie,
    int seasonNumber,
    List<Episode> episodes,
    int qualityIndex,
    List<int> audioIndexes,
    String firstEpisodeSourceRaw,
    String resourceKey,
  ) async {
    // its a dummy item, to show series image and title
    await DownloadDb.instance.insertSeries({
      'id': movie.id,
      'ott_id': movie.ott.id,
      'title': movie.title,
      'type': 'series',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'thumbnail': movie.ott.getImg(movie.id, forceHorizontal: true),
    });

    for (int i = 0; i < episodes.length; i++) {
      final episode = episodes[i];
      final sourceRaw = i == 0
          ? firstEpisodeSourceRaw
          : await getMasterHls(episode.id, resourceKey, movie.ott);
      final masterPlayList = parseMasterHls(sourceRaw);
      final videoId = episode.id;

      final (record, totalParts) = await createDownloadItem(
        videoId: videoId,
        masterPlaylist: masterPlayList,
        title: movie.title,
        ottId: movie.ott.id,
        isMovie: movie.isMovie,
        thumbnail: movie.ott.getImg(videoId, forceHorizontal: true),
        qualityIndex: qualityIndex,
        sourceRaw: sourceRaw,
        audioIndexes: audioIndexes,
      );

      DownloadDb.instance
          .insertItem({
            ...record,
            'series_id': movie.id,
            'runtime': episode.time,
            'season_number': seasonNumber,
            'episode_number': int.parse(episode.ep.substring(1)),
          })
          .then((value) {
            _progressController.add(
              DownloadProgress(id: videoId, seriesId: movie.id, newItem: true),
            );
            l.info("add episodes: ${episodes.length}");
            _progressController.add(
              DownloadProgress(id: movie.id, totalEpisodesPlus: 1),
            );
            if (currentDownloadItems < maxDownloadLimit) {
              // Check if already downloading to prevent duplicates
              if (pauseFlags[videoId] != false) {
                l.log("$currentDownloadItems < $maxDownloadLimit");
                currentDownloadItems++;
                processDownload(videoId);
              } else {
                l.warn("Download already in progress for $videoId");
              }
            }
          });
    }
  }

  //* @startDownload [ movie or single episode ]
  Future<void> startDownload(
    MinifyMovie movie,
    String sourceRaw,
    List<int> audioIndexes,
    int qualityIndex,
    String resourceKey,
    MasterPlayList masterPlaylist, {
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final db = await _db;
    final videoId = movie.isShow
        ? masterPlaylist.videos[qualityIndex].videoId
        : movie.id;

    final (record, totalParts) = await createDownloadItem(
      videoId: videoId,
      ottId: movie.ott.id,
      masterPlaylist: masterPlaylist,
      title: movie.title,
      isMovie: movie.isMovie,
      thumbnail: movie.ott.getImg(videoId, forceHorizontal: true),
      qualityIndex: qualityIndex,
      sourceRaw: sourceRaw,
      audioIndexes: audioIndexes,
    );
    // return;

    if (movie.isShow) {
      final episode = movie.seasons[seasonNumber]!.episodes![episodeNumber!]!;
      await DownloadDb.instance.insertSeriesWithEpisodes(
        {
          'id': movie.id,
          'ott_id': movie.ott.id,
          'title': movie.title,
          'type': 'series',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'thumbnail': movie.ott.getImg(movie.id, forceHorizontal: true),
        },
        [
          {
            ...record,
            'series_id': movie.id,
            'runtime': episode.time,
            'season_number': seasonNumber,
            'episode_number': episodeNumber,
          },
        ],
      );
      _progressController.add(
        DownloadProgress(id: movie.id, downloadedEpisodesPlus: 1),
      );
    } else {
      // is movie
      await db.insert(DownloadTables.downloads, {
        ...record,
        'runtime': movie.runtime,
      });
    }

    _progressController.add(
      DownloadProgress(
        id: videoId,
        currentPart: 0,
        progress: 0,
        totalParts: totalParts,
        status: currentDownloadItems < maxDownloadLimit
            ? "downloading"
            : "pending",
        isAudio: masterPlaylist.audios.isNotEmpty,
        newItem: true,
      ),
    );

    if (currentDownloadItems < maxDownloadLimit) {
      // Check if already downloading to prevent duplicates
      if (pauseFlags[videoId] != false) {
        currentDownloadItems++;
        processDownload(videoId);
      } else {
        l.warn("Download already in progress for $videoId");
      }
    }
  }

  //* @processDownload

  Future<void> processDownload(String videoId) async {
    l.info("Process Download : $videoId");
    final info = await DownloadDb.instance.getDownloadItem(videoId);
    final videoDir = Directory(
      p.join(info.downloadPath, ".${info.id}", "videos"),
    );
    final db = await _db;

    pauseFlags[videoId] = false;

    try {
      // download Audio Parts
      if (info.audioPrefix == "") {
        info.currentAudioPart = info.totalParts;
        _updateProgress(
          id: videoId,
          currentPart: info.currentAudioPart,
          totalParts: info.totalParts,
          isAudio: true,
        );
      }

      for (int i = 0; i < info.audioLangs.length; i++) {
        final audioLang = info.audioLangs[i];
        if (audioLang.status) continue;
        final audioSDirPath = p.join(
          ".${info.id}",
          "audios-${audioLang.audioIndex}",
        );
        final audioDir = Directory(p.join(info.downloadPath, audioSDirPath));

        while (info.currentAudioPart < info.totalParts) {
          final partId =
              "${info.uniqueId}_${info.currentAudioPart.toString().padLeft(3, '0')}";
          // final url =
          //     'https://${info.audioPrefix}.top/files/${info.videoId}/${info.audioSuffix}/$partId.${info.audioExt}';
          final url =
              'https://${info.audioPrefix}.top/files/${info.id}/a/${audioLang.audioIndex}/$partId.${info.audioExt}';
          // log("audio url: $url");
          final response = await Dio().get(
            url,
            options: Options(
              headers: headers,
              responseType: ResponseType.bytes,
            ),
          );
          // log("write data at: ${file.path}");
          final file = File(p.join(audioDir.path, "$partId.aac"));
          file.writeAsBytes(response.data).catchError((err) {
            l.error(
              "write Audio data error (Expected Error Happens Because Download was deleted)  : $err",
            );
            return file;
          });
          info.currentAudioPart++;
          _updateProgress(
            id: videoId,
            currentPart: info.currentAudioPart,
            totalParts: info.totalParts,
            isAudio: true,
          );
          if (pauseFlags[videoId] == true) {
            l.info("Paused Download in Process Download: [$videoId]");
            return;
          }
        }
        info.audioLangs[i].status = true;
        updateAudioLangs(videoId, info.audioLangs);
        info.currentAudioPart = 0;
      }

      // download video parts
      while (info.currentVideoPart < info.totalParts) {
        final partId =
            "${info.uniqueId}_${info.currentVideoPart.toString().padLeft(3, '0')}";
        final url =
            "https://${info.videoPrefix}.top/files/${info.id}/${info.resolution}/$partId.jpg";
        l.debug("url: $url");
        final response = await Dio().get(
          url,
          options: Options(headers: headers, responseType: ResponseType.bytes),
        );
        final file = File(p.join(videoDir.path, "$partId.mp4"));
        file.writeAsBytes(response.data).catchError((err) {
          l.error(
            "write Video data error (Expected Error Happens Because Download was deleted)  : $err",
          );
          return file;
        });
        info.currentVideoPart++;
        _updateProgress(
          id: videoId,
          currentPart: info.currentVideoPart,
          totalParts: info.totalParts,
        );

        // Check if the task has been cancelled
        if (pauseFlags[videoId] == true) {
          l.info("Paused Download: [$videoId]");
          return;
        }
      }
      l.success("Download Completed");
      decrementCurrentDownloadItems(); // Decrement counter on completion
      _progressController.add(DownloadProgress.status(videoId, "completed"));
      if (info.type == "episode") {
        _progressController.add(
          DownloadProgress(id: info.seriesId!, downloadedEpisodesPlus: 1),
        );
      }
      await db.update(
        DownloadTables.downloads,
        {'status': 'completed'},
        where: 'id = ?',
        whereArgs: [videoId],
      );
      l.info("Download Completed calling: continueDownload");
      continueDownload();
    } catch (e) {
      l.error("Error at Download: $e");
      decrementCurrentDownloadItems();
      _progressController.add(DownloadProgress.status(videoId, "failed"));
      await db.update(
        DownloadTables.downloads,
        {'status': 'failed'},
        where: 'id = ?',
        whereArgs: [videoId],
      );
      l.error("Download Failed calling: continueDownload");
      continueDownload();
    }
  }

  static decrementCurrentDownloadItems() {
    /*
    decrements when :
      1. Download Completed
      2. Download Failed
      3. Download Paused
      4. Download item Deleted
      5. Download Series Deleted
    */
    currentDownloadItems = max(0, currentDownloadItems - 1);
  }

  // Future<void> syncDownloadCounter() async {
  //   final (downloading, _) = await getDownloadingAndPendingIds();
  //   currentDownloadItems = downloading.length;
  //   l.info("Synced currentDownloadItems to: $currentDownloadItems");
  // }
}
