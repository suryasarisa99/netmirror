import 'package:better_player_plus/src/models/constants.dart';

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
