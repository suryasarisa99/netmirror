import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/api/get_search.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/search_results_model.dart';
import 'package:netmirror/utils/nav.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';
import 'package:netmirror/widgets/sticky_header_delegate.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';
import 'package:shared_code/models/ott.dart';

class Search extends ConsumerStatefulWidget {
  const Search(this.tabIndex, {super.key});

  final int tabIndex;

  @override
  ConsumerState<Search> createState() => _NmSearchState();
}

class _NmSearchState extends ConsumerState<Search>
    with SingleTickerProviderStateMixin {
  late int _tabIndex = widget.tabIndex;
  late final TabController _tabController = TabController(
    length: 5,
    vsync: this,
  );
  late final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final List<SearchResults?> searchResults = [null, null, null, null, null];
  final searchFocusNode = FocusNode();
  final focusScopeNode = FocusScopeNode();
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
    if (_tabIndex != 0) {
      _tabController.animateTo(
        _tabIndex,
        duration: const Duration(milliseconds: 50),
      );
    }
    // listen for tab changes
    _tabController.addListener(_onTabChange);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _searchController.removeListener(_onSearchChanged);
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  _onTabChange() {
    log("===================== Changed to ${_tabController.index}");
    int newTabIndex = _tabController.index;

    setState(() {
      _tabIndex = newTabIndex;
      if (searchResults[newTabIndex] == null ||
          searchResults[newTabIndex]!.query != _searchController.text) {
        searchResults[newTabIndex] = null;
        log("inside if condition");
        if (newTabIndex <= 2) {
          handleSearch();
        }
      }
    });
  }

  _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      handleSearch();
    });
  }

  Future<void> handleSearch() async {
    if (_searchController.text.isNotEmpty) {
      log("searching tab: $_tabIndex, query: ${_searchController.text}");
      int backupTabIndex = _tabIndex;

      final x = await getSearchResults(
        _searchController.text,
        ott: OTT.values[backupTabIndex],
      );

      setState(() {
        searchResults[backupTabIndex] = x;
      });
    }
  }

  Widget buildSearchbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: TextField(
        autofocus: true,
        controller: _searchController,
        onTapOutside: (e) {
          searchFocusNode.unfocus();
        },
        style: const TextStyle(color: Colors.white),
        focusNode: searchFocusNode,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          isDense: true,
          hintText: 'Search',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color.fromARGB(221, 51, 51, 51),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(width: 0, style: BorderStyle.none),
          ),
        ),
      ),
    );
  }

  int getNetflixCrossAxisCount(double width) {
    if (width < 700) return 2;
    if (width < 1000) return 3;
    if (width < 1500) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return DesktopWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              if (Platform.isMacOS)
                SizedBox(height: 20), // Space for the title bar on macOS
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, b) {
                    return [
                      SliverAppBar(
                        title: buildSearchbar(),
                        automaticallyImplyLeading: false,
                        titleSpacing: 0,
                        backgroundColor: Colors.black,
                        floating: true,
                        snap: true,
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: StickyHeaderDelegate(
                          minHeight: 40.0,
                          maxHeight: 40.0,
                          child: Container(
                            color: Colors.black,
                            child: TabBar(
                              controller: _tabController,
                              indicatorWeight: 1.0,

                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorColor: Colors.white,
                              labelStyle: const TextStyle(
                                fontSize: 17.0,
                                fontWeight: FontWeight.bold,
                              ),
                              // overlayColor: WidgetStatePropertyAll(Colors.red),
                              unselectedLabelColor: Colors.grey,
                              labelColor: Colors.white,
                              isScrollable: true,
                              tabs: OTT.values
                                  .map((e) => Tab(text: e.name))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      buildGridSearchResults(
                        size: size,
                        ott: OTT.netflix,
                        count: getNetflixCrossAxisCount(size.width),
                      ),
                      buildPrimeVideoSearchResults(),
                      buildGridSearchResults(
                        size: size,
                        ott: OTT.hotstar,
                        count: getNetflixCrossAxisCount(size.width) + 1,
                      ),
                      const Center(child: Text('Not Implemented Yet')),
                      const Center(child: Text('Not Implemented Yet')),
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

  Widget buildGridSearchResults({
    required Size size,
    required OTT ott,
    required int count,
  }) {
    if (_searchController.text.isEmpty) {
      return const Center(child: Text('Search for something'));
    }

    final searchResult = searchResults[ott.index]; // Remove the force unwrap
    if (searchResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResult.error.isNotEmpty) {
      return Center(
        child: Text(
          searchResult.error,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: handleSearch,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        itemCount: searchResult.results.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesk ? count : 3,
          // childAspectRatio: OTT.none.vImgRatio,
          childAspectRatio: ott.aspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final result = searchResult.results[index];
          return GestureDetector(
            onTap: () {
              goToMovie(context, ott.index, result.id);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                searchResult.ott.getImg(result.id),
                // width: 80,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildPrimeVideoSearchResults() {
    if (_searchController.text.isEmpty) {
      return const Center(child: Text('Search for something'));
    }

    final searchResult = searchResults[1]; // Remove the force unwrap
    if (searchResult == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (searchResult.error.isNotEmpty) {
      return Center(
        child: Text(
          searchResult.error,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: handleSearch,
      child: ListView.builder(
        itemCount: searchResult.results.length,
        itemBuilder: (context, index) {
          final result = searchResult.results[index];
          return InkWell(
            onTap: () {
              goToMovie(context, 1, result.id);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: searchResult.ott.getImg(result.id),
                      cacheManager: PvSmallCacheManager.instance,
                      width: 150,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.t,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          "${result.y ?? ''} ${result.r ?? ''}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
