import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/payment_service.dart';

class CartScreen extends StatefulWidget {
  final Map<int, CartItem> cart;
  final void Function(int productId, int quantity) onQuantityChanged;
  final void Function(int productId) onRemove;
  final void Function(ShopOrder order) onCheckout;

  const CartScreen({
    super.key,
    required this.cart,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onCheckout,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isCheckingOut = false;

  int get total => widget.cart.values.fold(
        0,
        (sum, item) => sum + item.subtotal,
      );

  Future<void> _checkout(List<CartItem> items) async {
    if (_isCheckingOut || items.isEmpty) return;

    setState(() => _isCheckingOut = true);

    try {
      final checkoutUrl = await _paymentService.createCheckout(
        items: items.map((item) {
          return <String, dynamic>{
            'product_id': item.product.id,
            'quantity': item.quantity,
            'size': item.size,
          };
        }).toList(),
      );

      await _paymentService.openCheckout(checkoutUrl);

      if (!mounted) return;

      final order = ShopOrder(
        reference: 'BLVK-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        items: items.map((item) {
          return OrderItem(
            name: item.product.name,
            price: item.product.price,
            quantity: item.quantity,
            size: item.size,
          );
        }).toList(),
        total: total,
      );

      widget.onCheckout(order);
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
        setState(() => _isCheckingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cart.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('YOUR BAG')),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 58),
                  SizedBox(height: 12),
                  Text('Your bag is empty.'),
                ],
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                // Keeps the cart centered on wide screens.
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 28,
                          color: Colors.black12,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final product = item.product;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bordered box, image centered and fitted.
                              Container(
                                width: 100,
                                height: 120,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFF111111),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    product.imageAsset,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.checkroom,
                                      color: Colors.black26,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Size: ${item.size}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      peso(product.price),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          visualDensity:
                                              VisualDensity.compact,
                                          onPressed: item.quantity > 1
                                              ? () => widget.onQuantityChanged(
                                                    product.id,
                                                    item.quantity - 1,
                                                  )
                                              : null,
                                          icon: const Icon(Icons.remove),
                                        ),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          visualDensity:
                                              VisualDensity.compact,
                                          onPressed: () =>
                                              widget.onQuantityChanged(
                                            product.id,
                                            item.quantity + 1,
                                          ),
                                          icon: const Icon(Icons.add),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          visualDensity:
                                              VisualDensity.compact,
                                          onPressed: () =>
                                              widget.onRemove(product.id),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Subtotal: ${peso(item.subtotal)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFF111111), width: 1.5),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  peso(total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: _isCheckingOut
                                    ? null
                                    : () => _checkout(items),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF111111),
                                  foregroundColor: Colors.white,
                                  // Keep the button black while loading.
                                  disabledBackgroundColor:
                                      const Color(0xFF111111),
                                  disabledForegroundColor: Colors.white,
                                ),
                                child: _isCheckingOut
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'PROCEED TO PAYMENT',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Secure checkout powered by Xendit.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}