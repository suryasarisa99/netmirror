import 'dart:math';
import 'package:flutter/material.dart';

class HotstarMovieAppbar extends StatefulWidget implements PreferredSizeWidget {
  final ScrollController? scrollController;
  final double maxScroll;
  final Color color;
  final String title;
  final double height;
  const HotstarMovieAppbar({
    required this.scrollController,
    required this.maxScroll,
    required this.color,
    required this.title,
    this.height = kToolbarHeight - 18,
    super.key,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);
  @override
  State<HotstarMovieAppbar> createState() => _HotstarMovieAppbarState();
}

class _HotstarMovieAppbarState extends State<HotstarMovieAppbar> {
  double _scrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) return;
    widget.scrollController!.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant HotstarMovieAppbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController == null) return;
    final pixels = widget.scrollController!.position.pixels;
    if (_scrollPosition > widget.maxScroll + 5 &&
        pixels > widget.maxScroll + 5) {
      return;
    }
    setState(() {
      _scrollPosition = pixels;
    });
  }

  double _calculateOpacity() {
    double adjustedScrollPosition = max(0, _scrollPosition - 30);
    // Calculate opacity based on scroll position (0.0 to 1.0)
    double opacity = (adjustedScrollPosition / (widget.maxScroll - 30)).clamp(
      0.0,
      1.0,
    );
    return opacity;
  }

  @override
  Widget build(BuildContext context) {
    final opacity = _calculateOpacity();
    return AppBar(
      backgroundColor: widget.color.withValues(alpha: opacity),
      // backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 18,
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: opacity),
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            iconSize: 22,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  // final paddingTop = MediaQuery.paddingOf(context).top;
  // return Container(
  //   height: widget.height + paddingTop,
  //   color: widget.color.withValues(alpha: opacity),
  //   padding: EdgeInsets.only(left: 18, right: 18, top: paddingTop),
  //   child: Row(
  //     children: [
  //       Expanded(
  //         child: Text(
  //           widget.title,
  //           style: TextStyle(
  //             color: Colors.white.withValues(alpha: opacity),
  //             fontSize: 20,
  //           ),
  //         ),
  //       ),
  //       IconButton(
  //         icon: Icon(Icons.close, color: Colors.white),
  //         iconSize: 22,
  //         onPressed: () => Navigator.of(context).pop(),
  //       ),
  //     ],
  //   ),
  // );

  //   return SliverAppBar(
  //     backgroundColor: widget.color.withValues(alpha: opacity),
  //     surfaceTintColor: Colors.transparent,
  //     automaticallyImplyLeading: false,
  //     titleSpacing: 18,
  //     pinned: true,
  //     title: Row(
  //       children: [
  //         Expanded(
  //           child: Text(
  //             widget.title,
  //             style: TextStyle(color: Colors.white.withValues(alpha: opacity)),
  //           ),
  //         ),
  //         IconButton(
  //           icon: Icon(Icons.close, color: Colors.white),
  //           iconSize: 22,
  //           onPressed: () => Navigator.of(context).pop(),
  //         ),
  //       ],
  //     ),
  //     expandedHeight: widget.height + MediaQuery.paddingOf(context).top,
  //   );
  // }
}
