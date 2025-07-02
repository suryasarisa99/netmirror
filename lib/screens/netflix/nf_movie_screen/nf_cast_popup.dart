import 'package:flutter/material.dart';
import 'package:netmirror/models/netmirror/nm_movie_model.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';

class NfCastPopupScreen extends StatelessWidget {
  final Movie _movie;

  const NfCastPopupScreen(this._movie, {super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bodyHeight = size.height - statusBarHeight;
    const style = TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w300,
      color: Colors.white70,
    );

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          windowDragArea(),
          Container(height: statusBarHeight, color: Colors.black),
          Container(
            height: bodyHeight,
            alignment: const Alignment(0, 0),
            color: Colors.black.withOpacity(0.78),
            child: ListView.builder(
              shrinkWrap: true,
              // itemCount: cast?.actors.length,
              padding: const EdgeInsets.only(top: 100, bottom: 120),
              itemBuilder: (context, i) {
                // final item = cast?.actors[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.of(context).pop();
                      // GoRouter.of(context).push("/",
                      //     extra: (3, "Person-${item!.personId}", item.title));
                    },
                    child: const Text(
                      "Empty",
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
