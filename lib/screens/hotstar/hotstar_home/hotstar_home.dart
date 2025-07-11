import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:html/parser.dart';
import 'package:lottie/lottie.dart';
import 'package:netmirror/api/get_initial.dart';
import 'package:netmirror/log.dart';
import 'package:netmirror/models/home_models.dart';
import 'package:netmirror/screens/hotstar/hotstar_button.dart';
import 'package:netmirror/screens/hotstar/hotstar_navbar.dart';
import 'package:netmirror/widgets/desktop_wrapper.dart';
import 'package:shared_code/models/ott.dart';

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
  HotstarModel? data;
  final ott = OTT.hotstar;
  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final str = await getHotstar();
    final h = HotstarModel.parse(str);
    setState(() {
      data = h;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return DesktopWrapper(
      child: Scaffold(
        backgroundColor: Color(0xFF0f1014),
        body: data == null
            ? Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        buildPoster(),
                        SizedBox(height: 8),
                        HotstarButton(text: "Watch Now", onPressed: () {}),
                        SizedBox(height: 16),
                        buildRows(data!.trays),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildPoster() {
    final size = MediaQuery.sizeOf(context);
    final clr = Color(0xFF0f1014);
    return SizedBox(
      height: size.width / 1.778 + 10,
      child: Stack(
        children: [
          Positioned(
            child: Image.network(
              data?.spotlightImg ?? "",
              fit: BoxFit.cover,
              // height: 200,
              width: size.width,
              height: size.width / 1.778 - 30,
              alignment: Alignment(0, -1),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, clr, clr],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: size.width / 2 - 80,
            right: size.width / 2 - 80,
            child: Image.network(data!.titleImg, width: 160),
          ),
        ],
      ),
    );
  }

  Widget buildRows(List<HomeTray> trays) {
    return Column(
      children: trays.map((tray) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: buildRow(tray),
        );
      }).toList(),
    );
  }

  Widget buildRow(HomeTray tray) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            tray.title,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              SizedBox(width: 8),
              ...tray.postIds.map((id) {
                return InkWell(
                  onTap: () {
                    GoRouter.of(context).push("/movie/${ott.id}/$id");
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      ott.getImg(id),
                      width: 150 * ott.aspectRatio,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
