import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:shared_code/models/ott.dart';

abstract class HomeModel {
  final List<HomeTray> trays;
  final DateTime lastUpdated;

  static HomeModel parse(String raw, OTT ott) {
    switch (ott) {
      case OTT.hotstar:
        return HotstarModel.parse(raw);
      case OTT.netflix:
        return NfHomeModel.parse(raw);
      case OTT.pv:
        return PvHomeModel.parse(raw);
      default:
        throw UnimplementedError('Parser not implemented for ${ott.name}');
    }
  }

  HomeModel({required this.trays, required this.lastUpdated});

  static List<HomeTray> traysFromJson(Map<String, dynamic> json) {
    return List<HomeTray>.from(json["trays"].map((x) => HomeTray.fromJson(x)));
  }

  static List<HomeTray> parseTrays(Document document) {
    final trayElements = document.querySelectorAll(".tray-container, .top10");
    return trayElements.map((tray) {
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
    }).toList();
  }

  // Instance Methods

  List<Map<String, dynamic>> get traysToJson {
    return trays.map((tray) => tray.toJson()).toList();
  }

  Map<String, dynamic> toJson() {
    return {"trays": traysToJson, "lastUpdated": lastUpdated.toIso8601String()};
  }

  // stale means data is old
  bool get isStale {
    return DateTime.now().difference(lastUpdated).inHours > 24;
  }

  bool get isFresh => !isStale;
}

class HomeTray {
  final bool isTop10;
  final String title;
  final List<String> postIds;

  HomeTray({required this.isTop10, required this.title, required this.postIds});

  Map<String, dynamic> toJson() {
    return {"isTop10": isTop10, "title": title, "postIds": postIds};
  }

  factory HomeTray.fromJson(Map<String, dynamic> json) {
    return HomeTray(
      isTop10: json["isTop10"],
      title: json["title"],
      postIds: List<String>.from(json["postIds"]),
    );
  }
}

class PvHomeModel extends HomeModel {
  final List<PvHomeCarousel> carouselImages;

  PvHomeModel({
    required this.carouselImages,
    required super.trays,
    required super.lastUpdated,
  });

  factory PvHomeModel.parse(String raw) {
    final document = parse(raw);

    final carousels = document.querySelectorAll(".spotlight").map((spotlight) {
      final postId = spotlight.parent!.attributes["onclick"]!.split("'")[1];
      final img = spotlight.querySelector("img.slider-img")!.attributes["src"]!;
      return PvHomeCarousel(img: img, id: postId);
    });

    log("images: len: ${carousels.length}");
    final trays = HomeModel.parseTrays(document);
    return PvHomeModel(
      carouselImages: carousels.toList(),
      trays: trays,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "carouselImages": carouselImages.map((e) => e.toJson()).toList(),
    };
  }

  factory PvHomeModel.fromJson(Map<String, dynamic> json) {
    return PvHomeModel(
      carouselImages: List<PvHomeCarousel>.from(
        json["carouselImages"].map((x) => PvHomeCarousel.fromJson(x)),
      ),
      trays: HomeModel.traysFromJson(json),
      lastUpdated: DateTime.parse(json["lastUpdated"]),
    );
  }
}

class NfHomeModel extends HomeModel {
  final String spotlightId;
  final List<String> genre;
  final Color gradientColor;

  NfHomeModel({
    required this.spotlightId,
    required this.genre,
    required this.gradientColor,
    required super.trays,
    required super.lastUpdated,
  });

  @override
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
    final gradientColor =
        RegExp(
          r'linear-gradient\((#[0-9a-fA-F]+)',
        ).firstMatch(style)?.group(1) ??
        '#000000';
    // get color from #color string
    debugPrint("color str: $gradientColor");
    Color color = Color(
      int.parse('FF${gradientColor.substring(1)}', radix: 16),
    );
    final hsl = HSLColor.fromColor(color);
    log("current saturation: ${hsl.saturation}");
    color = hsl.withLightness(0.3).toColor();

    // color = Color.fromRGBO(61, 98, 112, 1);
    // Color.fromARGB(255, 61, 98, 112);
    debugPrint("color val: ${color.toString()}");
    final genre = spotlight!.querySelector(".genre")!.text.split("•");

    final id = spotlight.querySelector(".btn-play")!.attributes["data-post"];

    return NfHomeModel(
      spotlightId: id!,
      genre: genre,
      gradientColor: color,
      trays: HomeModel.parseTrays(document),
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "spotlightId": spotlightId,
      "genre": genre,
      "gradientColor": gradientColor.toString(),
    };
  }

  factory NfHomeModel.fromJson(Map<String, dynamic> json) {
    return NfHomeModel(
      spotlightId: json["spotlightId"],
      genre: List<String>.from(json["genre"]),
      gradientColor: Color(json["gradientColor"]),
      trays: HomeModel.traysFromJson(json),
      lastUpdated: DateTime.parse(json["lastUpdated"]),
    );
  }
}

class PvHomeCarousel {
  final String img;
  final String id;

  PvHomeCarousel({required this.img, required this.id});

  Map<String, dynamic> toJson() {
    return {"img": img, "id": id};
  }

  factory PvHomeCarousel.fromJson(Map<String, dynamic> json) {
    return PvHomeCarousel(img: json["img"], id: json["id"]);
  }
}

class HotstarModel extends HomeModel {
  final List<HotstarStudio> studios;
  final String spotlightImg;
  final String titleImg;

  HotstarModel({
    required this.studios,
    required this.spotlightImg,
    required this.titleImg,
    required super.trays,
    required super.lastUpdated,
  });

  factory HotstarModel.parse(String raw) {
    final document = parse(raw);

    final studios = document.querySelectorAll(".ott-studio").map((studio) {
      final img = studio.querySelector("img");

      return HotstarStudio(
        studio: studio.attributes["data-studio"] ?? "Unknown",
        logoUrl: img?.attributes["src"] ?? "",
        name: studio.attributes["data-studio"] ?? "Unknown",
      );
    });
    final spotlight = document.querySelector(".spotlight-hs")!;
    final style = spotlight.attributes['style']!;
    final backgroundImageMatch = RegExp(
      r"""background-image:\s*url\(["\']?([^"\']+)["\']?\)""",
    ).firstMatch(style);
    final titleImg =
        spotlight.querySelector("img.img-title")?.attributes["src"] ?? "";
    log("bg: ${backgroundImageMatch?.group(1)}");

    log("images: len: ${studios.length}");
    final trays = HomeModel.parseTrays(document);
    return HotstarModel(
      studios: studios.toList(),
      spotlightImg: backgroundImageMatch?.group(1) ?? "",
      titleImg: titleImg,
      trays: trays,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "spotlightImg": spotlightImg,
      "studios": studios.map((e) => e.toJson()).toList(),
      "titleImg": titleImg,
    };
  }

  factory HotstarModel.fromJson(Map<String, dynamic> json) {
    return HotstarModel(
      spotlightImg: json["spotlightImg"],
      studios: List<HotstarStudio>.from(
        json["studios"].map((x) => HotstarStudio.fromJson(x)),
      ),
      trays: HomeModel.traysFromJson(json),
      lastUpdated: DateTime.parse(json["lastUpdated"]),
      titleImg: json["titleImg"],
    );
  }
}

class HotstarStudio {
  final String name;
  final String studio;
  final String logoUrl;

  HotstarStudio({
    required this.name,
    required this.studio,
    required this.logoUrl,
  });

  Map<String, dynamic> toJson() {
    return {"name": name, "logoUrl": logoUrl, "studio": studio};
  }

  factory HotstarStudio.fromJson(Map<String, dynamic> json) {
    return HotstarStudio(
      name: json["name"],
      studio: json["studio"],
      logoUrl: json["logoUrl"],
    );
  }
}
