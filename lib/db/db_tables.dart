class Tables {
  static const String movie = "movie";
  static const String ottPvHome = "ott_pv_home";
  static const String ottNfHome = "ott_nf_home";
  static const String watchHistory = "watch_history";
  static const String watchList = "watch_list";

  static const queries = (
    movie: '''CREATE TABLE $movie (
            key TEXT NOT NULL,
            ott_id INTEGER NOT NULL,
            value TEXT,
            PRIMARY KEY (key, ott_id)
          )''',
    ottPvHome: 'CREATE TABLE $ottPvHome (key TEXT PRIMARY KEY, value TEXT)',
    ottNfHome: 'CREATE TABLE $ottNfHome (key TEXT PRIMARY KEY, value TEXT)',
    watchHistory: '''CREATE TABLE $watchHistory (
            video_id TEXT,
            id TEXT NOT NULL,
            ott_id INTEGER NOT NULL,
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
            last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (video_id, ott_id)
          )''',
    watchList: '''CREATE TABLE $watchList (
            id TEXT NOT NULL,
            ott_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            is_show INTEGER NOT NULL,
            last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id, ott_id)
          )''',
  );

  static List<String> queriesList = [
    queries.movie,
    queries.ottPvHome,
    queries.ottNfHome,
    queries.watchHistory,
    queries.watchList,
  ];

  static const List<String> tableNames = [
    movie,
    ottPvHome,
    ottNfHome,
    watchHistory,
    watchList,
  ];
}
