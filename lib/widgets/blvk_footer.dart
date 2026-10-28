import 'package:flutter/material.dart';

class BlvkFooter extends StatelessWidget {
  const BlvkFooter({super.key});

  Widget _icon(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _icon(Icons.facebook),
            _icon(Icons.music_note),
            _icon(Icons.camera_alt_outlined),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'BLVK — DEFINE YOUR OWN STANDARD',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.black45,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}