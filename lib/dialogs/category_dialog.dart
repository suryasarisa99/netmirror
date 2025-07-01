import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netmirror/constants.dart';
import 'package:netmirror/widgets/windows_titlebar_widgets.dart';

class CategoryPopupScreen extends StatelessWidget {
  const CategoryPopupScreen({
    super.key,
    required this.getText,
    required this.handleClick,
    required this.items,
    this.selected = -1,
  });

  final String Function(dynamic) getText;
  final void Function(int) handleClick;
  final List<dynamic> items;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bodyHeight =
        size.height - (isDesk ? kToolbarHeight : statusBarHeight);
    const style = TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w300,
      color: Colors.white70,
    );
    const hStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 25,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Column(
            children: [
              Container(color: Colors.black, child: windowDragArea()),
              // Container(height: statusBarHeight, color: Colors.black),
              Container(
                height: bodyHeight,
                alignment: const Alignment(0, 0),
                color: Colors.black.withValues(alpha: 0.78),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pop();
                          handleClick(i);
                        },
                        child: Text(
                          getText(item),
                          textAlign: TextAlign.center,
                          style: i == selected ? hStyle : style,
                        ),
                      ),
                    );
                  },
                  itemCount: items.length,
                  padding: const EdgeInsets.only(top: 100, bottom: 120),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.1), Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              alignment: const Alignment(0, 0.83),
              child: GestureDetector(
                onTap: () {
                  GoRouter.of(context).pop();
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 35,
                  child: Icon(Icons.close, size: 30, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
