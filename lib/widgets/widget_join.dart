import 'package:flutter/material.dart';

List<Widget> joinWidgets(List<Widget> widgets, Widget seperator) {
  if (widgets.isEmpty) return [];
  List<Widget> joined = [];
  for (int i = 0; i < widgets.length; i++) {
    joined.add(widgets[i]);
    if (i != widgets.length - 1) {
      joined.add(seperator);
    }
  }
  return joined;
}
