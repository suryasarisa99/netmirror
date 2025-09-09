import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/home_models.dart';
import 'package:netmirror/screens/home_abstract.dart';
import 'package:netmirror/screens/prime_video/home_screen/pv_header_tab.dart';
import 'package:netmirror/screens/prime_video/home_screen/pv_home_row.dart';
import 'package:netmirror/screens/prime_video/pv_navbar.dart';
import 'package:netmirror/utils/nav.dart';
import 'package:netmirror/widgets/top_buttons.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';

class PvMain extends StatelessWidget {
  const PvMain(this.shell, {super.key});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: shell.currentIndex,
        onItemSelected: shell.goBranch,
      ),
    );
  }
}

class PvHomeScreen extends Home {
  const PvHomeScreen({super.key, required super.tab});
  @override
  State<Home> createState() => _PvHomeScreenState();
}

class _PvHomeScreenState extends HomeState<PvHomeModel, PvHomeScreen>
    with SingleTickerProviderStateMixin {
  @override
  OTT ott = OTT.pv;
  int currentCarouselIndex = 0;
  int currentNavigationIndex = 0;
  var carouselController = CarouselSliderController();
  var scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadDataFromOnline,
      displacement: 50,
      edgeOffset: 120,
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: true,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              buildAppBar(),
              if (data == null)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 500,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: buildCarousel()),
                SliverList.builder(
                  itemCount: data!.trays.length,
                  itemBuilder: (context, i) {
                    final tray = data!.trays[i];
                    return tray.isTop10
                        ? PvHomeTop10Row(tray: tray)
                        : PvHomeRow(tray: tray);
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAppBar() {
    const double toolbarHeight = kToolbarHeight - 10;
    const double extendedHeight = 60;

    return SliverAppBar(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.black,
      titleSpacing: 24,
      automaticallyImplyLeading: false,
      title: windowDragAreaWithChild(
        [
          widget.tab == 0
              ? Image.asset("assets/logos/pv-header.png", width: 80)
              : Text(
                  widget.tab == 1 ? "Movies" : "Tv Shows",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ],
        actions: [
          TopbarButtons.settingsBtn(context),
          TopbarButtons.downloadsBtn(context),
          TopbarButtons.searchBtn(context, 1),
        ],
      ),
      toolbarHeight: toolbarHeight,
      expandedHeight: toolbarHeight + extendedHeight,
      floating: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          margin: const EdgeInsets.only(top: toolbarHeight - 5),
          child: PvHeaderTabs(tab: widget.tab),
        ),
      ),
    );
  }

  Widget buildCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: CarouselSlider(
            carouselController: carouselController,
            options: CarouselOptions(
              height: 230,
              aspectRatio: 0.5,
              autoPlayInterval: const Duration(seconds: 5),
              viewportFraction: 1,
              enableInfiniteScroll: true,
              autoPlay: true,
              onPageChanged: (index, reason) {
                setState(() {
                  currentCarouselIndex = index;
                });
              },
            ),
            items: data!.carouselImages.map((item) {
              return Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () {
                      goToMovie(context, 1, item.id);
                    },
                    child: CachedNetworkImage(
                      imageUrl: item.img,
                      fit: BoxFit.cover,
                      cacheManager: PvSpotLightCacheManager.instance,
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(data!.carouselImages.length, (i) {
            bool isSelected = i == currentCarouselIndex;
            return GestureDetector(
              onTap: () {
                carouselController.animateToPage(i);
              },
              child: AnimatedContainer(
                width: isSelected ? 12 : 5,
                height: 5,
                margin: EdgeInsets.symmetric(horizontal: isSelected ? 4 : 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  borderRadius: BorderRadius.circular(5),
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
