import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const categories = [
    'All',
    'T-Shirt',
    'Hoodie',
    'Shorts',
    'Pants',
  ];

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder + minWidth keeps the pills centered on wide screens,
    // and the horizontal scroll prevents overflow on small phones.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _CategoryPill(
                      label: category,
                      active: selected == category,
                      onTap: () => onSelected(category),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active ? const Color(0xFF111111) : const Color(0xFF3A3A3A),
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF111111) : const Color(0xFFD0D0D0),
          ),
        ),
      ],
    );
  }
}