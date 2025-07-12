import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:netmirror/widgets/ott_drawer.dart';

class HotstarNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const HotstarNavbar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Color(0xFF0f1014),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, context, FontAwesome.house_solid, 'Home', size: 20),
          // _buildNavItem(1, context, HugeIcons.strokeRoundedPlay, 'OTT'),
          _buildNavItem(1, context, HugeIcons.strokeRoundedMenuSquare, 'OTT'),
          _buildNavItem(3, context, Icons.download_outlined, 'Downloads'),
          _buildNavItem(4, context, Icons.search, 'Search'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    BuildContext c,
    IconData icon,
    String label, {
    double size = 24,
  }) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? Color(0xFFe2e6f1) : Color(0xFF8e98be);
    return Stack(
      children: [
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
                    return OttDrawer(selectedOtt: 2);
                  },
                );
                break;
              case 3:
                GoRouter.of(c).push('/downloads');
                break;
              case 4:
                GoRouter.of(c).push('/search/2');
                break;
            }
          },
          child: SizedBox(
            width: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: size),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: color, fontSize: 9)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
