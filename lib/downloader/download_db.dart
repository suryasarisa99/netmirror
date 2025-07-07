import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:netmirror/downloader/download_models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
export 'package:netmirror/downloader/download_models.dart';

class DownloadDb {
  static final DownloadDb instance = DownloadDb._internal();
  DownloadDb._internal();

  // properties
  static const DOWNLOAD_TASK = "downloadTask";
  static Database? _db;

  //* getters
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  //* Database Initialization

  Future<Database> _initDatabase() async {
    log("<=====================    _initDatabase    =====================>");

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'downloads.db');

    // Create database with same configuration
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        log("inside onUpgrade");
        if (oldVersion < newVersion) {
          log("need to delete tables");
          await deleteTables(db);
          for (final statement in DownloadTables.createStatements) {
            await db.execute(statement);
          }
        }
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        log("inside onDowngrade");
        if (oldVersion > newVersion) {
          log("need to delete tables");
          await deleteTables(db);
          await _onCreate(db, newVersion);
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final statement in DownloadTables.createStatements) {
      await db.execute(statement);
    }
  }

  Future<void> deleteTables(Database db) async {
    // final db = await database;
    log("database getter is done");
    for (final table in DownloadTables.tables) {
      await db.execute("DROP TABLE IF EXISTS $table");
    }
    for (final view in DownloadTables.views) {
      await db.execute("DROP VIEW IF EXISTS $view");
    }
    log("Tables deleted");
  }

  //* Database Queries
  Future<List<DownloadItem>> getAllDownloads() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT * FROM ${DownloadTables.downloadsList}",
    );
    return result.map((e) => DownloadItem.fromMap(e)).toList();
  }

  // Get episodes for a specific series
  Future<List<DownloadItem>> getSeriesEpisodes(String seriesId) async {
    final db = await database;
    log("only episodes");
    const query =
        '''
      SELECT * 
      FROM ${DownloadTables.downloads}
      WHERE series_id = ? AND type = '${DownloadType.episode}'
      ORDER BY season_number, episode_number
    ''';

    final result = await db.rawQuery(query, [seriesId]);
    return result.map((e) => DownloadItem.fromMap(e)).toList();
  }

  Future<List<MiniDownloadItem>> getMovieOrSeries(String id) async {
    final db = _db!;
    const query = """
    WITH selected_download AS ( SELECT * FROM downloads WHERE id = :id )
    SELECT 
        d.*
    FROM downloads d
    JOIN selected_download sd ON (
        (sd.type = 'movie' AND d.id = sd.id) OR
        (sd.type = 'series' AND d.series_id = sd.id)
    )
    ORDER BY d.type DESC, d.season_number, d.episode_number;""";
    final result = await db.rawQuery(query, [id]);
    return (result as List).map((e) => MiniDownloadItem.fromMap(e)).toList();
  }

  Future<DownloadItem> getDownloadItem(String id) async {
    final db = await database;
    final result = await db.query(
      DownloadTables.downloads,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) {
      throw Exception("Download item not found");
    }

    final item = result.first;
    final type = item['type'];

    if (type == 'series') {
      log("It is Series, Not (Movie or Episode)");
      throw Exception("NOt a Movie or Episode. ! It is Series");
    }

    return DownloadItem.fromMap(item);
  }

  //* Database Insertions
  // Insert a movie download
  Future<void> insertItem(Map<String, dynamic> movie) async {
    final db = await database;
    await db.insert(DownloadTables.downloads, movie);
  }

  Future<void> insertEpisodeDownload(Map<String, dynamic> episode) async {
    final db = await database;
    await db.insert(DownloadTables.downloads, episode);
  }

  Future<void> insertSeries(Map<String, dynamic> series) async {
    final db = await database;
    await db.insert(DownloadTables.downloads, {
      ...series,
      ...DownloadTables.dummyItems,
    });
  }

  Future<String> getDownloadStatus(String videoId) {
    return _db!
        .query(DownloadTables.downloads, where: 'id = ?', whereArgs: [videoId])
        .then((value) => value.first['status'] as String);
  }

  Future<void> insertSeriesWithEpisodes(
    Map<String, dynamic> series,
    List<Map<String, dynamic>> episodes,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert series
      series['type'] = 'series';
      await txn.insert(DownloadTables.downloads, {
        ...series,
        ...DownloadTables.dummyItems,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert episodes
      for (var episode in episodes) {
        episode['series_id'] = series['id'];
        await txn.insert(DownloadTables.downloads, episode);
      }
    });
  }

  //* Database Updates

  // Update progress
  Future<void> updateProgress(
    String id,
    int currentPart,
    int progress, {
    required isAudio,
  }) async {
    final db = await database;
    final prefix = isAudio ? "audio" : "video";
    await db.update(
      DownloadTables.downloads,
      {
        'current_${prefix}_part': currentPart,
        '${prefix}_progress': progress,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateStatus(String id, String type, String status) async {
    final db = await database;
    await db.update(
      DownloadTables.downloads,
      {'status': status, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateAudioLangs(
    String downloadId,
    List<DownloadAudioLangs> audioLangs,
  ) async {
    final db = await database;
    final audioLangsList = audioLangs.map((e) => e.toJson()).toList();

    await db.update(
      DownloadTables.downloads,
      {
        'audio_langs': jsonEncode(audioLangsList),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [downloadId],
    );
  }

  //* Db deletion
  static Future<void> deleteDownload(String videoId) async {
    final db = await instance.database;
  }
}
