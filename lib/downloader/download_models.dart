import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';

class DownloadType {
  static const movie = "movie";
  static const series = "series";
  static const episode = "episode";
}

class DownloadStatus {
  static const downloading = "downloading";
  static const paused = "paused";
  static const completed = "completed";
  static const failed = "failed";
}

class DownloadColors {
  static const Color downloading = Color.fromARGB(255, 106, 186, 255); // Blue
  static const Color pending = Color(0xFFFFA726); // Orange
  static const Color completed = Color(0xFF66BB6A); // Green
  static const Color failed = Color(0xFFE53935); // Red
  static const Color paused = Color(0xFFBDBDBD); // Grey

  static Color fromStatus(String status) {
    switch (status) {
      case DownloadStatus.downloading:
        return downloading;
      case DownloadStatus.paused:
        return paused;
      case DownloadStatus.completed:
        return completed;
      case DownloadStatus.failed:
        return failed;
      default:
        return pending;
    }
  }
}

class DownloadTables {
  static const String downloads = 'downloads';
  static const String downloadsList = "downloads_list";
  // static const String episodes = 'download_episodes';

  static const tables = [downloads];
  static const views = [downloadsList, "series_stats"];

  static const dummyItems = {
    'status': 'completed',
    'download_path': '_',
    'playlist_path': '_',
    'resolution': '_',
    'total_parts': 0,
    'unique_id': '_',
    'video_prefix': '_',
    'audio_prefix': '_',
    'audio_suffix': '_',
    'audio_ext': '_',
    'current_audio_part': 0,
    'current_video_part': 0,
    'audio_progress': 0,
    'video_progress': 0,
    'last_played_position': 0,
    'runtime': "_",
  };

  static const List<String> createStatements = [
    '''
    CREATE TABLE IF NOT EXISTS $downloads (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    type TEXT NOT NULL,
    thumbnail TEXT,
    runtime TEXT,
    status TEXT DEFAULT 'downloading',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    download_path TEXT NOT NULL,
    playlist_path TEXT NOT NULL,
    resolution TEXT NOT NULL,
    total_parts INTEGER NOT NULL,
    unique_id TEXT NOT NULL,
    video_prefix TEXT NOT NULL,
    audio_prefix TEXT NOT NULL,
    audio_suffix TEXT NOT NULL,
    audio_ext TEXT NOT NULL,
    current_audio_part INTEGER DEFAULT 0,
    current_video_part INTEGER DEFAULT 0,
    audio_progress INTEGER DEFAULT 0,
    video_progress INTEGER DEFAULT 0,
    last_played_position INTEGER DEFAULT 0,
    audio_langs TEXT DEFAULT '[]',

    -- Episode Specific --
    -- episode_number INTEGER,
    -- season_number INTEGER,
    -- series_id TEXT,

    -- with CHECK constraints
    episode_number INTEGER CHECK ((type = 'episode' AND episode_number IS NOT NULL) OR 
                                (type != 'episode' AND episode_number IS NULL)),
    season_number INTEGER CHECK ((type = 'episode' AND season_number IS NOT NULL) OR 
                               (type != 'episode' AND season_number IS NULL)),
    series_id TEXT CHECK ((type = 'episode' AND series_id IS NOT NULL) OR 
                         (type = 'series' AND id = series_id) OR
                         (type = 'movie' AND series_id IS NULL)),

    FOREIGN KEY (series_id) REFERENCES $downloads (id)
    )
    ''',
    //* Indexes
    '''
    CREATE INDEX idx_downloads_type_status ON $downloads(type, status);

    CREATE INDEX idx_downloads_series_episodes ON $downloads(series_id, season_number, episode_number) 
    WHERE type = 'episode';

    CREATE INDEX idx_downloads_created ON $downloads(created_at DESC);

    -- CREATE INDEX idx_downloads_status_progress ON $downloads(status, progress) 
    -- WHERE status = 'downloading';
    ''',
    //* Views
    '''
      CREATE VIEW IF NOT EXISTS series_stats AS
    SELECT 
        d.series_id,
        COUNT(*) as total_episodes,
        SUM(CASE WHEN d.status = 'completed' THEN 1 ELSE 0 END) as completed_episodes,
        -- AVG(d.video_progress) as avg_progress,
        MIN(d.created_at) as first_episode_date,
        MAX(d.created_at) as last_episode_date
    FROM downloads d
    WHERE d.type = 'episode'
    GROUP BY d.series_id;
    ''',
    '''
    CREATE VIEW IF NOT EXISTS $downloadsList AS
    SELECT 
      d.id,
      d.title,
      d.type,
      d.thumbnail,
      d.created_at,
      d.updated_at,
      d.download_path,
      d.playlist_path,
      d.resolution,
      d.total_parts,
      d.unique_id,
      d.video_prefix,
      d.audio_prefix,
      d.audio_suffix,
      d.audio_ext,
      d.current_audio_part,
      d.current_video_part,
      d.audio_progress,
      d.video_progress,
      d.last_played_position,
      d.audio_langs,
      d.status,
      d.runtime,
      COALESCE(s.completed_episodes, null) as completed_episodes,
      COALESCE(s.total_episodes, null) as total_episodes
    FROM $downloads d
    LEFT JOIN series_stats s ON d.id = s.series_id
    WHERE d.type != 'episode'
    ORDER BY d.created_at DESC;
  ''',
  ];
}

class DownloadProgress {
  final String id;

  final String? seriesId;
  final int? currentPart;
  final int? totalParts;
  final int? progress;
  final bool? isAudio;
  final String? status;
  final List<DownloadAudioLangs>? audioLangs;
  final bool newItem;
  final int? totalEpisodesPlus;
  final int? downloadedEpisodesPlus;
  final bool maybeNewSeries;

  DownloadProgress({
    required this.id,
    this.seriesId,
    this.currentPart,
    this.totalParts,
    this.status,
    this.progress,
    this.audioLangs,
    this.totalEpisodesPlus,
    this.downloadedEpisodesPlus,
    this.isAudio = false,
    this.newItem = false,
    this.maybeNewSeries = false,
  });

  factory DownloadProgress.status(String id, String status) {
    return DownloadProgress(id: id, status: status);
  }

  factory DownloadProgress.audioLangs(
    String id,
    List<DownloadAudioLangs> langs,
  ) {
    return DownloadProgress(id: id, isAudio: true, audioLangs: langs);
  }
}

final Map<String, bool> pauseFlags = {};

class MiniDownloadItem {
  String id;
  int progress;
  String status;
  List<DownloadAudioLangs> audioLangs;

  MiniDownloadItem({
    required this.id,
    required this.progress,
    required this.status,
    required this.audioLangs,
  });

  factory MiniDownloadItem.fromMap(Map<String, dynamic> map) {
    log('MiniDownloadItem.fromMap: $map');
    return MiniDownloadItem(
      id: map['id'] as String,
      progress: map['video_progress'] as int,
      status: map['status'] as String,
      audioLangs: (jsonDecode(map['audio_langs']) as List)
          .map((e) => DownloadAudioLangs.fromJson(e))
          .toList(),
    );
  }
}

class DownloadAudioLangs {
  final String audioSuffix;
  // final int unique_id;
  bool status;
  final int audioIndex;

  DownloadAudioLangs({
    required this.audioSuffix,
    required this.audioIndex,
    // required this.unique_id,
    required this.status,
  });

  factory DownloadAudioLangs.fromJson(Map<String, dynamic> map) {
    return DownloadAudioLangs(
      audioSuffix: map['audio_suffix'] as String,
      // unique_id: map['unique_id'] as int,
      status: map['status'] as bool,
      audioIndex: map['audio_index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_suffix': audioSuffix,
      // 'unique_id': unique_id,
      'status': status,
      'audio_index': audioIndex,
    };
  }
}

class DownloadItem {
  String id; // video ID
  String title;
  String type;
  String thumbnail;
  // int totalSize;
  // int downloadedSize;
  String status;
  int createdAt;
  int updatedAt;
  String downloadPath;
  String playlistPath;
  String resolution;
  int totalParts;
  String uniqueId;
  String videoPrefix;
  String audioPrefix;
  String audioSuffix;
  String audioExt;
  int audioProgress;
  int videoProgress;
  int currentAudioPart;
  int currentVideoPart;
  int lastPlayedPosition;
  String? runtime;
  List<DownloadAudioLangs> audioLangs;

  String? seriesId;
  int? episodeNumber;
  int? seasonNumber;

  // view specific
  int? completedEpisodes;
  int? totalEpisodes;

  DownloadItem({
    required this.id,
    required this.title,
    required this.type,
    required this.thumbnail,
    // required this.totalSize,
    // required this.downloadedSize,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.downloadPath,
    required this.playlistPath,
    required this.resolution,
    required this.totalParts,
    required this.uniqueId,
    required this.videoPrefix,
    required this.audioPrefix,
    required this.audioSuffix,
    required this.audioExt,
    required this.currentAudioPart,
    required this.currentVideoPart,
    required this.lastPlayedPosition,
    required this.audioProgress,
    required this.videoProgress,
    required this.audioLangs,
    required this.runtime,

    // Episode Specific
    required this.seriesId,
    required this.episodeNumber,
    required this.seasonNumber,

    // view specific
    required this.completedEpisodes,
    required this.totalEpisodes,
  });

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      thumbnail: map['thumbnail'] as String,
      // totalSize: map['total_size'] as int,
      // downloadedSize: map['downloaded_size'] as int,
      status: map['status'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      downloadPath: map['download_path'] as String,
      playlistPath: map['playlist_path'] as String,
      resolution: map['resolution'] as String,
      totalParts: map['total_parts'] as int,
      uniqueId: map['unique_id'] as String,
      videoPrefix: map['video_prefix'] as String,
      audioPrefix: map['audio_prefix'] as String,
      audioSuffix: map['audio_suffix'] as String,
      audioExt: map['audio_ext'] as String,
      audioProgress: map['audio_progress'] as int,
      videoProgress: map['video_progress'] as int,
      currentAudioPart: map['current_audio_part'] as int,
      currentVideoPart: map['current_video_part'] as int,
      lastPlayedPosition: map['last_played_position'] as int,
      runtime: map['runtime'] as String?,
      audioLangs: (jsonDecode(map['audio_langs']) as List)
          .map((e) => DownloadAudioLangs.fromJson(e))
          .toList(),

      //episode specific
      seriesId: map['series_id'] as String?,
      episodeNumber: map['episode_number'] as int?,
      seasonNumber: map['season_number'] as int?,

      // view specific
      completedEpisodes: map['completed_episodes'] as int?,
      totalEpisodes: map['total_episodes'] as int?,
    );
  }

  DownloadItem update(DownloadProgress progress) {
    if (progress.isAudio! && progress.progress != null) {
      currentAudioPart = progress.currentPart!;
      audioProgress = progress.progress!;
    } else if (progress.progress != null) {
      currentVideoPart = progress.currentPart!;
      videoProgress = progress.progress!;
    }
    if (progress.status != null) status = progress.status!;
    if (progress.audioLangs != null) audioLangs = progress.audioLangs!;
    if (progress.totalEpisodesPlus != null) {
      totalEpisodes = (totalEpisodes ?? 0) + progress.totalEpisodesPlus!;
    }
    if (progress.downloadedEpisodesPlus != null) {
      completedEpisodes =
          (completedEpisodes ?? 0) + progress.downloadedEpisodesPlus!;
    }
    return this;
  }
}
