import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/downloader/download_db.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:shared_code/models/movie_model.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EpisodeWidget extends StatelessWidget {
  const EpisodeWidget({
    super.key,
    required this.episode,
    required this.ott,
    required this.dEpisode,
    required this.downloadEpisode,
    required this.playEpisode,
    rq,
    this.wh,
  });

  final Episode episode;
  final String ott;
  final MiniDownloadItem? dEpisode;
  final WatchHistory? wh;
  final VoidCallback downloadEpisode;
  final VoidCallback playEpisode;

  Widget? buildProgressBar() {
    if (wh == null || wh!.current == 0 || wh!.duration == 0) return null;
    return Positioned(
      bottom: -1,
      left: 0,
      right: 0,
      child: LinearProgressIndicator(
        value: wh!.current / wh!.duration,
        backgroundColor: Colors.grey[800],
        color: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadStatus = dEpisode?.status;

    return GestureDetector(
      onTap: playEpisode,
      child: Container(
        width: double.infinity,
        color: Colors.black38,
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              width: 130,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    child: Image.network(
                      "https://imgcdn.media/${ott}epimg/150/${episode.id}.jpg",
                      fit: BoxFit.cover,
                      height: 75,
                      width: 130,
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Skeleton.ignore(
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromRGBO(0, 0, 0, 0.45),
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: Color.fromRGBO(255, 255, 255, 0.5),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ?buildProgressBar(),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.t,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${episode.ep}  ${episode.time}",
                    style: const TextStyle(fontSize: 15, color: Colors.white54),
                  ),
                ],
              ),
            ),
            if (downloadStatus == "completed")
              Icon(Icons.check_circle, color: Colors.green, size: 24)
            else if (downloadStatus == "downloading" ||
                downloadStatus == "paused")
              SizedBox(
                width: 30,
                height: 30,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      color: downloadStatus == "downloading"
                          ? Colors.white
                          : const Color.fromARGB(255, 91, 91, 91),
                      value:
                          dEpisode!.progress /
                          100, // Assuming you have a variable for progress
                      strokeWidth: 2,
                    ),
                    Center(
                      child: Text(
                        "${dEpisode!.progress}", // Display percentage
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              IconButton(
                onPressed: downloadEpisode,
                icon: Icon(HugeIcons.strokeRoundedDownload05),
              ),
          ],
        ),
      ),
    );
  }
}
