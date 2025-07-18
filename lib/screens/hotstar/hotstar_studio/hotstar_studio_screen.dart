import 'package:flutter/material.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/home_models.dart';
import 'package:netmirror/screens/home_abstract.dart';
import 'package:netmirror/screens/hotstar/hotstar_widgets.dart';
import 'package:netmirror/screens/hotstar/hotstar_home/hotstar_home_screen.dart';
import 'package:netmirror/screens/hotstar/opacity_builder.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';
import 'package:shared_code/models/ott.dart';

class HotstarStudioScreen extends Home {
  final String studioName;
  const HotstarStudioScreen({
    required this.studioName,
    required super.tab,
    super.key,
  });

  @override
  State<Home> createState() => HotstarStudioScreenState();
}

const l = L("hotstar_studio");

class HotstarStudioScreenState
    extends HomeState<HotstarModel, HotstarStudioScreen> {
  @override
  final OTT ott = OTT.hotstar;
  @override
  String get currentTabName => widget.studioName;
  @override
  String? get studioName => widget.studioName;

  final scrollController = ScrollController();
  late final studio = studios.firstWhere((s) => s.studio == widget.studioName);

  buildAppBar(double maxScroll, Color bg) {
    return ScrollPercentBuilder(
      maxScroll: maxScroll,
      scrollController: scrollController,
      height: kToolbarHeight - 5,
      builder: (opacity) {
        return AppBar(
          backgroundColor: bg.withValues(alpha: opacity),
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0.0,
          toolbarHeight: kToolbarHeight - 5,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    l.debug("--- rebuilding");
    final maxScrollRange = 170.0;
    final size = MediaQuery.sizeOf(context);
    final bg = Color(0xFF0f1014);
    return DesktopWrapper(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: bg,
        appBar: buildAppBar(maxScrollRange, bg),
        body: SizedBox(
          height: size.height,
          width: size.width,
          child: Stack(
            children: [
              ScrollPercentBuilder(
                maxScroll: maxScrollRange,
                scrollController: scrollController,
                height: size.height,
                builder: (per) {
                  return Transform.translate(
                    offset: Offset(0, -(per * 25)),
                    child: buildStudioPoster(),
                  );
                },
              ),
              Positioned.fill(
                child: ScrollPercentBuilder(
                  maxScroll: maxScrollRange,
                  scrollController: scrollController,
                  height: size.height,
                  builder: (opacity) =>
                      Container(color: bg.withValues(alpha: opacity)),
                ),
              ),
              CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: size.width - 90)),
                  SliverToBoxAdapter(
                    child: HotstarStudioList(curr: studioName),
                  ),
                  data == null
                      ? SliverToBoxAdapter(
                          child: SizedBox(
                            height: size.height - size.width - 80,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : HotstarRows(trays: data!.trays),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStudioPoster() {
    final size = MediaQuery.sizeOf(context);
    final clr = Color(0xFF0f1014);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          Positioned(
            child: Image.asset(
              "assets/hotstar/studio-posters/${widget.studioName}.jpg",
              fit: BoxFit.cover,
              width: size.width,
              height: size.width,
            ),
          ),
          if (studio.gradient != null)
            Positioned(
              top: size.width - 40,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                // color: Colors.red,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [studio.gradient!, clr],
                  ),
                ),
              ),
            ),
          if (!studio.title)
            Positioned(
              top: (size.width) / 2 - 180 / 2,
              left: (size.width) / 2 - 300 / 2,
              right: (size.width) / 2 - 300 / 2,
              child: Image.asset(studio.titlePath),
            ),
        ],
      ),
    );
  }
}
