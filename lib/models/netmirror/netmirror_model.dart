import 'package:netmirror/constants.dart';

enum OTT {
  // none("", name: "Netflix"),
  // pv("pv", name: "Prime Video"),
  // dh("dh", name: "Disney + Hotstar"),
  // lionGate("lg", name: "Lionsgate"),
  // hbo("hbo", name: "HBO");

  none(
    "",
    name: "Netflix",
    vImgHeight: 233,
    vImgWidth: 166,
    hImgHeight: 374,
    hImgWidth: 665,
  ),
  pv("pv",
      name: "Prime Video",
      vImgHeight: 0,
      vImgWidth: 0,
      hImgHeight: 0,
      hImgWidth: 0),
  dh("dh",
      name: "Disney + Hotstar",
      vImgHeight: 0,
      vImgWidth: 0,
      hImgHeight: 0,
      hImgWidth: 0),
  lionGate("lg",
      name: "Lionsgate",
      vImgHeight: 0,
      vImgWidth: 0,
      hImgHeight: 0,
      hImgWidth: 0),
  hbo("hbo",
      name: "HBO", vImgHeight: 0, vImgWidth: 0, hImgHeight: 0, hImgWidth: 0);

  final String value;
  final String name;
  final double vImgHeight;
  final double vImgWidth;
  final double hImgHeight;
  final double hImgWidth;
  final double vAspectRatio;
  final double hAspectRatio;

  const OTT(
    this.value, {
    this.name = '',
    required this.vImgHeight,
    required this.vImgWidth,
    required this.hImgHeight,
    required this.hImgWidth,
    // required this.vImgRatio = hImgHeight / hImgWidth,
  })  : vAspectRatio = vImgWidth / vImgHeight,
        hAspectRatio = hImgWidth / hImgHeight;

  get url => value.isEmpty ? '' : '$value/';

  get aspectRatio => isDesk ? hAspectRatio : vAspectRatio;

  get cookie => value.isEmpty ? 'nf' : value;

  String getImg(
    String id, {
    bool largeImg = false,
    bool forceHorizontal = false,
    bool forceVertical = false,
  }) {
    if (this == OTT.none) {
      late String direction;

      if (forceHorizontal) {
        direction = "341";
      } else if (forceVertical) {
        direction = "v";
      } else {
        direction = isDesk ? "341" : "v";
      }

      return "https://imgcdn.media/poster/$direction/$id.jpg";
    }
    return "https://imgcdn.media/$url${largeImg ? 700 : 341}/$id.jpg";
    // return "https://imgcdn.media/$url/c/$id.jpg";   //pv moviescreen poster
  }

  factory OTT.fromValue(String value) {
    return OTT.values.firstWhere((element) => element.value == value);
  }
}

class NmSearchResults {
  final List<NmSearchResult> results;
  final OTT ott;
  final String query;
  final String error;

  NmSearchResults(
      {required this.results,
      required this.ott,
      required this.query,
      required this.error});

  factory NmSearchResults.fromJson(
      Map<String, dynamic> json, OTT ott, String query) {
    return NmSearchResults(
      // ott: OTT.fromValue(json['ott']),
      query: query,
      ott: ott,
      results: json['searchResult'] == null
          ? []
          : (json['searchResult'] as List)
              .map((e) => NmSearchResult.fromJson(e))
              .toList(),
      error: json['error'],
    );
  }
}

class NmSearchResult {
  final String id;
  final String t;
  final String? y;
  final String? r;

  NmSearchResult({
    required this.id,
    required this.t,
    required this.y,
    required this.r,
  });

  factory NmSearchResult.fromJson(Map<String, dynamic> json) {
    return NmSearchResult(
      id: json['id'],
      t: json['t'],
      y: json['y'],
      r: json['r'],
    );
  }
}
