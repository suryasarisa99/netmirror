import 'dart:math';

import 'package:flutter/material.dart';

class HotstarAppbar extends StatefulWidget implements PreferredSizeWidget {
  final ScrollController scrollController;
  final double maxScroll;
  final Color color;
  final double height;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? title;

  const HotstarAppbar({
    required this.scrollController,
    required this.maxScroll,
    required this.color,
    this.height = kToolbarHeight - 5,
    this.leading,
    this.actions,
    this.title,
    super.key,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  State<HotstarAppbar> createState() => _HotstarAppbarState();
}

class _HotstarAppbarState extends State<HotstarAppbar> {
  double _scrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final pixels = widget.scrollController.position.pixels;
    if (_scrollPosition > widget.maxScroll + 5 &&
        pixels > widget.maxScroll + 5) {
      return;
    }
    setState(() {
      _scrollPosition = pixels;
    });
  }

  Color _calculateBackgroundColor() {
    double adjustedScrollPosition = max(0, _scrollPosition - 30);
    // Calculate opacity based on scroll position (0.0 to 1.0)
    double opacity = (adjustedScrollPosition / (widget.maxScroll - 30)).clamp(
      0.0,
      1.0,
    );

    // Create color with calculated opacity
    return widget.color.withValues(alpha: opacity);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _calculateBackgroundColor(),
      surfaceTintColor: Colors.transparent,
      leading: widget.leading,
      actions: widget.actions,
      title: widget.title,
      toolbarHeight: widget.height,
      titleSpacing: 0.0, // To ensure title is centered
    );
  }
}
