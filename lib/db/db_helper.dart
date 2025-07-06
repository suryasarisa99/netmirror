import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:netmirror/db/db_tables.dart';
import 'package:netmirror/models/movie_model.dart';
import 'package:netmirror/models/prime_video/pv_home_model.dart';
import 'package:netmirror/models/watch_list_model.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:shared_code/models/ott.dart';
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
      version: 8,
      onCreate: (db, version) async {
        // Iterate over all queries using named record destructuring
        for (final query in Tables.queriesList) {
          await db.execute(query);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await db.execute(Tables.queries.watchHistory);
        }
        if (oldVersion < 6) {
          await db.execute(Tables.queries.watchList);
        }
        if (oldVersion < 8) {
          log("dropping tables and recreating");
          for (final table in Tables.tableNames) {
            await db.execute('DROP TABLE IF EXISTS $table');
          }
          for (final query in Tables.queriesList) {
            await db.execute(query);
          }
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
    db.insert(Tables.ottPvHome, {
      'key': key,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addNfHomePage(String key, NfHomeModel data) async {
    final db = await database;
    db.insert(Tables.ottNfHome, {
      'key': key,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PvHomeModel?> getPvHomePage(String key) async {
    final db = await database;
    final res = await db.query(
      Tables.ottPvHome,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (res.isEmpty) return null;
    return PvHomeModel.fromJson(jsonDecode(res.first['value']! as String));
  }

  Future<NfHomeModel?> getNfHomePage(String key) async {
    final db = await database;
    final res = await db.query(
      Tables.ottNfHome,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (res.isEmpty) return null;
    return NfHomeModel.fromJson(jsonDecode(res.first['value']! as String));
  }

  Future<void> addMovie(String key, int ottId, Movie data) async {
    final db = await database;
    db.insert(Tables.movie, {
      'key': key,
      'ott_id': ottId,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Movie?> getMovie(String key, int ottId) async {
    final db = await database;
    final res = await db.query(
      "movie",
      where: 'key = ? AND ott_Id = ?',
      whereArgs: [key, ottId],
    );
    if (res.isEmpty) return null;
    return Movie.fromJson(jsonDecode(res.first['value']! as String), key, null);
  }

  // Watch History Methods

  /// Save or update watch history for a video
  Future<void> saveWatchHistory(WatchHistory watchHistory) async {
    final db = await database;
    await db.insert(Tables.watchHistory, {
      'id': watchHistory.id,
      'video_id': watchHistory.videoId.toString(),
      'ott_id': watchHistory.ottId,
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
  Future<WatchHistory?> getWatchHistory({
    required String videoId,
    required int ottId,
    required String id,
  }) async {
    final db = await database;
    final res = await db.query(
      Tables.watchHistory,
      where: 'video_id = ? AND id = ? AND ott_id = ?',
      whereArgs: [videoId, id, ottId],
    );
    if (res.isEmpty) return null;

    final data = res.first;
    return WatchHistory(
      id: data['id'] as String,
      ottId: data['ott_id'] as int,
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
  Future<List<WatchHistory>> getShowWatchHistory({
    required String seriesId,
    required int ottId,
    required int seasonIndex,
  }) async {
    final db = await database;
    final res = await db.query(
      Tables.watchHistory,
      where: 'id = ? AND ott_id = ?  AND season_index = ? And is_show = 1',
      whereArgs: [seriesId, ottId, seasonIndex],
      // orderBy: 'episode_index ASC',
      orderBy: 'last_updated DESC',
      // limit: 1,
    );

    final result = res
        .map(
          (data) => WatchHistory(
            id: data['id'] as String,
            ottId: data['ott_id'] as int,
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
  Future<List<WatchHistory>> getAllWatchHistory() async {
    final db = await database;
    final res = await db.query(
      Tables.watchHistory,
      orderBy: 'last_updated DESC',
    );

    return res
        .map(
          (data) => WatchHistory(
            id: data['id'] as String,
            ottId: data['ott_id'] as int,
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
  Future<void> deleteWatchHistory({
    required String videoId,
    required String id,
    required String ottId,
  }) async {
    final db = await database;
    await db.delete(
      Tables.watchHistory,
      where: 'video_id = ? AND id = ? AND ott_id = ?',
      whereArgs: [videoId, id, ottId],
    );
  }

  /// Update progress for existing watch history
  Future<void> updateWatchProgress({
    required String videoId,
    required int ottId,
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
      Tables.watchHistory,
      updateData,
      where: 'video_id = ? AND ott_id = ?',
      whereArgs: [videoId, ottId],
    );
  }

  // <===================== Watch List Methods ===============>

  Future<void> addToWatchList(WatchList item) async {
    final db = await database;
    await db.insert(
      Tables.watchList,
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isInWatchList(String id, int ottId) async {
    final db = await database;
    final res = await db.query(
      Tables.watchList,
      where: 'id = ? AND ott_id = ?',
      whereArgs: [id, ottId],
    );
    return res.isNotEmpty;
  }

  Future<List<WatchList>> getWatchList() async {
    final db = await database;
    final res = await db.query(Tables.watchList);
    return res.map((data) => WatchList.fromJson(data)).toList();
  }

  Future<void> removeFromWatchList(String id, int ottId) async {
    final db = await database;
    await db.delete(
      Tables.watchList,
      where: 'id = ? AND ott_id = ?',
      whereArgs: [id, ottId],
    );
  }
}
