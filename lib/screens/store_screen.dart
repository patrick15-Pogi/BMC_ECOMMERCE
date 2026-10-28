
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/products.dart';
import '../models/product.dart';
import 'orders_screen.dart';

final supabase = Supabase.instance.client;

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  Future<void> _buy(Product product) async {
    try {
      final result = await supabase.functions.invoke(
        'create-invoice',
        body: {
          'product_id': product.id,
          'quantity': 1,
        },
      );

      if (result.status < 200 || result.status >= 300) {
        throw Exception(result.data);
      }

      final data = result.data;

      if (data is! Map) {
        throw Exception('Invalid checkout response.');
      }

      final url = data['checkout_url'] as String?;
      final uri = url == null ? null : Uri.tryParse(url);

      if (uri == null || uri.scheme != 'https') {
        throw Exception('Invalid checkout URL.');
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception('Could not open checkout.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e'),
        ),
      );
    }
  }

  void _openOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrdersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BLVK',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Order History',
            onPressed: _openOrderHistory,
            icon: const Icon(Icons.receipt_long),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'EVERYDAY ESSENTIALS',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New arrivals',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          for (final product in products)
            _ProductCard(
              product: product,
              onBuy: () => _buy(product),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onBuy;

  const _ProductCard({
    required this.product,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              product.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 48,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(product.description),
                const SizedBox(height: 10),
                Text(
                  peso(product.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onBuy,
                    child: const Text('BUY NOW'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
