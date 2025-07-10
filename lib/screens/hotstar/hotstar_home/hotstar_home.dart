import 'package:flutter/material.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';

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
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text("Hotstar Home"),
              backgroundColor: Colors.black,
              expandedHeight: 200,
            ),
          ],
        ),
      ),
    );
  }
}
