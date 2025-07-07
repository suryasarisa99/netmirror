
/// this function only keeps the first audio track found in audioLangs and removes the rest, if not found return all audio tracks.
/// also for video resolution.
String fastPlaylist(
  String playlist,
  List<String> audioLangs, [
  String? resolution,
]) {
  if (playlist.isEmpty) return playlist;

  final lines = playlist.split('\n');
  final filteredLines = <String>[];

  // Keep header and version info
  for (final line in lines) {
    if (line.startsWith('#EXTM3U') || line.startsWith('#EXT-X-VERSION')) {
      filteredLines.add(line);
    } else {
      break;
    }
  }

  // Parse audio tracks
  final audioTracks = <String>[];
  String? selectedAudioTrack;

  // Parse video streams
  final videoStreams = <String>[];
  final videoStreamUrls = <String>[];
  String? selectedVideoStream;
  String? selectedVideoStreamUrl;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    // Handle audio tracks
    if (line.startsWith('#EXT-X-MEDIA:TYPE=AUDIO')) {
      audioTracks.add(line);
    }
    // Handle video streams
    else if (line.startsWith('#EXT-X-STREAM-INF')) {
      final streamInfo = line;
      final streamUrl = i + 1 < lines.length ? lines[i + 1].trim() : '';

      if (streamUrl.isNotEmpty && !streamUrl.startsWith('#')) {
        videoStreams.add(streamInfo);
        videoStreamUrls.add(streamUrl);

        // Check if this video stream matches the desired resolution
        if (resolution != null &&
            selectedVideoStream == null &&
            streamInfo.contains(resolution)) {
          selectedVideoStream = streamInfo;
          selectedVideoStreamUrl = streamUrl;
        }

        // Skip the URL line in the next iteration
        i++;
      }
    }
  }

  // Find the first preferred audio language that exists in the playlist
  // This respects the order of audioLangs array
  for (final preferredLang in audioLangs) {
    for (final audioTrack in audioTracks) {
      if (audioTrack.contains('LANGUAGE="$preferredLang"')) {
        selectedAudioTrack = audioTrack;
        break;
      }
    }
    if (selectedAudioTrack != null) break;
  }

  // If no matching audio track found, keep the first one or all if none specified
  if (selectedAudioTrack == null && audioTracks.isNotEmpty) {
    selectedAudioTrack = audioTracks.first;
  }

  // If no matching video resolution found, find the best alternative
  if (resolution != null &&
      selectedVideoStream == null &&
      videoStreams.isNotEmpty) {
    // Try to find default or fallback to first available
    for (int i = 0; i < videoStreams.length; i++) {
      final streamInfo = videoStreams[i];
      if (streamInfo.contains('DEFAULT=YES') || selectedVideoStream == null) {
        selectedVideoStream = streamInfo;
        selectedVideoStreamUrl = videoStreamUrls[i];
        if (streamInfo.contains('DEFAULT=YES')) break;
      }
    }
  }

  // Add the selected audio track
  if (selectedAudioTrack != null) {
    filteredLines.add(selectedAudioTrack);
  }

  // Add video streams based on resolution filtering
  if (resolution == null || selectedVideoStream == null) {
    // If resolution is null or no match found, add all video streams
    for (int i = 0; i < videoStreams.length; i++) {
      filteredLines.add(videoStreams[i]);
      filteredLines.add(videoStreamUrls[i]);
    }
  } else {
    // Add only the selected video stream
    filteredLines.add(selectedVideoStream);
    filteredLines.add(selectedVideoStreamUrl!);
  }

  // If no tracks were selected, return original playlist
  if (filteredLines.length <= 2) {
    return playlist;
  }

  return filteredLines.join('\n');
}

// void main() {
//   List<String> playlists = [
//     '''
// #EXTM3U
//       #EXT-X-VERSION:3
//       #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",LANGUAGE="hin",NAME="[1] Hindi",DEFAULT=NO,URI="https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/a/0/0.m3u8"
//       #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",LANGUAGE="kan",NAME="[2] Kannada",DEFAULT=NO,URI="https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/a/1/1.m3u8"
//       #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",LANGUAGE="mal",NAME="[3] Malayalam",DEFAULT=NO,URI="https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/a/2/2.m3u8"
//       #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",LANGUAGE="tam",NAME="[4] Tamil",DEFAULT=NO,URI="https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/a/3/3.m3u8"
//       #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",LANGUAGE="tel",NAME="[5] Telugu",DEFAULT=NO,URI="https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/a/4/4.m3u8"
//       #EXT-X-STREAM-INF:BANDWIDTH=1000000,AUDIO="aac",RESOLUTION=1920x1080,CLOSED-CAPTIONS=NONE
//       https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/1080p/1080p.m3u8?in=ssssssssssssssssssssss::b8579d20a4e0e60ace946c49ae30aabc::1751708021::ni
//       #EXT-X-STREAM-INF:BANDWIDTH=600000,AUDIO="aac",DEFAULT=YES,RESOLUTION=1280x720,CLOSED-CAPTIONS=NONE
//       https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/720p/720p.m3u8?in=ssssssssssssssssssssss::b8579d20a4e0e60ace946c49ae30aabc::1751708021::ni
//       #EXT-X-STREAM-INF:BANDWIDTH=400000,AUDIO="aac",RESOLUTION=854x480,CLOSED-CAPTIONS=NONE
//       https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/480p/480p.m3u8?in=ssssssssssssssssssssss::b8579d20a4e0e60ace946c49ae30aabc::1751708021::ni
// ''',
//     '''
// #EXTM3U
//       #EXT-X-VERSION:3
//       #EXT-X-STREAM-INF:BANDWIDTH=1000000,AUDIO="aac",RESOLUTION=1920x1080,CLOSED-CAPTIONS=NONE
//       https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/1080p/1080p.m3u8?in=ssssssssssssssssssssss::b8579d20a4e0e60ace946c49ae30aabc::1751708021::ni
//       #EXT-X-STREAM-INF:BANDWIDTH=600000,AUDIO="aac",DEFAULT=YES,RESOLUTION=1280x720,CLOSED-CAPTIONS=NONE
//       https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/720p/720p.m3u8?in=ssssssssssssssssssssss::b8579d20a4e0e60ace946c49ae30aabc::1751708021::ni
//       #EXT-X-STREAM-INF:BANDWIDTH=400000,AUDIO="aac",RESOLUTION=854x480,CLOSED-CAPTIONS=NONE
//       https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/480p/480p.m3u8?in=ssssssssssssssssssssss::b8579d20a4e0e60ace946c49ae30aabc::1751708021::ni
// ''',
//     '''
// #EXTM3U
//       #EXT-X-VERSION:3
//       #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aac",LANGUAGE="meow",NAME="",DEFAULT=NO,URI="https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/a/4/4.m3u8"
//       #EXT-X-STREAM-INF:BANDWIDTH=1000000,AUDIO="aac",RESOLUTION=1920x1080,CLOSED-CAPTIONS=NONE
//       https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/1080p/1080p.m3u8?in=ssssssssssssssssssssss::b8579d20a4e0e60ace946c49ae30aabc::1751708021::ni
//       #EXT-X-STREAM-INF:BANDWIDTH=600000,AUDIO="aac",DEFAULT=YES,RESOLUTION=1280x720,CLOSED-CAPTIONS=NONE
//       https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/720p/720p.m3u8?in=ssssssssssssssssssssss::b8579d20a4e0e60ace946c49ae30aabc::1751708021::ni
//       #EXT-X-STREAM-INF:BANDWIDTH=400000,AUDIO="aac",RESOLUTION=854x480,CLOSED-CAPTIONS=NONE
//       https://s14.nm-cdn7.top/files/0STFO0E97XRJ8WFI3RZLCPGSHZ/480p/480p.m3u8?in=ssssssssssssssssssssss::b8579d20a4e0e60ace946c49ae30aabc::1751708021::ni
// ''',
//   ];

//   List<String> audioLangs = ['tel', 'hin', 'kan', 'mal', 'tam'];
//   // String resolution = ';

//   String result = fastPlaylist(playlists[2], audioLangs, null);
//   print(result);
// }
