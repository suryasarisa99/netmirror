import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:netmirror/api/get_initial.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/home_models.dart';
import 'package:netmirror/screens/hotstar/hotstar_navbar.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';

class HotstarMain extends StatelessWidget {
  final Widget shell;

  const HotstarMain(this.shell, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: HotstarNavbar(
        selectedIndex: 0,
        onItemSelected: (_) {},
      ),
      body: shell,
    );
  }
}

class HotstarHome extends StatefulWidget {
  const HotstarHome({super.key});

  @override
  State<HotstarHome> createState() => _HotstarHomeState();
}

const l = L("hotstar_home");

class _HotstarHomeState extends State<HotstarHome> {
  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final str = await getHotstar();
    try {
      final document = parse(str);
      final trayElements = document.querySelectorAll(".tray-container, .top10");
      l.debug("trayElements len: ${trayElements.length}");
      final trays = trayElements.map((tray) {
        bool isTop10 = tray.className == "top10";
        String title;
        if (isTop10) {
          title = tray.querySelector("span")!.text;
        } else {
          title = tray.querySelector(".tray-link")!.text;
        }

        var x = tray
            .querySelectorAll("[data-post]")
            .map((post) => post.attributes["data-post"] as String);

        return HomeTray(isTop10: isTop10, title: title, postIds: x.toList());
      });
      l.debug("trays len: ${trays.length}");
    } catch (e) {
      l.error("Error parsing Hotstar home data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopWrapper(
      child: Scaffold(
        // backgroundColor: Color(0xFF0f1014),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text("Hotstar Home"),
              expandedHeight: 200,
            ),
            SliverToBoxAdapter(
              child: FilledButton(
                onPressed: () {
                  loadData();
                },
                child: Text("Load Data"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
