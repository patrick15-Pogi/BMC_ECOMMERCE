import 'package:flutter/material.dart';

class BlvkHeader extends StatelessWidget {
  final int cartCount;
  final VoidCallback onCart;
  final VoidCallback onOrders;
  final ValueChanged<String> onSearch;

  const BlvkHeader({
    super.key,
    required this.cartCount,
    required this.onCart,
    required this.onOrders,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        children: [
          const Text(
            'BLVK',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Color(0xFFB5B5B5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: onSearch,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.black54,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 36,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            onPressed: onOrders,
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
            tooltip: 'Orders',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onCart,
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                ),
                tooltip: 'Cart',
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                padding: EdgeInsets.zero,
              ),
              if (cartCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}