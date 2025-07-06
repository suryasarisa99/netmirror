import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:html/parser.dart';

class PvHomeModel {
  final List<PvHomeCarousel> carouselImgs;
  final List<PvHomeTray> trays;
  final DateTime lastUpdated;

  PvHomeModel({
    required this.carouselImgs,
    required this.trays,
    required this.lastUpdated,
  });

  factory PvHomeModel.parse(String raw) {
    final document = parse(raw);

    final carousels = document.querySelectorAll(".spotlight").map((splotlight) {
      final postId = splotlight.parent!.attributes["onclick"]!.split("'")[1];
      final img =
          splotlight.querySelector("img.slider-img")!.attributes["src"]!;
      return PvHomeCarousel(img: img, id: postId);
    });

    log("images: len: ${carousels.length}");
    final trayElements = document.querySelectorAll(".tray-container, .top10");
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

      return PvHomeTray(isTop10: isTop10, title: title, postIds: x.toList());
    });

    return PvHomeModel(
      carouselImgs: carousels.toList(),
      trays: trays.toList(),
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "carouselImgs": carouselImgs.map((e) => e.toJson()).toList(),
      "trays": trays.map((e) => e.toJson()).toList(),
      "lastUpdated": lastUpdated.toIso8601String(),
    };
  }

  factory PvHomeModel.fromJson(Map<String, dynamic> json) {
    return PvHomeModel(
      carouselImgs: List<PvHomeCarousel>.from(
          json["carouselImgs"].map((x) => PvHomeCarousel.fromJson(x))),
      trays: List<PvHomeTray>.from(
          json["trays"].map((x) => PvHomeTray.fromJson(x))),
      lastUpdated: DateTime.parse(json["lastUpdated"]),
    );
  }

  // stale means data is old
  bool get isStale {
    return DateTime.now().difference(lastUpdated).inHours > 24;
  }

  bool get isFresh => !isStale;
}

class NfHomeModel {
  final String spotlightId;
  final List<String> genre;
  final Color gradientColor;
  final List<PvHomeTray> trays;
  final DateTime lastUpdated;

  NfHomeModel({
    required this.spotlightId,
    required this.genre,
    required this.gradientColor,
    required this.trays,
    required this.lastUpdated,
  });

  factory NfHomeModel.parse(String raw) {
    final document = parse(raw);

    // <div
    //     class="spotlight"
    //     style="
    //       background-image: url('https://imgcdn.media/poster/c/16539454.jpg');
    //       background: linear-gradient(#9f2a37 74%, #5757574f);
    //       margin-bottom: 0px;
    //       height: 83vh;
    //     "
    //   >

    final spotlight = document.querySelector(".spotlight");
    final style = spotlight?.attributes['style'] ?? '';
    final gradientColor = RegExp(r'linear-gradient\((#[0-9a-fA-F]+)')
            .firstMatch(style)
            ?.group(1) ??
        '#000000';
    // get color from #color string
    print("color str: $gradientColor");
    Color color =
        Color(int.parse('FF${gradientColor.substring(1)}', radix: 16));
    final hsl = HSLColor.fromColor(color);
    log("current saturation: ${hsl.saturation}");
    color = hsl.withLightness(0.3).toColor();

    // color = Color.fromRGBO(61, 98, 112, 1);
    // Color.fromARGB(255, 61, 98, 112);
    print("color val: ${color.value}");
    final genre = spotlight!.querySelector(".genre")!.text.split("•");

    final id = spotlight.querySelector(".btn-play")!.attributes["data-post"];

    // extra  gradient

    final trayElements = document.querySelectorAll(".tray-container, .top10");
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

      return PvHomeTray(isTop10: isTop10, title: title, postIds: x.toList());
    });

    return NfHomeModel(
      spotlightId: id!,
      genre: genre,
      gradientColor: color,
      trays: trays.toList(),
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "spotlightId": spotlightId,
      "genre": genre,
      "gradientColor": gradientColor.value,
      "trays": trays.map((e) => e.toJson()).toList(),
      "lastUpdated": lastUpdated.toIso8601String(),
    };
  }

  factory NfHomeModel.fromJson(Map<String, dynamic> json) {
    return NfHomeModel(
      spotlightId: json["spotlightId"],
      genre: List<String>.from(json["genre"]),
      gradientColor: Color(json["gradientColor"]),
      trays: List<PvHomeTray>.from(
          json["trays"].map((x) => PvHomeTray.fromJson(x))),
      lastUpdated: DateTime.parse(json["lastUpdated"]),
    );
  }

  // stale means data is old
  bool get isStale {
    return DateTime.now().difference(lastUpdated).inHours > 24;
  }

  bool get isFresh => !isStale;
}

class PvHomeCarousel {
  final String img;
  final String id;

  PvHomeCarousel({required this.img, required this.id});

  Map<String, dynamic> toJson() {
    return {
      "img": img,
      "id": id,
    };
  }

  factory PvHomeCarousel.fromJson(Map<String, dynamic> json) {
    return PvHomeCarousel(img: json["img"], id: json["id"]);
  }
}

class PvHomeTray {
  final bool isTop10;
  final String title;
  final List<String> postIds;

  PvHomeTray(
      {required this.isTop10, required this.title, required this.postIds});

  Map<String, dynamic> toJson() {
    return {
      "isTop10": isTop10,
      "title": title,
      "postIds": postIds,
    };
  }

  factory PvHomeTray.fromJson(Map<String, dynamic> json) {
    return PvHomeTray(
      isTop10: json["isTop10"],
      title: json["title"],
      postIds: List<String>.from(json["postIds"]),
    );
  }
}
