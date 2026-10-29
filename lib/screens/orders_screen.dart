
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final refs = prefs.getStringList('blvk_order_refs') ?? [];

    if (refs.isEmpty) return [];

    final response =
        await Supabase.instance.client.functions.invoke(
      'create-invoice',
      body: {
        'action': 'history',
        'reference_ids': refs,
      },
    );

    if (response.data is! Map) {
      throw Exception('Invalid response from the server.');
    }

    final result = Map<String, dynamic>.from(response.data as Map);

    if (result['error'] != null) {
      throw Exception(result['error'].toString());
    }

    final rawOrders = result['orders'];

    if (rawOrders is! List) return [];

    return rawOrders
        .whereType<Map>()
        .map((order) => Map<String, dynamic>.from(order))
        .toList();
  }

  Future<void> _refreshOrders() async {
    final future = _loadOrders();

    setState(() {
      _ordersFuture = future;
    });

    await future;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }

  Product? _findProduct(dynamic productId, String name) {
    final id = num.tryParse(
      productId?.toString().trim() ?? '',
    )?.toInt();

    if (id != null) {
      for (final product in products) {
        if (product.id == id) return product;
      }
    }

    final target = _normalize(name);

    if (target.isNotEmpty) {
      for (final product in products) {
        if (_normalize(product.name) == target) {
          return product;
        }
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _itemsForOrder(
    Map<String, dynamic> order,
  ) {
    final rawItems = order['items'] ?? order['order_items'];

    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _orderTitle(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) {
    final names = <String>[];

    for (final item in items) {
      final saved =
          (item['product_name'] ?? item['name'] ?? '')
              .toString()
              .trim();

      final name = _findProduct(
            item['product_id'],
            saved,
          )?.name ??
          saved;

      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }

    if (names.isEmpty) {
      final saved = (order['product_name'] ?? '').toString().trim();

      final name = _findProduct(
            order['product_id'],
            saved,
          )?.name ??
          saved;

      if (name.isNotEmpty) names.add(name);
    }

    if (names.isEmpty) return 'Order';
    if (names.length == 1) return names.first;

    return '${names.first} +${names.length - 1} more';
  }

  String _peso(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;

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
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final savedName =
        (item['product_name'] ?? item['name'] ?? 'Product')
            .toString();

    final product = _findProduct(
      item['product_id'],
      savedName,
    );

    final name = product?.name ?? savedName;
    final size = (item['size'] ?? '-').toString();

    final rawQuantity = item['quantity'];
    final quantity = rawQuantity is num
        ? rawQuantity.toInt()
        : int.tryParse(rawQuantity?.toString() ?? '') ?? 0;

    final rawPrice = item['unit_price'] ?? item['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    final rawSubtotal = item['subtotal'];
    final subtotal = rawSubtotal is num
        ? rawSubtotal.toDouble()
        : double.tryParse(rawSubtotal?.toString() ?? '') ??
            price * quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _productImage(product),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: $quantity',
                  style: const TextStyle(color: Colors.black54),
                ),
                if ((item['color'] ?? '').toString().isNotEmpty)
                  Text(
                    'Color: ${item['color']}',
                    style: const TextStyle(color: Colors.black54),
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
  }

  // CUSTOMER INFORMATION
  Widget _buildCustomerInfo(Map<String, dynamic> order) {
    final name = (order['customer_name'] ?? '').toString().trim();
    final email = (order['customer_email'] ?? '').toString().trim();
    final phone = (order['customer_phone'] ?? '').toString().trim();
    final address = (order['shipping_address'] ?? '').toString().trim();
    final city = (order['shipping_city'] ?? '').toString().trim();
    final province =
        (order['shipping_province'] ?? '').toString().trim();
    final postal =
        (order['shipping_postal_code'] ?? '').toString().trim();
    final notes = (order['shipping_notes'] ?? '').toString().trim();

    final fullAddress = [
      address,
      city,
      province,
      postal,
    ].where((part) => part.isNotEmpty).join(', ');

    Widget infoRow(IconData icon, String label, String value) {
      if (value.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: Colors.black54),
            const SizedBox(width: 9),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 19),
              SizedBox(width: 8),
              Text(
                'CUSTOMER INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          infoRow(Icons.person_outline, 'Customer',
              name.isEmpty ? 'N/A' : name),
          infoRow(Icons.email_outlined, 'Email', email),
          infoRow(Icons.phone_outlined, 'Contact', phone),
          infoRow(Icons.location_on_outlined, 'Address',
              fullAddress),
          infoRow(Icons.notes_outlined, 'Delivery notes', notes),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = _itemsForOrder(order);

    final status = (
      order['payment_status'] ?? order['status'] ?? 'PENDING'
    ).toString();

    final orderNumber = (
      order['reference_id'] ?? order['order_number'] ?? ''
    ).toString();

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
          if (orderNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Order ID: $orderNumber',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 18),

          if (items.isEmpty)
            Row(
              children: [
                _productImage(
                  _findProduct(
                    order['product_id'],
                    (order['product_name'] ?? '').toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (order['product_name'] ?? 'No order items found')
                        .toString(),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            )
          else
            ...items.map(_buildOrderItem),

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
                _peso(order['amount'] ?? order['subtotal']),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CUSTOMER DETAILS APPEAR HERE
          _buildCustomerInfo(order),
        ],
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text('No orders yet on this device.'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _refreshOrders,
                      icon: const Icon(Icons.refresh),
                      label: const Text('REFRESH'),
                    ),
                  ],
                ),
              ),
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
                    return _buildOrderCard(orders[index]);
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
