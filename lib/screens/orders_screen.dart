import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../data/products.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final data = await Supabase.instance.client
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _refreshOrders() async {
    final future = _loadOrders();
    setState(() => _ordersFuture = future);
    await future;
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Finds the purchased product: by product ID first, then by exact name.
  /// Returns null when nothing matches (never guesses a different product).
  Product? _findProduct(dynamic productId, String name) {
    final id = num.tryParse(productId?.toString().trim() ?? '')?.toInt();

    if (id != null) {
      for (final product in products) {
        if (product.id == id) return product;
      }
    }

    final target = _normalize(name);
    if (target.isNotEmpty) {
      for (final product in products) {
        if (_normalize(product.name) == target) return product;
      }
    }

    return null;
  }

  /// Title shown at the top of an order card: the purchased product's name
  /// (plus "+N more" when the order has several items).
  String _orderTitle(Map<String, dynamic> order, List<Map<String, dynamic>> items) {
    final names = <String>[];

    for (final item in items) {
      final saved = (item['product_name'] ?? '').toString().trim();
      final name = _findProduct(item['product_id'], saved)?.name ?? saved;
      if (name.isNotEmpty) names.add(name);
    }

    if (names.isEmpty) {
      final saved = (order['product_name'] ?? '').toString().trim();
      final name = _findProduct(order['product_id'], saved)?.name ?? saved;
      if (name.isNotEmpty) names.add(name);
    }

    if (names.isEmpty) return 'Order';
    if (names.length == 1) return names.first;
    return '${names.first} +${names.length - 1} more';
  }

  String _peso(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return '₱${amount.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) return 'Date unavailable';

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'EXPIRED':
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _productImage(Product? product) {
    const placeholder = Center(
      child: Icon(
        Icons.checkroom,
        size: 35,
        color: Colors.black26,
      ),
    );

    return Container(
      width: 90,
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: product == null
          ? placeholder
          : Image.asset(
              product.imageAsset,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        title: const Text(
          'ORDER HISTORY',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: _refreshOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 45,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load order history.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshOrders,
                      child: const Text('TRY AGAIN'),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders yet.'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: RefreshIndicator(
                onRefresh: _refreshOrders,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    final items = List<Map<String, dynamic>>.from(
                      order['order_items'] ?? [],
                    );

                    final status =
                        (order['payment_status'] ?? 'PENDING')
                            .toString();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF171717),
                          width: 1.3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _orderTitle(order, items),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDate(order['created_at']),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 18),

                          if (items.isEmpty)
                            Builder(builder: (context) {
                              final fallbackName =
                                  (order['product_name'] ?? '').toString();
                              final fallbackProduct = _findProduct(
                                order['product_id'],
                                fallbackName,
                              );

                              return Row(
                                children: [
                                  _productImage(fallbackProduct),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      fallbackName.isEmpty
                                          ? 'No order items found'
                                          : fallbackName,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            })
                          else
                            ...items.map((item) {
                              final savedName =
                                  (item['product_name'] ?? 'Product')
                                      .toString();

                              final product = _findProduct(
                                item['product_id'],
                                savedName,
                              );

                              // Name from the products table (by product ID).
                              final name = product?.name ?? savedName;

                              final size =
                                  (item['size'] ?? '-').toString();

                              final quantity =
                                  (item['quantity'] as num?)?.toInt() ?? 0;

                              final subtotal = item['subtotal'] ??
                                  ((item['price'] as num? ?? 0) *
                                      quantity);

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 14,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _productImage(product),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Size: $size',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Quantity: $quantity',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _peso(subtotal),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                          const Divider(
                            color: Color(0xFFDADADA),
                            thickness: 1,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                _peso(order['amount']),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}