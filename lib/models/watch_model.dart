class WatchItemModel {
  final String title;
  final String url;
  final int id;
  final bool isShow;

  WatchItemModel({
    required this.title,
    required this.url,
    required this.id,
    required this.isShow,
  });

  factory WatchItemModel.fromJson(Map<String, dynamic> json) {
    return WatchItemModel(
      id: json['id'],
      title: json['title'],
      url: json['url'],
      isShow: json['is_show'] == 1 ? true : false,
    );
  }
}

class WatchHistoryModel {
  final String id;
  final String videoId;
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

  WatchHistoryModel({
    required this.id,
    required this.videoId,
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

  factory WatchHistoryModel.fromJson(Map<String, dynamic> json) {
    return WatchHistoryModel(
      id: json['id'],
      videoId: json['video_id'],
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

      // id,
      // video_id,
      // episode_index,
      // season_index,
      // title,
      // url,
      // is_show,
      // scale_x,
      // scale_y,
      // duration,
      // current,
      // fit,
      // speed
