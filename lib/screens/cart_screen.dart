import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../screens/customer_info_screen.dart';
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
  static const int maxQuantity = 10;


  final PaymentService _paymentService = PaymentService();
  bool _isCheckingOut = false;


  int get total => widget.cart.values.fold(
        0,
        (sum, item) => sum + item.subtotal,
      );


  void _changeQuantity(int productId, int quantity) {
    final limitedQuantity = quantity.clamp(1, maxQuantity);


    widget.onQuantityChanged(productId, limitedQuantity);
    setState(() {});
  }


  void _removeItem(int productId) {
    widget.onRemove(productId);
    setState(() {});
  }


  Future<void> _checkout(List<CartItem> items) async {
    if (_isCheckingOut || items.isEmpty) return;


    setState(() => _isCheckingOut = true);


    try {
      final customerResult =
          await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => const CustomerInfoScreen(),
        ),
      );


      if (!mounted) return;
      if (customerResult == null) return;


      if (items.isEmpty) {
        throw Exception('Your bag is empty.');
      }


      final itemsPayload = items.map((item) {
        return <String, dynamic>{
          'product_id': item.product.id,
          'quantity': item.quantity.clamp(1, maxQuantity),
          'size': item.size,
        };
      }).toList();


      final response =
          await Supabase.instance.client.functions.invoke(
        'create-invoice',
        body: {
          'items': itemsPayload,
          'customer': customerResult,
        },
      );


      debugPrint('BLVK checkout response: ${response.data}');


      if (response.data is! Map) {
        throw Exception('Invalid response from payment server.');
      }


      final result = Map<String, dynamic>.from(
        response.data as Map,
      );


      if (result['error'] != null) {
        throw Exception(result['error'].toString());
      }


      final checkoutUrl = result['checkout_url'] as String?;
      final referenceId = result['reference_id'] as String?;


      if (checkoutUrl == null ||
          checkoutUrl.isEmpty ||
          referenceId == null ||
          referenceId.isEmpty) {
        throw Exception(
          'Checkout URL or order reference was not returned.',
        );
      }


      final prefs = await SharedPreferences.getInstance();
      final refs = prefs.getStringList('blvk_order_refs') ?? [];


      if (!refs.contains(referenceId)) {
        refs.add(referenceId);


        final saved = await prefs.setStringList(
          'blvk_order_refs',
          refs,
        );


        if (!saved) {
          throw Exception(
            'Order reference could not be saved on this device.',
          );
        }
      }


      final savedRefs =
          prefs.getStringList('blvk_order_refs') ?? [];


      debugPrint('BLVK saved order references: $savedRefs');


      if (!savedRefs.contains(referenceId)) {
        throw Exception(
          'Order reference was not saved. Please try again.',
        );
      }


      await _paymentService.openCheckout(checkoutUrl);


      if (!mounted) return;


      final order = ShopOrder(
        reference: referenceId,
        createdAt: DateTime.now(),
        items: items.map((item) {
          return OrderItem(
            name: item.product.name,
            price: item.product.price,
            quantity: item.quantity.clamp(1, maxQuantity),
            size: item.size,
          );
        }).toList(),
        total: items.fold(
          0,
          (sum, item) => sum + item.subtotal,
        ),
      );


      widget.onCheckout(order);
    } catch (error, stackTrace) {
      debugPrint('BLVK CHECKOUT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);


      if (!mounted) return;


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $error'),
          duration: const Duration(seconds: 10),
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
      appBar: AppBar(
        title: const Text('YOUR BAG'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 58,
                  ),
                  SizedBox(height: 12),
                  Text('Your bag is empty.'),
                ],
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
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
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(
                                      Icons.checkroom,
                                      color: Colors.black26,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                              ? () => _changeQuantity(
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
                                          onPressed: item.quantity <
                                                  maxQuantity
                                              ? () => _changeQuantity(
                                                    product.id,
                                                    item.quantity + 1,
                                                  )
                                              : null,
                                          icon: const Icon(Icons.add),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          visualDensity:
                                              VisualDensity.compact,
                                          onPressed: () =>
                                              _removeItem(product.id),
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
                          top: BorderSide(
                            color: Color(0xFF111111),
                            width: 1.5,
                          ),
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
                                    : () => _checkout(
                                          List<CartItem>.of(items),
                                        ),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF111111),
                                  foregroundColor: Colors.white,
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