import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NfHeaderTabs extends StatefulWidget {
  final int tab;
  const NfHeaderTabs(this.tab, {super.key});

  @override
  State<NfHeaderTabs> createState() => _NfHeaderTabsState();
}

class _NfHeaderTabsState extends State<NfHeaderTabs> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _showCloseBtn();
  }

  void _showCloseBtn() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  void _hideCloseBtn() {
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ["Tv Shows", "Movies"];
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Hide button when back navigation is invoked
        if (didPop) {
          _hideCloseBtn();
        }
      },
      child: Row(
        children: [
          const SizedBox(width: 15),
          if (widget.tab == 0)
            ...tabs.mapIndexed((i, e) {
              return NfHeaderTab(
                name: e,
                isSelected: false,
                onTap: () {
                  log("naviagting to /nf-home/$i");
                  context.push("/nf-home", extra: i + 1);
                },
              );
            })
          else
            buildCloseBtn(),
          if (widget.tab == 1)
            NfHeaderTab(name: "Tv Shows", isSelected: true, onTap: () {})
          else if (widget.tab == 2)
            NfHeaderTab(name: "Movies", isSelected: true, onTap: () {}),
        ],
      ),
    );
  }

  Widget buildCloseBtn() {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: _isVisible
          ? const Duration(milliseconds: 500)
          : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: () {
          // Hide the button immediately when tapped
          _hideCloseBtn();
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              GoRouter.of(context).pop();
            } catch (_) {}
          });
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: 0.5, color: Colors.white),
          ),
          child: const Icon(Icons.close, color: Colors.white70, size: 22),
        ),
      ),
    );
  }
}

class NfHeaderTab extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;

  const NfHeaderTab({
    super.key,
    required this.name,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: "nf-tab-$name",
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white70),
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
