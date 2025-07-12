import 'package:flutter/material.dart';

class RaiseWidget extends StatefulWidget {
  final ScrollController scrollController;
  final Widget child;
  final double maxScroll;
  final double maxRaisePixels;
  const RaiseWidget({
    required this.maxScroll,
    required this.scrollController,
    required this.child,
    this.maxRaisePixels = 20.0,
    super.key,
  });

  @override
  State<RaiseWidget> createState() => _RaiseWidgetState();
}

class _RaiseWidgetState extends State<RaiseWidget> {
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

  double _calculateRaiseOffset() {
    // Calculate the raise offset based on scroll position
    // From 0 to 240px scroll → 0 to 20px raise
    double progress = (_scrollPosition / widget.maxScroll).clamp(0.0, 1.0);
    return progress * widget.maxRaisePixels;
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
