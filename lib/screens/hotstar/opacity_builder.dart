import 'dart:math';

import 'package:flutter/material.dart';

class ScrollPercentBuilder extends StatefulWidget
    implements PreferredSizeWidget {
  final ScrollController? scrollController;
  final double maxScroll;
  final double minScroll;
  final double height;
  final Widget Function(double opacity) builder;
  const ScrollPercentBuilder({
    required this.maxScroll,
    required this.builder,
    this.minScroll = 0.0,
    this.scrollController,
    this.height = kToolbarHeight - 5,
    super.key,
  });

  @override
  State<ScrollPercentBuilder> createState() => _ScrollPercentBuilderState();
  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _ScrollPercentBuilderState extends State<ScrollPercentBuilder> {
  double _scrollPosition = 0.0;
  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) return;
    widget.scrollController!.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ScrollPercentBuilder oldWidget) {
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
    double adjustedScrollPosition = max(0, _scrollPosition - widget.minScroll);
    // Calculate opacity based on scroll position (0.0 to 1.0)
    double opacity =
        (adjustedScrollPosition / (widget.maxScroll - widget.minScroll)).clamp(
          0.0,
          1.0,
        );
    return opacity;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_calculateOpacity());
  }
}
