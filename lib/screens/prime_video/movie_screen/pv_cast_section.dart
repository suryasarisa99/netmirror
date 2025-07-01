import 'package:flutter/material.dart';

class CastSection extends StatelessWidget {
  final String title;
  final String value;

  const CastSection(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 22),
        //horizontal line
        const Divider(
          height: 1,
          color: Colors.white24,
        )
      ],
    );
  }
}
