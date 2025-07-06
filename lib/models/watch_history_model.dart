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
  final int? episodeIndex;
  final int? seasonIndex;

  WatchHistory({
    required this.id,
    required this.videoId,
    required this.ottId,
    required this.episodeIndex,
    required this.seasonIndex,
    required this.title,
    required this.url,
    required this.isShow,
    required this.duration,
    required this.current,
    required this.scaleX,
    required this.scaleY,
    required this.fit,
    required this.speed,
  });

  factory WatchHistory.fromJson(Map<String, dynamic> json) {
    return WatchHistory(
      id: json['id'],
      videoId: json['video_id'],
      ottId: json['ott_id'] as int,
      episodeIndex: json['episode_index'],
      seasonIndex: json['season_index'],
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
}
