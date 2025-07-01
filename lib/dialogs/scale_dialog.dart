import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ScaleDialog extends StatefulWidget {
  const ScaleDialog({
    super.key,
    required this.onScale,
    required this.scale,
  });
  final void Function(double, double) onScale;
  final Size scale;

  @override
  State<ScaleDialog> createState() => _ScaleDialogState();
}

class _ScaleDialogState extends State<ScaleDialog> {
  final widthC = TextEditingController();
  final heightC = TextEditingController();
  final singleC = TextEditingController();
  var isHeightAndWidthEqual = true;

  @override
  void initState() {
    super.initState();
    widthC.text = widget.scale.width.toString();
    heightC.text = widget.scale.height.toString();
    if (widget.scale.width != widget.scale.height) {
      setState(() {
        isHeightAndWidthEqual = false;
      });
    } else {
      singleC.text = widget.scale.height.toString();
    }
  }

  Widget _buildInput(TextEditingController c, String x) {
    return SizedBox(
      width: x == "" ? 160 : 80,
      child: CupertinoTextField(
        placeholder: "Scale $x",
        controller: c,
        keyboardType: TextInputType.number,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color.fromARGB(255, 46, 46, 46),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: isHeightAndWidthEqual
                    ? [_buildInput(singleC, "")]
                    : [
                        Expanded(child: _buildInput(widthC, "X")),
                        const SizedBox(width: 8),
                        _buildInput(heightC, "Y")
                      ]),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      isHeightAndWidthEqual = !isHeightAndWidthEqual;
                    });
                  },
                  icon: Icon(
                    isHeightAndWidthEqual
                        ? HugeIcons.strokeRoundedEqualSign
                        : HugeIcons.strokeRoundedNotEqualSign,
                    size: 18,
                  ),
                ),
                IconButton(
                    onPressed: () {
                      heightC.text = "1";
                      widthC.text = "1";
                      singleC.text = "1";
                      widget.onScale(1, 1);
                    },
                    icon: const Icon(Icons.restore)),
                const SizedBox(width: 8),
                SizedBox(
                  height: 30,
                  child: FilledButton(
                      onPressed: () {
                        if (isHeightAndWidthEqual) {
                          final value = double.parse(singleC.text);
                          widget.onScale(value, value);
                        } else {
                          final x = double.parse(widthC.text);
                          final y = double.parse(heightC.text);
                          widget.onScale(x, y);
                        }
                      },
                      style: ButtonStyle(
                          backgroundColor:
                              const WidgetStatePropertyAll(Colors.white),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                          padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(vertical: 0))),
                      child: const Text("Set")),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Usage example
// void showPopup(BuildContext context
