import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:netmirror/models/netmirror/nm_movie_model.dart';
import 'package:netmirror/models/prime_video/pv_home_model.dart';
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
      version: 4,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE ott_pv_home (key TEXT PRIMARY KEY, value TEXT)',
        );
        await db.execute(
          'CREATE TABLE ott_nf_home (key TEXT PRIMARY KEY, value TEXT)',
        );
        await db
            .execute('CREATE TABLE movie (key TEXT PRIMARY KEY, value TEXT)');
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
    db.insert(
      "ott_pv_home",
      {
        'key': key,
        'value': jsonEncode(data.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addNfHomePage(String key, NfHomeModel data) async {
    final db = await database;
    db.insert(
      "ott_nf_home",
      {
        'key': key,
        'value': jsonEncode(data.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PvHomeModel?> getPvHomePage(String key) async {
    final db = await database;
    final res =
        await db.query("ott_pv_home", where: 'key = ?', whereArgs: [key]);
    if (res.isEmpty) return null;
    return PvHomeModel.fromJson(jsonDecode(res.first['value']! as String));
  }

  Future<NfHomeModel?> getNfHomePage(String key) async {
    final db = await database;
    final res =
        await db.query("ott_nf_home", where: 'key = ?', whereArgs: [key]);
    if (res.isEmpty) return null;
    return NfHomeModel.fromJson(jsonDecode(res.first['value']! as String));
  }

  Future<void> addMovie(String key, NmMovie data) async {
    final db = await database;
    db.insert(
      "movie",
      {
        'key': key,
        'value': jsonEncode(data.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<NmMovie?> getMovie(String key) async {
    final db = await database;
    final res = await db.query("movie", where: 'key = ?', whereArgs: [key]);
    if (res.isEmpty) return null;
    return NmMovie.fromJson(
        jsonDecode(res.first['value']! as String), key, null);
  }
}
