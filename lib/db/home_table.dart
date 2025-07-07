// Home Database Operations
import 'dart:convert';

import 'package:netmirror/db/db.dart';
import 'package:netmirror/db/tables.dart';
import 'package:netmirror/models/home_models.dart';
import 'package:sqflite/sqflite.dart';

class HomeTable {
  final DB _dbHelper;
  HomeTable(this._dbHelper);

  Future<void> addPvHome(String key, PvHomeModel data) async {
    final db = await _dbHelper.database;
    await db.insert(Tables.ottPvHome, {
      'key': key,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addNfHome(String key, NfHomeModel data) async {
    final db = await _dbHelper.database;
    await db.insert(Tables.ottNfHome, {
      'key': key,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PvHomeModel?> getPvHome(String key) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      Tables.ottPvHome,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (res.isEmpty) return null;
    return PvHomeModel.fromJson(jsonDecode(res.first['value']! as String));
  }

  Future<NfHomeModel?> getNfHome(String key) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      Tables.ottNfHome,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (res.isEmpty) return null;
    return NfHomeModel.fromJson(jsonDecode(res.first['value']! as String));
  }
}
