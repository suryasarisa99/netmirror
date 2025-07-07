// Movie Database Operations
import 'dart:convert';

import 'package:netmirror/db/db.dart';
import 'package:netmirror/db/tables.dart';
import 'package:netmirror/models/movie_model.dart';
import 'package:sqflite/sqflite.dart';

class MovieTable {
  final DB _dbHelper;
  MovieTable(this._dbHelper);

  Future<void> add(String key, int ottId, Movie data) async {
    final db = await _dbHelper.database;
    await db.insert(Tables.movie, {
      'key': key,
      'ott_id': ottId,
      'value': jsonEncode(data.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Movie?> get(String key, int ottId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      "movie",
      where: 'key = ? AND ott_Id = ?',
      whereArgs: [key, ottId],
    );
    if (res.isEmpty) return null;
    return Movie.fromJson(jsonDecode(res.first['value']! as String), key, null);
  }
}
