import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/data/options.dart';

class OTTModel {
  final String name;
  final String image;
  final String route;
  const OTTModel({
    required this.name,
    required this.image,
    required this.route,
  });
}

const ottList = [
  OTTModel(
    name: "Netflix",
    image: "assets/ott-list/nf.webp",
    route: "/nf-home",
  ),
  OTTModel(
    name: "Prime Video",
    image: "assets/ott-list/pv.jpg",
    route: "/pv-home",
  ),
  OTTModel(
    name: "Jio Hotstar",
    image: "assets/ott-list/jio-hotstar.jpg",
    route: "/hotstar-home",
  ),
];

class OttDrawer extends StatelessWidget {
  final selectedOtt;
  OttDrawer({super.key, this.selectedOtt = 0});

  final controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    //  dragableScrollableSheet
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, x) {
        return Container(
          color: Colors.black,
          child: NotificationListener(
            // onNotification: (notificaion) {
            // if (notificaion is ScrollMetricsNotification) {
            // setState(() {
            //   isExpanded = scrollController.offset > 0;
            // });
            // }
            // return true;
            // },
            child: GridView.builder(
              itemCount: ottList.length,
              controller: x,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    // close the bottom sheet
                    Navigator.of(context).pop();
                    if (selectedOtt != index) {
                      SettingsOptions.currentScreen = ottList[index].route;
                      GoRouter.of(context).go(ottList[index].route);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedOtt == index
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        ottList[index].image,

                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
