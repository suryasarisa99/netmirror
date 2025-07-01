import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/widgets/ott_drawer.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Color.fromRGBO(93, 93, 93, 1),
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, context, Icons.home_outlined, 'Home'),
          // _buildNavItem(1, context, HugeIcons.strokeRoundedPlay, 'OTT'),
          _buildNavItem(1, context, HugeIcons.strokeRoundedMenuSquare, 'OTT'),
          _buildNavItem(3, context, Icons.download_outlined, 'Downloads'),
          _buildNavItem(4, context, Icons.search, 'Search'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, BuildContext c, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return Stack(
      children: [
        if (isSelected)
          Positioned(
            top: -30,
            child: Container(
              width: 70,
              height: 55,
              alignment: Alignment.topCenter,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.38),
                    Colors.white.withOpacity(0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.2, 0.75, 1],
                  radius: 0.8,
                ),
              ),
            ),
          ),
        InkWell(
          onTap: () {
            // onItemSelected(index);
            switch (index) {
              case 0:
                break;
              case 1:
                showModalBottomSheet(
                  context: c,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return OttDrawer(selectedOtt: 1);
                  },
                );
                break;
              case 3:
                GoRouter.of(c).push('/downloads');
                break;
              case 4:
                GoRouter.of(c).push('/search', extra: 1);
                break;
            }
          },
          child: SizedBox(
            width: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
