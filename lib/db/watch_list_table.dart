// WatchList Database Operations
import 'package:netmirror/db/db.dart';
import 'package:netmirror/db/tables.dart';
import 'package:netmirror/models/watch_list_model.dart';
import 'package:sqflite/sqflite.dart';

class WatchListTable {
  final DB _dbHelper;
  static final table = Tables.watchList;
  WatchListTable(this._dbHelper);

  Future<void> add(WatchList item) async {
    final db = await _dbHelper.database;
    await db.insert(
      table,
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isIn(String id, int ottId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      Tables.watchList,
      where: 'id = ? AND ott_id = ?',
      whereArgs: [id, ottId],
    );
    return res.isNotEmpty;
  }

  Future<List<WatchList>> getAll() async {
    final db = await _dbHelper.database;
    final res = await db.query(Tables.watchList);
    return res.map((data) => WatchList.fromJson(data)).toList();
  }

  Future<void> delete(String id, int ottId) async {
    final db = await _dbHelper.database;
    await db.delete(
      Tables.watchList,
      where: 'id = ? AND ott_id = ?',
      whereArgs: [id, ottId],
    );
  }
}
