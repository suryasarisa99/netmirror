import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/api/get_search.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/models/cache_model.dart';
import 'package:netmirror/models/search_results_model.dart';
import 'package:netmirror/utils/nav.dart';
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
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
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

  _onTabChange() {
    log("===================== Changed to ${_tabController.index}");
    int newTabIndex = _tabController.index;

    setState(() {
      _tabIndex = newTabIndex;
      if (searchResults[newTabIndex] == null ||
          searchResults[newTabIndex]!.query != _searchController.text) {
        searchResults[newTabIndex] = null;
      }
      if (newTabIndex <= 1) {
        handleSearch();
      }
    });
  }

  _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      handleSearch();
    });
  }

  void handleSearch() async {
    if (_searchController.text.isNotEmpty) {
      log("message: ${_searchController.text}");
      int backupTabIndex = _tabIndex;

      final x = await getNmSearch(
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
        controller: _searchController,
        onTapOutside: (e) {
          focusNode.unfocus();
        },
        style: const TextStyle(color: Colors.white),
        focusNode: focusNode,
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        title: windowDragAreaWithChild([const Text('Search')]),
        // title: ,
      ),
      body: Column(
        children: [
          buildSearchbar(),
          TabBar(
            controller: _tabController,
            indicatorWeight: 1.0,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelColor: Colors.grey,
            labelColor: Colors.white,
            isScrollable: true,
            tabs: OTT.values.map((e) => Tab(text: e.name)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Text('Netflix'),
                buildNetflixSearchResults(size),
                buildPrimeVideoSearchResults(),
                const Center(child: Text('Not Implemented Yet')),
                const Center(child: Text('Not Implemented Yet')),
                const Center(child: Text('Not Implemented Yet')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNetflixSearchResults(Size size) {
    if (_searchController.text.isEmpty) {
      return const Center(child: Text('Search for something'));
    }

    final searchResult = searchResults[0]; // Remove the force unwrap
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

    int getCrossAxisCount(double width) {
      if (width < 700) return 2;
      if (width < 1000) return 3;
      if (width < 1500) return 4;
      return 5;
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      itemCount: searchResult.results.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesk ? getCrossAxisCount(size.width) : 3,
        // childAspectRatio: OTT.none.vImgRatio,
        childAspectRatio: OTT.netflix.aspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final result = searchResult.results[index];
        return GestureDetector(
          onTap: () {
            goToMovie(context, 0, result.id);
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
    );
  }

  Widget buildPrimeVideoSearchResults() {
    if (_searchController.text.isEmpty) {
      return const Center(child: Text('Search for something'));
    }

    final searchResult = searchResults[1]; // Remove the force unwrap
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

    return ListView.builder(
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
    );
  }
}
