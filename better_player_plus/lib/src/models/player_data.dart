// class PlayerData {
//   final List<List<EpisodeData>> episodes;
//   final int? currentEpisodeIndex;
//   final int currentSeasonIndex;
//   final int seasonsCount;
//   final bool isShow;
//   final int id;
//   final int? movieId;
//   final String title;
//   final String img;

//   PlayerData({
//     required this.episodes,
//     required this.currentEpisodeIndex,
//     required this.isShow,
//     required this.movieId,
//     required this.title,
//     required this.id,
//     required this.img,
//     required this.seasonsCount,
//     required this.currentSeasonIndex,
//   });

//   PlayerData copyWith({required int ei, int? si}) {
//     return PlayerData(
//       episodes: episodes,
//       seasonsCount: seasonsCount,
//       isShow: isShow,
//       movieId: movieId,
//       title: title,
//       id: id,
//       img: img,
//       currentEpisodeIndex: ei,
//       currentSeasonIndex: si ?? currentSeasonIndex,
//     );
//   }

//   bool get hasNext {
//     if (!isShow) return false;
//     return (currentSeasonIndex < episodes.length - 1 ||
//         currentEpisodeIndex! < episodes[currentSeasonIndex].length);
//   }

//   PlayerData nextEpisode() {
//     final currentSeason = episodes[currentSeasonIndex];
//     if (currentEpisodeIndex! < currentSeason.length - 1) {
//       return copyWith(ei: currentEpisodeIndex! + 1);
//     } else {
//       return copyWith(ei: 0, si: currentSeasonIndex + 1);
//     }
//   }

//   EpisodeData? get currentEpisode =>
//       !isShow ? null : episodes[currentSeasonIndex][currentEpisodeIndex!];

//   int get videoId {
//     return !isShow ? movieId! : currentEpisode!.id;
//   }
// }

// class EpisodeData {
//   final int id;
//   final String title;
//   final String url;

//   EpisodeData({required this.id, required this.title, required this.url});
// }
