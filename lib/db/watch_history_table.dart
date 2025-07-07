// WatchHistory Database Operations
import 'package:netmirror/db/db.dart';
import 'package:netmirror/db/tables.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:sqflite/sqflite.dart';

class WatchHistoryTable {
  final DB _dbHelper;
  static final table = Tables.watchHistory;
  WatchHistoryTable(this._dbHelper);

  Future<void> save(WatchHistory watchHistory) async {
    final db = await _dbHelper.database;
    await db.insert(
      table,
      watchHistory.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<WatchHistory?> get({
    required String videoId,
    required int ottId,
    required String id,
  }) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      table,
      where: 'video_id = ? AND id = ? AND ott_id = ?',
      whereArgs: [videoId, id, ottId],
    );
    if (res.isEmpty) return null;
    return WatchHistory.fromJson(res.first);
  }

  Future<List<WatchHistory>> getShowHistory({
    required String seriesId,
    required int ottId,
    required int seasonIndex,
  }) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      table,
      where: 'id = ? AND ott_id = ?  AND season_index = ? And is_show = 1',
      whereArgs: [seriesId, ottId, seasonIndex],
      orderBy: 'last_updated DESC',
    );

    return res.map((data) => WatchHistory.fromJson(data)).toList();
  }

  Future<List<WatchHistory>> getAll() async {
    final db = await _dbHelper.database;
    final res = await db.query(table, orderBy: 'last_updated DESC');
    return res.map((data) => WatchHistory.fromJson(data)).toList();
  }

  Future<void> delete(String videoId) async {
    final db = await _dbHelper.database;
    await db.delete(table, where: 'video_id = ?', whereArgs: [videoId]);
  }

  Future<void> updateProgress({
    required String videoId,
    required int ottId,
    required int current,
    int? duration,
  }) async {
    final db = await _dbHelper.database;
    final updateData = <String, dynamic>{
      'current': current,
      'last_updated': DateTime.now().toIso8601String(),
    };

    if (duration != null) {
      updateData['duration'] = duration;
    }

    await db.update(
      table,
      updateData,
      where: 'video_id = ? AND ott_id = ?',
      whereArgs: [videoId, ottId],
    );
  }
}
