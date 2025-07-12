import 'dart:convert';

import 'package:netmirror/db/db.dart';
import 'package:netmirror/db/tables.dart';
import 'package:netmirror/models/home_models.dart';
import 'package:shared_code/models/ott.dart';
import 'package:sqflite/sqflite.dart';

class HomeTable {
  final DB _dbHelper;
  final String table = Tables.home;
  HomeTable(this._dbHelper);

  Future<void> add(String key, HomeModel data, OTT ott) async {
    final db = await _dbHelper.database;
    await db.insert(table, {
      'key': key,
      'ott_id': ott.id,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<HomeModel?> get(String key, OTT ott) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      table,
      where: 'key = ? AND ott_id = ?',
      whereArgs: [key, ott.id],
    );
    if (result.isEmpty) return null;
    final jsonData = jsonDecode(result.first['value']! as String);
    return HomeModel.fromJson(jsonData, ott);
  }

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
