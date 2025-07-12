import 'package:flutter/material.dart';

class HotstarBg extends StatefulWidget {
  final ScrollController scrollController;
  final double maxScroll;
  final Color color;
  const HotstarBg({
    required this.maxScroll,
    required this.color,
    required this.scrollController,
    super.key,
  });

  @override
  State<HotstarBg> createState() => _HotstarBgState();
}

class _HotstarBgState extends State<HotstarBg> {
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
    // if ((_scrollPosition - pixels).abs() < 5.0) {
    //   // ignore small changes
    //   return;
    // }

    setState(() {
      _scrollPosition = pixels;
    });
  }

  Color _calculateBackgroundColor() {
    // Calculate opacity based on scroll position (0.0 to 1.0)
    double opacity = (_scrollPosition / widget.maxScroll).clamp(0.0, 1.0);
    // Create color with calculated opacity
    return widget.color.withValues(alpha: opacity);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("rebuilding");
    return Container(color: _calculateBackgroundColor());
  }
}
