class WatchHistory {
  final String id;
  final String videoId;
  final int ottId;
  final bool isShow;
  final String title;
  final String url;
  final int duration;
  final int current;
  final double scaleX;
  final double scaleY;
  final double speed;
  final String fit;
  final int? episodeNumber;
  final int? seasonNumber;

  final DateTime? lastUpdated;

  WatchHistory({
    required this.id,
    required this.videoId,
    required this.ottId,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.title,
    required this.url,
    required this.isShow,
    required this.duration,
    required this.current,
    required this.scaleX,
    required this.scaleY,
    required this.fit,
    required this.speed,
    this.lastUpdated,
  });

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      id: json['id'],
      videoId: json['video_id'],
      ottId: json['ott_id'] as int,
      episodeNumber: json['episode_number'],
      seasonNumber: json['season_number'],
      title: json['title'],
      url: json['url'],
      isShow: json['is_show'] == 1 ? true : false,
      scaleX: json['scale_x'],
      scaleY: json['scale_y'],
      duration: json['duration'],
      current: json['current'],
      fit: json['fit'],
      speed: json['speed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_id': videoId,
      'ott_id': ottId,
      'episode_number': episodeNumber,
      'season_number': seasonNumber,
      'title': title,
      'url': url,
      'is_show': isShow ? 1 : 0,
      'scale_x': scaleX,
      'scale_y': scaleY,
      'duration': duration,
      'current': current,
      'fit': fit,
      'speed': speed,
      'last_updated':
          lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
