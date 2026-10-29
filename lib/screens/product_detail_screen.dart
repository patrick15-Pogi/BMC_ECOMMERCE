
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/blvk_footer.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final void Function(Product product, int quantity, String size) onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String selectedSize = 'Medium';
  int quantity = 1;

  // UI only: shows a bigger, zoomable picture of the product.
  void _openZoom(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      child: Center(
                        child: Image.asset(
                          product.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.checkroom,
                            size: 80,
                            color: Colors.black26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BLVK',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: Color(0xFFB5B5B5),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF111111),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Image.asset(
                              product.imageAsset,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.checkroom,
                                size: 80,
                                color: Colors.black26,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: IconButton(
                          tooltip: 'Zoom',
                          onPressed: () => _openZoom(product),
                          icon: const Icon(Icons.zoom_in),
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                product.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                peso(product.price),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                product.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Size',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Small', 'Medium', 'Large', 'X-Large'].map((size) {
                  return ChoiceChip(
                    label: Text(size),
                    selected: selectedSize == size,
                    onSelected: (_) {
                      setState(() => selectedSize = size);
                    },
                    showCheckmark: false,
                    selectedColor: const Color(0xFF111111),
                    backgroundColor: const Color(0xFF9E9E9E),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: const StadiumBorder(),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),

                  const SizedBox(width: 16),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF111111),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),

                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => quantity++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    widget.onAddToCart(product, quantity, selectedSize);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to your bag.'),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'ADD TO BAG',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                '•  Category: ${product.category}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 28),

              const BlvkFooter(),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
