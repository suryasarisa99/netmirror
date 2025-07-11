import 'package:flutter/material.dart';

class HotstarButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const HotstarButton({required this.text, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
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
            height: 34,
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
