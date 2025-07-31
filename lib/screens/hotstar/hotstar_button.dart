import 'package:flutter/material.dart';

class HotstarButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final double height;
  const HotstarButton({
    this.child,
    this.text,
    this.height = 40,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      text != null || child != null,
      "Either text or child must be provided",
    );
    assert(text == null || child == null, "Cannot provide both text and child");

    return Container(
      width: 170,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1491FF),
            Color(0xFF155BBD),
            Color(0xFF67379D),
            Color(0xFFDB0765),
          ],
          // stops: [0.6, 0.8, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            height: height,
            alignment: Alignment.center,
            child: text != null
                ? Text(
                    text!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : child!,
          ),
        ),
      ),
    );
  }
}
