import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/payment_service.dart';
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

  final PaymentService _paymentService = PaymentService();
  bool _isBuyingNow = false;

  // Buy Now: checkout only this product (selected size + quantity) through
  // the same Supabase `create-invoice` + Xendit flow the cart uses.
  // The cart is not touched.
  Future<void> _buyNow() async {
    if (_isBuyingNow) return;

    setState(() => _isBuyingNow = true);

    try {
      final checkoutUrl = await _paymentService.createCheckout(
        items: [
          <String, dynamic>{
            'product_id': widget.product.id,
            'quantity': quantity,
            'size': selectedSize,
          },
        ],
      );

      await _paymentService.openCheckout(checkoutUrl);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Checkout opened. Payment status will be verified by the server.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $error'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBuyingNow = false);
      }
    }
  }

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
          // Keeps the page nicely centered on wide screens (web / tablet).
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            children: [
              // Square picture box with black border, image centered and fitted.
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
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(
                product.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.5),
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
                    onSelected: (_) => setState(() => selectedSize = size),
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
                      const SnackBar(content: Text('Added to your bag.')),
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
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _isBuyingNow ? null : _buyNow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111111),
                    side: const BorderSide(
                      color: Color(0xFF111111),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isBuyingNow
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF111111),
                          ),
                        )
                      : const Text(
                          'BUY NOW',
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
                style: const TextStyle(fontSize: 12, color: Colors.black54),
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