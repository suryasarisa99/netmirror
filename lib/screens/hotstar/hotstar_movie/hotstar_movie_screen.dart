import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/screens/hotstar/hotstar_button.dart';
import 'package:netmirror/screens/movie_abstract.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';

class HotstarMovieScreen extends MovieScreen {
  const HotstarMovieScreen(super.id, {super.key});

  @override
  ConsumerState<MovieScreen> createState() => _HoststarMovieScreenState();
}

const l = L("hotstar_movie_screen");

class _HoststarMovieScreenState extends MovieScreenState {
  @override
  OTT ott = OTT.hotstar;
  @override
  bool extraTabForCast = true;

  @override
  void initState() {
    super.initState();
    l.debug("HotstarMovieScreen initState");
  }

  @override
  void dispose() {
    l.debug("HotstarMovieScreen dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return DesktopWrapper(
      child: Scaffold(
        backgroundColor: Color(0xFF0F1014),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              if (Platform.isMacOS)
                SliverToBoxAdapter(child: SizedBox(height: 28)),
              // SliverAppBar(
              //   backgroundColor: Colors.black,
              //   surfaceTintColor: Colors.black,
              //   toolbarHeight: 48,
              //   title: windowDragAreaWithChild(
              //     [],
              //     actions: [
              //       IconButton(
              //         onPressed: () {
              //           GoRouter.of(context).push("/downloads");
              //         },
              //         icon: isDesk
              //             ? Icon(Icons.download, size: 20)
              //             : Icon(
              //                 HugeIcons.strokeRoundedDownload05,
              //                 size: 30,
              //                 color: Colors.white,
              //               ),
              //       ),
              //       IconButton(
              //         onPressed: () {
              //           GoRouter.of(context).push("/search/${ott.id}");
              //         },
              //         icon: isDesk
              //             ? Icon(Icons.search, size: 20)
              //             : Icon(Icons.search, size: 30, color: Colors.white),
              //       ),
              //     ],
              //   ),
              // ),
              SliverToBoxAdapter(child: _buildMoviePoster()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // _buildMoviePoster(),
                      if (movie != null)
                        ...buildMainData(size)
                      else
                        SizedBox(
                          height: 400,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildMainData(Size size) {
    return [
      HotstarButton(text: "Watch Now", onPressed: () {}),
      SizedBox(height: 16),
      _buildActions(),
      SizedBox(height: 16),

      // Genre Tags
      SizedBox(
        width: size.width,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: movie!.genre.mapIndexed((index, genre) {
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      genre,
                      style: TextStyle(
                        color: Color(0xFFe0e4ed),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Add gray line separator, but not after the last item
                  if (index < movie!.genre.length - 1)
                    Container(
                      width: 1,
                      height: 12,
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),

      // Movie Description
      Text(
        movie!.desc,
        style: TextStyle(color: Color(0xFFe0e4ed), fontSize: 14),
      ),
    ];
  }

  Widget _buildMoviePoster() {
    final size = MediaQuery.sizeOf(context);
    return SizedBox(
      width: size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Movie Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: "https://imgcdn.media/hs/h/700/${widget.id}.jpg",
                cacheManager: NfLargeCacheManager.instance,
                fit: BoxFit.cover,
                width: size.width,
              ),
            ),

            const SizedBox(height: 16),

            // Movie Title Image
            // w=1.788 of height
            CachedNetworkImage(
              imageUrl: "https://imgcdn.media/hs/n/${widget.id}.png",
              cacheManager: NfLargeCacheManager.instance,
              height: 80,
              width: 80 * 1.788,
            ),

            const SizedBox(height: 16),

            // Movie Description
          ],
        ),
      ),
    );
  }

  // Widget _buildWatchButton() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           Color(0xFF1491FF),
  //           Color(0xFF155BBD),
  //           Color(0xFF67379D),
  //           Color(0xFFDB0765),
  //         ],
  //         // stops: [0.6, 0.8, 1.0],
  //       ),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Material(
  //       color: Colors.transparent,
  //       borderRadius: BorderRadius.circular(8),
  //       child: InkWell(
  //         borderRadius: BorderRadius.circular(8),
  //         onTap: () {},
  //         child: Container(
  //           width: 200,
  //           height: 40,
  //           alignment: Alignment.center,
  //           child: Text(
  //             "Watch Now",
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: 16,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildActions() {
    return Row(
      spacing: 28,
      children: [
        const SizedBox(width: 10),
        _actionBtn(
          LottieBuilder.asset(
            "assets/lottie/hotstar/watchlist_animation_blue.json",
            // "assets/lottie/my-list-plus-to-check.json",
            controller: watchlistAnimationController,
            height: 24,
            onLoaded: (composition) {
              // Set initial state based on inWatchlist
              if (inWatchlist) {
                watchlistAnimationController.value = 1.0;
              } else {
                watchlistAnimationController.value = 0.0;
              }
            },
          ),
          "Watchlist",
          handleAddWatchlist,
        ),
        _actionBtn(
          _icon(HugeIcons.strokeRoundedDownload05),
          "Download",
          downloadMovie,
        ),
        _actionBtn(
          _icon(HugeIcons.strokeRoundedShare08),
          "Share",
          shareDeepLinkUrl,
        ),
        _actionBtn(
          _icon(HugeIcons.strokeRoundedFavourite, size: 19),
          "Share",
          shareDeepLinkUrl,
        ),
      ],
    );
  }

  Widget _actionBtn(Widget icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          Text(label, style: TextStyle(color: Color(0xFFe0e4ed), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, {double size = 22}) {
    return Icon(icon, size: size, color: Color(0xFFe0e4ed));
  }
}
