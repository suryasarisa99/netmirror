import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/api/get_initial.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/db/db_helper.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/prime_video/pv_home_model.dart';
import 'package:netmirror/screens/netflix/nf_home_screen/nf_navbar.dart';
import 'package:netmirror/screens/netflix/nf_home_screen/nf_home_rows.dart';
import 'package:netmirror/screens/netflix/nf_home_screen/nf_tabs.dart';
import 'package:netmirror/widgets/top_buttons.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';

class NfMain extends StatelessWidget {
  const NfMain(this.shell, {super.key});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: const NfNavBar(current: 0),
    );
  }
}

class NfHomeScreen extends ConsumerStatefulWidget {
  const NfHomeScreen(this.tab, {super.key});
  final int tab;
  @override
  ConsumerState<NfHomeScreen> createState() => _NfHomeScreenState();
}

class _NfHomeScreenState extends ConsumerState<NfHomeScreen>
    with SingleTickerProviderStateMixin {
  // List<NfHomeModel?> dataList = [null, null, null];
  NfHomeModel? data;
  final _controller = ScrollController();

  // Animation controller for the entrance animation
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Scroll and color related variables
  double scrollProgress = 0.0;
  // double backgroundOpacity = 0.0;
  // double appBarOpacity = 0.0;
  static const int scrollThreshold = 30; // 600/20 = 30

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Create slide animation that starts from -50px (top) and moves to 0 (normal position)
    _slideAnimation = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    loadData();
    _controller.addListener(_handleScroll);

    // Start the animation when the screen opens (from -50px to 0px)
    _animationController.forward();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // Restart animation when coming back to this screen
  //   if (_animationController.value == 0.0) {
  //     _animationController.forward();
  //   }
  // }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String get currentTabName {
    return switch (widget.tab) {
      0 => "home",
      1 => "tvshows",
      2 => "movies",
      _ => "home",
    };
  }

  void _handleScroll() {
    final int offset = (_controller.offset / 8).toInt();
    final scrollThreshold = 30;
    if (offset > scrollThreshold || offset == scrollThreshold) return;
    setState(() {
      scrollProgress = (offset / scrollThreshold).clamp(0.0, 1.0);
    });
  }

  void loadData() async {
    final prvData = await DBHelper.instance.getNfHomePage(currentTabName);
    if (prvData == null || prvData.isStale) {
      loadDataFromOnline();
    } else {
      setState(() {
        data = prvData;
      });
    }
  }

  Future<void> loadDataFromOnline() async {
    final raw = await getNf(id: widget.tab, ott: OTT.none);
    final temp = NfHomeModel.parse(raw);
    setState(() {
      data = temp;
    });
    DBHelper.instance.addNfHomePage(currentTabName, temp);
  }

  void goToNewTab() {
    // Animation to move content to -50px (up) when tab is about to change
    _animationController.reverse().then((_) {
      // After animation completes, keep it at the reset position
      // The new screen will handle animating from -50px to 0px
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color? baseColor = data?.gradientColor;
    final backgroundOpacity =
        ((scrollProgress * scrollThreshold) / (scrollThreshold * 0.7)).clamp(
          0.0,
          1.0,
        );
    final appBarOpacity =
        ((scrollProgress * scrollThreshold) / (scrollThreshold * 0.3)).clamp(
          0.0,
          0.9,
        );

    // Calculate the background color
    final Color backgroundColor = baseColor != null
        ? Color.lerp(baseColor, Colors.black, backgroundOpacity)!
        : Colors.black;
    final paddingTop = MediaQuery.paddingOf(context).top;

    return RefreshIndicator(
      onRefresh: loadDataFromOnline,
      child: Scaffold(
        // backgroundColor: Colors.black,
        backgroundColor: backgroundColor,
        // bottomNavigationBar: const NfNavBar(current: 0),
        extendBodyBehindAppBar: true,

        body: CustomScrollView(
          controller: _controller,
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.black.withValues(alpha: appBarOpacity),
              surfaceTintColor: Colors.transparent,
              pinned: true,
              floating: true,
              expandedHeight: 108,
              title: windowDragAreaWithChild(
                [
                  widget.tab == 0
                      ? Image.asset(
                          "assets/logos/netflix.png",
                          height: 45,
                          width: 37,
                        )
                      : Text(
                          ["Tv Shows", "Movies", "Categories"][widget.tab - 1],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ],
                actions: [
                  TopbarButtons.settingsBtn(context),
                  TopbarButtons.downloadsBtn(context),
                  TopbarButtons.searchBtn(context),
                ],
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  // padding: EdgeInsets.only(top: isDesk ? 55 : 105),
                  padding: EdgeInsets.only(top: kToolbarHeight + paddingTop),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        // these color is showing on expanded mode of appbar only
                        // so : it shows initialy, and when scroll up
                        if (scrollProgress == 0) ...[
                          Color.lerp(
                            baseColor?.lighten(0.2) ?? Colors.black,
                            Colors.black,
                            scrollProgress,
                          )!,
                          // Base gradient color transitioning to black
                          Color.lerp(
                            baseColor?.withOpacity(0.5) ?? Colors.black,
                            Colors.black.withAlpha(200),
                            scrollProgress,
                          )!,
                        ] else ...[
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: NfHeaderTabs(widget.tab, goToNewTab),
                ),
              ),
            ),
            data == null
                ? const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 600,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                : SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Column(
                            children: [
                              buildSpotlight(backgroundColor, baseColor),
                              ...data!.trays.map((e) => NfHomeRow(tray: e)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget buildSpotlight(Color? hsl, Color? baseColor) {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).push("/nf-movie", extra: data!.spotlightId);
      },
      child: Container(
        height: 500,
        width: double.infinity,
        margin: const EdgeInsets.only(left: 25, right: 25, top: 8, bottom: 0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white54, width: 0.5),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              spreadRadius: 12,
              blurRadius: 40,
              offset: const Offset(0, 15), // Offset for bottom left corner
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              bottom: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl:
                      "https://imgcdn.media/poster/c/${data!.spotlightId}.jpg",
                  cacheManager: NfSpotLightCacheManager.instance,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.red,
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      baseColor?.withValues(alpha: 0.8) ??
                          Colors.black.withValues(alpha: 0.95),
                      baseColor ?? Colors.black,
                      baseColor ?? Colors.black,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.65, 0.75, 1.0],
                    // 0.75 to 1.0, complete base color
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            // Title and Genre
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        "https://imgcdn.media/poster/n/${data!.spotlightId}.jpg",
                    cacheManager: NfSpotLightCacheManager.instance,
                    height: 115,
                  ),
                  SizedBox(height: 12),
                  Text(
                    data!.genre.join("  $Dot  "),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll<Color>(
                                Colors.white,
                              ),
                              shape: WidgetStatePropertyAll<OutlinedBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            onPressed: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow),
                                SizedBox(width: 4),
                                Text("Play", style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll<Color>(
                                Colors.white.withOpacity(0.25),
                              ),
                              foregroundColor: WidgetStatePropertyAll<Color>(
                                Colors.white,
                              ),
                              shape: WidgetStatePropertyAll<OutlinedBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            onPressed: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text("MyList", style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
