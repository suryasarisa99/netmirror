class Tables {
  static const String movie = "movie";
  static const String home = "home";
  static const String watchHistory = "watch_history";
  static const String watchList = "watch_list";

  static const queries = (
    movie: '''CREATE TABLE $movie (
            key TEXT NOT NULL,
            ott_id INTEGER NOT NULL,
            value TEXT,
            PRIMARY KEY (key, ott_id)
          )''',
    home: '''CREATE TABLE $home (
            key TEXT NOT NULL,
            ott_id INTEGER NOT NULL,
            value TEXT,
            PRIMARY KEY (key, ott_id)
          )''',
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
            episode_number INTEGER,
            season_number INTEGER,
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
    queries.watchHistory,
    queries.watchList,
    queries.home,
  ];

  static const List<String> tableNames = [movie, watchHistory, watchList, home];

  Tables._();
}
