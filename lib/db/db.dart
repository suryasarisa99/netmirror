import 'package:netmirror/db/tables.dart';
import 'package:netmirror/db/home_table.dart';
import 'package:netmirror/db/movie_table.dart';
import 'package:netmirror/db/watch_history_table.dart';
import 'package:netmirror/db/watch_list_table.dart';
import 'package:netmirror/log.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

const l = L("db");

class DB {
  static final DB instance = DB._internal();

  static Database? _db;

  // Organized access points
  static late final WatchListTable watchList;
  static late final WatchHistoryTable watchHistory;
  static late final MovieTable movie;
  static late final HomeTable home;

  DB._internal() {
    // Initialize the organized database classes
    watchList = WatchListTable(this);
    watchHistory = WatchHistoryTable(this);
    movie = MovieTable(this);
    home = HomeTable(this);
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    String path = p.join(await getDatabasesPath(), 'netmirror.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        for (final query in Tables.queriesList) {
          await db.execute(query);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < newVersion) {
          l.debug("onUpgrade: dropping all tables and recreating them");
          for (final table in Tables.tableNames) {
            await db.execute('DROP TABLE IF EXISTS $table');
          }
          for (final query in Tables.queriesList) {
            await db.execute(query);
          }
        }
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        if (oldVersion > newVersion) {
          l.debug("onDowngrade: dropping all tables and recreating them");
          for (final table in Tables.tableNames) {
            await db.execute('DROP TABLE IF EXISTS $table');
          }
          for (final query in Tables.queriesList) {
            await db.execute(query);
          }
        }
      },
    );
  }

  Future<void> disconnect() async {
    _db?.close();
    _db = null;
  }
}
