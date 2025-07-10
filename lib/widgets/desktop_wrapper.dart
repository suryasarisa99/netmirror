import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DesktopWrapper extends StatelessWidget {
  final Widget child;
  final focusScope = FocusScopeNode();
  final focusNode = FocusNode();
  DesktopWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: focusScope,
      autofocus: true,
      canRequestFocus: true,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          focusNode.requestFocus();
        } else {}
      },
      child: CallbackShortcuts(
        bindings: {
          LogicalKeySet(LogicalKeyboardKey.escape): () {
            GoRouter.of(context).pop();
          },
          LogicalKeySet(
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.arrowLeft,
          ): () {
            GoRouter.of(context).pop();
          },
        },
        child: Focus(
          focusNode: focusNode,
          canRequestFocus: true,
          autofocus: true,
          skipTraversal: true,
          child: child,
        ),
      ),
    );
  }
}
