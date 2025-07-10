import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DesktopWrapper extends StatefulWidget {
  final Widget child;

  const DesktopWrapper({required this.child, super.key});

  @override
  State<DesktopWrapper> createState() => _DesktopWrapperState();
}

class _DesktopWrapperState extends State<DesktopWrapper> {
  late final FocusScopeNode focusScope;
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusScope = FocusScopeNode();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    focusScope.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: focusScope,
      autofocus: true,
      canRequestFocus: true,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          focusNode.requestFocus();
        }
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
          child: widget.child,
        ),
      ),
    );
  }
}
