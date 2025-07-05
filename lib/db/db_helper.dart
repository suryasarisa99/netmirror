import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:netmirror/models/netmirror/movie_model.dart';
import 'package:netmirror/models/prime_video/pv_home_model.dart';
import 'package:netmirror/models/watch_model.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Database? _db;

  factory DBHelper() {
    return instance;
  }

  DBHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    String path = p.join(await getDatabasesPath(), 'netmirror.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE ott_pv_home (key TEXT PRIMARY KEY, value TEXT)',
        );
        await db.execute(
          'CREATE TABLE ott_nf_home (key TEXT PRIMARY KEY, value TEXT)',
        );
        await db.execute(
          'CREATE TABLE movie (key TEXT PRIMARY KEY, value TEXT)',
        );
        await db.execute('''CREATE TABLE watch_history (
            video_id TEXT PRIMARY KEY,
            id TEXT NOT NULL,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            is_show INTEGER NOT NULL,
            duration INTEGER NOT NULL,
            current INTEGER NOT NULL,
            scale_x REAL NOT NULL DEFAULT 1.0,
            scale_y REAL NOT NULL DEFAULT 1.0,
            speed REAL NOT NULL DEFAULT 1.0,
            fit TEXT NOT NULL DEFAULT 'contain',
            episode_index INTEGER,
            season_index INTEGER,
            last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
          )''');
        // for (final statement in DownloadTables.createStatements) {
        //   await db.execute(statement);
        // }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS ott_nf_home (key TEXT PRIMARY KEY, value TEXT)',
          );
          print('Table ott_nf_home created during upgrade');
        }
        if (oldVersion < 5) {
          await db.execute('''CREATE TABLE IF NOT EXISTS watch_history (
              video_id TEXT PRIMARY KEY,
              id TEXT NOT NULL,
              title TEXT NOT NULL,
              url TEXT NOT NULL,
              is_show INTEGER NOT NULL,
              duration INTEGER NOT NULL,
              current INTEGER NOT NULL,
              scale_x REAL NOT NULL DEFAULT 1.0,
              scale_y REAL NOT NULL DEFAULT 1.0,
              speed REAL NOT NULL DEFAULT 1.0,
              fit TEXT NOT NULL DEFAULT 'contain',
              episode_index INTEGER,
              season_index INTEGER,
              last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
            )''');
          print('Table watch_history created during upgrade');
        }
      },
      // onOpen: (Database db) async {
      //   // Enable foreign keys
      //   await db.execute('PRAGMA foreign_keys = ON');
      // },
    );
  }

  Future<void> disonnect() async {
    _db?.close();
    _db = null;
  }

  Future<void> addPvHomePage(String key, PvHomeModel data) async {
    final db = await database;
    db.insert("ott_pv_home", {
      'key': key,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addNfHomePage(String key, NfHomeModel data) async {
    final db = await database;
    db.insert("ott_nf_home", {
      'key': key,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PvHomeModel?> getPvHomePage(String key) async {
    final db = await database;
    final res = await db.query(
      "ott_pv_home",
      where: 'key = ?',
      whereArgs: [key],
    );
    if (res.isEmpty) return null;
    return PvHomeModel.fromJson(jsonDecode(res.first['value']! as String));
  }

  Future<NfHomeModel?> getNfHomePage(String key) async {
    final db = await database;
    final res = await db.query(
      "ott_nf_home",
      where: 'key = ?',
      whereArgs: [key],
    );
    if (res.isEmpty) return null;
    return NfHomeModel.fromJson(jsonDecode(res.first['value']! as String));
  }

  Future<void> addMovie(String key, Movie data) async {
    final db = await database;
    db.insert("movie", {
      'key': key,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Movie?> getMovie(String key) async {
    final db = await database;
    final res = await db.query("movie", where: 'key = ?', whereArgs: [key]);
    if (res.isEmpty) return null;
    return Movie.fromJson(jsonDecode(res.first['value']! as String), key, null);
  }

  // Watch History Methods

  /// Save or update watch history for a video
  Future<void> saveWatchHistory(WatchHistoryModel watchHistory) async {
    final db = await database;
    await db.insert("watch_history", {
      'id': watchHistory.id,
      'video_id': watchHistory.videoId.toString(),
      'title': watchHistory.title,
      'url': watchHistory.url,
      'is_show': watchHistory.isShow ? 1 : 0,
      'duration': watchHistory.duration,
      'current': watchHistory.current,
      'scale_x': watchHistory.scaleX,
      'scale_y': watchHistory.scaleY,
      'speed': watchHistory.speed,
      'fit': watchHistory.fit,
      'episode_index': watchHistory.episodeIndex,
      'season_index': watchHistory.seasonIndex,
      'last_updated': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get watch history by video ID
  Future<WatchHistoryModel?> getWatchHistory(String videoId) async {
    final db = await database;
    final res = await db.query(
      "watch_history",
      where: 'video_id = ?',
      whereArgs: [videoId],
    );
    if (res.isEmpty) return null;

    final data = res.first;
    return WatchHistoryModel(
      id: data['id'] as String,
      videoId: data['video_id'] as String,
      title: data['title'] as String,
      url: data['url'] as String,
      isShow: (data['is_show'] as int) == 1,
      duration: data['duration'] as int,
      current: data['current'] as int,
      scaleX: data['scale_x'] as double,
      scaleY: data['scale_y'] as double,
      speed: data['speed'] as double,
      fit: data['fit'] as String,
      episodeIndex: data['episode_index'] as int?,
      seasonIndex: data['season_index'] as int?,
    );
  }

  /// Get watch history for shows by series ID and season index, ordered by last updated
  Future<List<WatchHistoryModel>> getShowWatchHistory(
    String seriesId,
    int seasonIndex,
  ) async {
    final db = await database;
    final res = await db.query(
      "watch_history",
      where: 'id = ? AND season_index = ? And is_show = 1',
      whereArgs: [seriesId, seasonIndex],
      // orderBy: 'episode_index ASC',
      orderBy: 'last_updated DESC',
      // limit: 1,
    );

    final result = res
        .map(
          (data) => WatchHistoryModel(
            id: data['id'] as String,
            videoId: data['video_id'] as String,
            title: data['title'] as String,
            url: data['url'] as String,
            isShow: (data['is_show'] as int) == 1,
            duration: data['duration'] as int,
            current: data['current'] as int,
            scaleX: data['scale_x'] as double,
            scaleY: data['scale_y'] as double,
            speed: data['speed'] as double,
            fit: data['fit'] as String,
            episodeIndex: data['episode_index'] as int?,
            seasonIndex: data['season_index'] as int?,
          ),
        )
        .toList();
    // return result.firstOrNull;
    return result;
  }

  /// Get all watch history ordered by last updated
  Future<List<WatchHistoryModel>> getAllWatchHistory() async {
    final db = await database;
    final res = await db.query("watch_history", orderBy: 'last_updated DESC');

    return res
        .map(
          (data) => WatchHistoryModel(
            id: data['id'] as String,
            videoId: data['video_id'] as String,
            title: data['title'] as String,
            url: data['url'] as String,
            isShow: (data['is_show'] as int) == 1,
            duration: data['duration'] as int,
            current: data['current'] as int,
            scaleX: data['scale_x'] as double,
            scaleY: data['scale_y'] as double,
            speed: data['speed'] as double,
            fit: data['fit'] as String,
            episodeIndex: data['episode_index'] as int?,
            seasonIndex: data['season_index'] as int?,
          ),
        )
        .toList();
  }

  /// Delete watch history by video ID
  Future<void> deleteWatchHistory(String videoId) async {
    final db = await database;
    await db.delete(
      "watch_history",
      where: 'video_id = ?',
      whereArgs: [videoId],
    );
  }

  /// Update progress for existing watch history
  Future<void> updateWatchProgress({
    required String videoId,
    required int current,
    int? duration,
  }) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'current': current,
      'last_updated': DateTime.now().toIso8601String(),
    };

    if (duration != null) {
      updateData['duration'] = duration;
    }

    await db.update(
      "watch_history",
      updateData,
      where: 'video_id = ?',
      whereArgs: [videoId],
    );
  }
}
