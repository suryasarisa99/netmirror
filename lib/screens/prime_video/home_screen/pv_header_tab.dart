import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';

class PvHeaderTabs extends StatelessWidget {
  final int tab;

  const PvHeaderTabs({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const SizedBox(width: 15),
      if (tab == 0)
        ...["Movies", "Tv Shows"].mapIndexed((i, e) {
          return PvHeaderTab(
              name: e,
              isSelected: i + 1 == tab,
              onTap: () {
                context.push("/pv-home", extra: i + 1);
                // changeTab(i + 1);
              });
        })
      else
        PvHeaderTab(
          name: tab == 1 ? "Movies" : "Tv Shows",
          isSelected: true,
          onTap: () => {},
        ),
    ]);
  }
}

class PvHeaderTab extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback? onTap;
  const PvHeaderTab({
    super.key,
    required this.name,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelected ? () => context.pop() : onTap,
      child: Hero(
        tag: "pv-tab-$name",
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30),
            color: isSelected ? Colors.white : Colors.transparent,
          ),
          child: isSelected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.close, color: Colors.black, size: 16)
                  ],
                )
              : Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
        ),
      ),
    );
  }
}
