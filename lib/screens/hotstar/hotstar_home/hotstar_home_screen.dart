import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/home_models.dart';
import 'package:netmirror/screens/home_abstract.dart';
import 'package:netmirror/screens/hotstar/hotstar_widgets.dart';
import 'package:netmirror/screens/hotstar/hotstar_button.dart';
import 'package:netmirror/screens/hotstar/hotstar_navbar.dart';
import 'package:netmirror/screens/hotstar/opacity_builder.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';
import 'package:shared_code/models/ott.dart';

class HotstarMain extends StatelessWidget {
  final Widget shell;

  const HotstarMain(this.shell, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: HotstarNavbar(
        selectedIndex: 0,
        onItemSelected: (_) {},
      ),
      body: shell,
    );
  }
}

class Studio {
  final String studio;
  final bool title;
  final Color? gradient;

  const Studio(this.studio, {this.title = true, this.gradient});

  String get assetPath => "assets/hotstar/studio-lists/$studio.png";
  String get posterPath => "assets/hotstar/studio-posters/$studio.jpg";
  String get titlePath => "assets/hotstar/studio-titles/$studio.png";
}

const List<Studio> studios = [
  Studio("special"),
  Studio("disney", title: false),
  Studio("hbo"),
  Studio("peacock"),
  Studio("paramount", gradient: Color(0xff234FC5)),
  Studio("marvel", title: false),
  Studio("pixar"),
  // Studio("star-wars", title: true),
  Studio("national", title: false),
];

class HotstarHomeScreen extends Home {
  const HotstarHomeScreen({required super.tab, super.key});

  @override
  State<Home> createState() => HotstarHomeState();
}

const l = L("hotstar_home");

class HotstarHomeState extends HomeState<HotstarModel, HotstarHomeScreen> {
  @override
  final OTT ott = OTT.hotstar;

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return DesktopWrapper(
      child: Scaffold(
        backgroundColor: Color(0xFF0f1014),
        extendBodyBehindAppBar: true,
        appBar: ScrollPercentBuilder(
          minScroll: 180,
          maxScroll: 200.0,
          scrollController: scrollController,
          height: MediaQuery.paddingOf(context).top,
          builder: (opacity) {
            return Container(
              height: MediaQuery.paddingOf(context).top,
              color: Color(0xFF0f1014).withValues(alpha: opacity),
            );
          },
        ),
        body: data == null
            ? Center(child: CircularProgressIndicator())
            : CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(child: buildHome()),
                  HotstarRows(trays: data!.trays),
                ],
              ),
      ),
    );
  }

  Widget buildHome() {
    return Column(
      children: [
        buildPoster(),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HotstarButton(text: "Watch Now", onPressed: () {}),
            SizedBox(width: 12),
            buildWatchList(),
          ],
        ),
        SizedBox(height: 8),
        HotstarStudioList(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget buildPoster() {
    final size = MediaQuery.sizeOf(context);
    final clr = Color(0xFF0f1014);
    final imgUrl = data!.spotlightImg.startsWith("http")
        ? data!.spotlightImg
        : "https://netfree2.cc/${data!.spotlightImg}";
    final titleImg = data!.titleImg.startsWith("http")
        ? data!.titleImg
        : "https://netfree2.cc/${data!.titleImg}";
    return SizedBox(
      height: size.width / 1.778 + 80,
      child: Stack(
        children: [
          Positioned(
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              fit: BoxFit.cover,
              cacheManager: PvSmallCacheManager.instance,
              width: size.width,
              height: size.width / 1.778 + 60,
              alignment: Alignment(0, -1),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, clr, clr],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: size.width / 2 - 80,
            right: size.width / 2 - 80,
            child: CachedNetworkImage(
              imageUrl: titleImg,
              cacheManager: PvSmallCacheManager.instance,
              width: 160,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWatchList() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF212227),
        borderRadius: BorderRadius.circular(6),
      ),
      child: LottieBuilder.asset(
        "assets/lottie/hotstar/watchlist_animation_blue.json",
        height: 24,
        animate: false,
        onLoaded: (composition) {},
      ),
    );
  }
}
