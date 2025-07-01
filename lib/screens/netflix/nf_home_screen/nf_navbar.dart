import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:netmirror/widgets/ott_drawer.dart';

class _CustomNavItem {
  const _CustomNavItem({
    required this.icon,
    required this.uIcon,
    required this.label,
  });

  final Widget icon;
  final Widget uIcon;
  final String label;
}

class NfNavBar extends StatelessWidget {
  const NfNavBar({super.key, required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const sClr = Colors.white;
    const usClr = Colors.white60;

    final imgWidget = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.asset(
        "assets/logos/netflix-profile-logo.png",
        height: 20,
        width: 20,
      ),
    );

    final items = [
      const _CustomNavItem(
          icon: Icon(Icons.home, color: Colors.white),
          uIcon: Icon(Icons.home_outlined, color: usClr),
          label: "Home"),
      const _CustomNavItem(
          uIcon: Icon(HugeIcons.strokeRoundedMenuSquare, color: usClr),
          // icon: Icon(
          //   HugeIcons.strokeRoundedGameController03,
          //   color: Colors.white,
          // ),
          icon: Icon(HugeIcons.strokeRoundedGameController03, color: usClr),
          label: "OTT"),
      const _CustomNavItem(
          icon: Icon(CupertinoIcons.add, color: Colors.white),
          uIcon: Icon(Icons.search, color: usClr),
          label: "New & Hot"),
      _CustomNavItem(
          icon: Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.white),
                  borderRadius: BorderRadius.circular(3)),
              child: imgWidget),
          uIcon: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: imgWidget,
          ),
          label: "My Profile"),
      //     label: "New & Hot"),
      // CustomNavItem(
      //     icon: Icon(Icons.home, color: Colors.white),
      //     uIcon: Icon(Icons.home, color: usClr),
      //     label: "My Profile"),
    ];

    return Container(
      color: Colors.black.withOpacity(0.6),
      height: 55,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.mapIndexed((i, item) {
          final isSelected = i == current;
          return IconButton(
            onPressed: () {
              if (i == 0 && current != 0) {
                GoRouter.of(context).push("/");
              } else if (i == 1) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return OttDrawer(selectedOtt: 0);
                  },
                );
              } else if (i == 3 && current != 3) {
                GoRouter.of(context).push("/profile");
              } else if (i == 2) {
                GoRouter.of(context).push("/search", extra: 0);
              }
            },
            icon: Column(
              children: [
                isSelected ? item.icon : item.uIcon,
                const SizedBox(
                  height: 0,
                ),
                Text(item.label,
                    style: TextStyle(
                        fontSize: 9, color: isSelected ? sClr : usClr))
              ],
            ),
          );
        }).toList(),
      ),
    );

    // return Row(
    //   children: [
    //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    //     BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: "Games"),
    //     BottomNavigationBarItem(icon: Icon(Icons.video_settings), label: "Hot"),
    //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "My Profile"),
    //   ],
    //   currentIndex: 0,
    //   unselectedIconTheme: IconThemeData(color: Colors.white60),
    //   selectedIconTheme: IconThemeData(color: Colors.white),
    //   selectedItemColor: Colors.white,
    //   unselectedItemColor: Colors.white60,
    //   unselectedLabelStyle: TextStyle(color: Colors.white),
    // );
  }
}
