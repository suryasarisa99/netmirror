class WatchList {
  final String id;
  final int ottId; // Added ottId to identify the OTT platform
  final String title;
  final bool isShow;

  // last_updated, optional
  final DateTime? lastUpdated;

  WatchList({
    required this.id,
    required this.title,
    required this.ottId,
    required this.isShow,
    this.lastUpdated,
  });

  factory WatchList.fromJson(Map<String, dynamic> json) {
    return WatchList(
      id: json['id'] as String,
      ottId: json['ott_id'] as int,
      title: json['title'] as String,
      isShow: json['is_show'] == 1 ? true : false,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ott_id': ottId,
      'title': title,
      'is_show': isShow ? 1 : 0,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}
