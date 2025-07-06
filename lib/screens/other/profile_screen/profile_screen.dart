import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/db/db_helper.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/watch_history_model.dart';
import 'package:netmirror/models/watch_list_model.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

final double _imgHeight = isDesk ? 120 : 170;

class _ProfileScreenState extends State<ProfileScreen> {
  List<WatchList> myList = [];
  List<WatchHistory> watchHistory = [];

  @override
  void initState() {
    super.initState();
    _initial();
  }

  void _initial() async {
    final [x, y] = await Future.wait([
      DBHelper.instance.getWatchList(),
      DBHelper.instance.getAllWatchHistory(),
    ]);

    setState(() {
      myList = x as List<WatchList>;
      watchHistory = y as List<WatchHistory>;
      log(myList.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLgScreen = size.width > kLgScreenWidth;
    const headStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    return Scaffold(
      appBar: AppBar(
        title: windowDragAreaWithChild(
          [
            const Text(
              "My Netflix",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
          actions: [
            IconButton(
              onPressed: () {
                GoRouter.of(context).push("/downloads");
              },
              icon: const Icon(
                HugeIcons.strokeRoundedDownload05,
                color: Colors.white,
                size: 28,
              ),
            ),
            IconButton(
              onPressed: () {
                GoRouter.of(context).push("/settings-audio-tracks");
                // GoRouter.of(context).push("/test");
              },
              icon: const Icon(Icons.settings, size: 28, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: isLgScreen,
      ),
      backgroundColor: Colors.black,
      // bottomNavigationBar: isLgScreen ? null : const MyNavBar(current: 3),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (myList.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text("My List", style: headStyle),
                SizedBox(
                  height: _imgHeight + 10,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: myList.map((e) {
                      final ott = OTT.fromId(e.ottId);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                        child: InkWell(
                          onTap: () {
                            GoRouter.of(
                              context,
                            ).push("/${ott.cookie}-movie", extra: e.id);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: ott.getImg(e.id),
                              height: _imgHeight,
                              width: _imgHeight * ott.aspectRatio,
                              cacheManager: e.isShow
                                  ? ShowCacheManager.instance
                                  : MovieCacheManager.instance,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (watchHistory.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text("Watch History", style: headStyle),
                SizedBox(
                  height: _imgHeight + 10 + 3.5,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: watchHistory.map((e) {
                      final ott = OTT.fromId(e.ottId);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        // mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: InkWell(
                              onTap: () {
                                GoRouter.of(
                                  context,
                                ).push("/${ott.cookie}-movie", extra: e.id);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: ott.getImg(e.id),
                                  height: _imgHeight,
                                  width: _imgHeight * ott.aspectRatio,
                                  cacheManager: e.isShow
                                      ? ShowCacheManager.instance
                                      : MovieCacheManager.instance,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: _imgHeight * ott.aspectRatio,
                            height: 3.5,
                            child: LinearProgressIndicator(
                              value: e.current / e.duration,
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.red,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 2,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    // final uri = Uri.parse("https://t.me/netmirror_app");
                    final uri = Uri.parse("https://t.me/+dOVQE6fRw3U3YWRl");
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      throw 'Could not launch telegram link';
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(153, 135, 135, 135),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          HugeIcons.strokeRoundedTelegram,
                          size: 40,
                          color: Colors.blue[400],
                        ),
                        const SizedBox(width: 30),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Join Telegram",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text("Request Movies, Updates, Report Bugs"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final uri = Uri.parse("https://netmirror.app");
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      throw 'Could not launch telegram link';
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(153, 135, 135, 135),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            "assets/logos/netmirror.png",
                            height: 40,
                            width: 40,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "NetMirror",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text("Official Netmirror Site"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 2,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(153, 135, 135, 135),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          "This Android App Was Created By  ",
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Sarisa Jaya Surya",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text("NetMirror",
                              //     style: TextStyle(
                              //       fontSize: 20,
                              //       fontWeight: FontWeight.bold,
                              //     )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
