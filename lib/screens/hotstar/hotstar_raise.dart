import 'package:flutter/material.dart';

class RaiseWidget extends StatefulWidget {
  final ScrollController scrollController;
  final Widget child;
  const RaiseWidget({
    required this.scrollController,
    required this.child,
    super.key,
  });

  @override
  State<RaiseWidget> createState() => _RaiseWidgetState();
}

class _RaiseWidgetState extends State<RaiseWidget> {
  double _scrollPosition = 0.0;
  static const double _maxScrollForFullRaise = 240.0;
  static const double _maxRaisePixels = 15.0;

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
    setState(() {
      _scrollPosition = widget.scrollController.position.pixels;
    });
  }

  double _calculateRaiseOffset() {
    // Calculate the raise offset based on scroll position
    // From 0 to 240px scroll → 0 to 20px raise
    double progress = (_scrollPosition / _maxScrollForFullRaise).clamp(
      0.0,
      1.0,
    );
    return progress * _maxRaisePixels;
  }

  @override
  Widget build(BuildContext context) {
    double raiseOffset = _calculateRaiseOffset();
    return Transform.translate(
      offset: Offset(0, -raiseOffset), // Negative Y to raise upward
      child: widget.child,
    );
  }
}
