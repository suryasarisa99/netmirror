import 'package:flutter/material.dart';

class HotstarBg extends StatefulWidget {
  final ScrollController? scrollController;
  const HotstarBg({required this.scrollController, super.key});

  @override
  State<HotstarBg> createState() => _HotstarBgState();
}

class _HotstarBgState extends State<HotstarBg> {
  double _scrollPosition = 0.0;
  static const double _maxScrollForFullOpacity = 240.0;
  static const Color _targetColor = Color(0xFF0f1014);

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController != null) {
      setState(() {
        _scrollPosition = widget.scrollController!.position.pixels;
      });
    }
  }

  Color _calculateBackgroundColor() {
    // Calculate opacity based on scroll position (0.0 to 1.0)
    double opacity = (_scrollPosition / _maxScrollForFullOpacity).clamp(
      0.0,
      1.0,
    );

    // Create color with calculated opacity
    return _targetColor.withOpacity(opacity);
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: _calculateBackgroundColor());
  }
}
