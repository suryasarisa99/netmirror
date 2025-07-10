import 'package:flutter/material.dart';
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

class _HotstarHomeState extends State<HotstarHome> {
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
          ],
        ),
      ),
    );
  }
}
