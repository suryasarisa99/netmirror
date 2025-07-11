import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/api/get_home.dart';
import 'package:netmirror/models/home_models.dart';
import 'package:shared_code/models/ott.dart';

abstract class Home extends StatefulWidget {
  const Home({super.key});
}

abstract class HomeState<T extends HomeModel> extends State<Home> {
  T? data;
  abstract final OTT ott;

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void loadData() async {
    final raw = await getHome(ott: ott);
    final h = HomeModel.parse(raw, ott);
    setState(() {
      data = h as T;
    });
    log("Home data loaded: ${h.trays.length} trays");
  }

  void goToMovie(String id) {
    GoRouter.of(context).push("/movie/${ott.id}/$id");
  }
}
