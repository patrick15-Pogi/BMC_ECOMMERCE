import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/products.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../widgets/blvk_footer.dart';
import '../widgets/blvk_header.dart';
import '../widgets/category_filter.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';

  final Map<int, CartItem> cart = {};


  int get cartCount =>
      cart.values.fold(0, (sum, item) => sum + item.quantity);

  List<Product> get filteredProducts {
    return products.where((product) {
      final matchesCategory = selectedCategory == 'All' ||
          product.category == selectedCategory;

      final query = searchQuery.toLowerCase().trim();
      final matchesSearch = product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void addToCart(Product product, int quantity, String size) {
    setState(() {
      final existing = cart[product.id];

      if (existing != null && existing.size == size) {
        existing.quantity += quantity;
      } else {
        cart[product.id] = CartItem(
          product: product,
          quantity: quantity,
          size: size,
        );
      }
    });
  }

  void openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          onAddToCart: addToCart,
        ),
      ),
    );
  }

  
void openCart() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CartScreen(
        cart: cart,
        onQuantityChanged: (productId, quantity) {
          setState(() {
            if (cart.containsKey(productId)) {
              cart[productId]!.quantity = quantity;
            }
          });
        },
        onRemove: (productId) {
          setState(() => cart.remove(productId));
        },
        onCheckout: (order) {
          // Checkout is handled by Xendit in CartScreen.
          // Do not create a local demo order here.
          setState(() {
            cart.clear();
          });

          Navigator.pop(context);

          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text(
                'Checkout opened. Payment status will be verified by the server.',
              ),
            ),
          );
        },
      ),
    ),
  ).then((_) {
    if (mounted) setState(() {});
  });
}


  
void openOrders() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const OrdersScreen(),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final visibleProducts = filteredProducts;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // Light status bar icons because the header is black.
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            // Black header bar (stays on top while the page scrolls).
            Container(
              color: const Color(0xFF111111),
              child: SafeArea(
                bottom: false,
                child: BlvkHeader(
                  cartCount: cartCount,
                  onCart: openCart,
                  onOrders: openOrders,
                  onSearch: (value) {
                    setState(() => searchQuery = value);
                  },
                ),
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        child: CategoryFilter(
                          selected: selectedCategory,
                          onSelected: (category) {
                            setState(() => selectedCategory = category);
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.black26,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BUILT DIFFERENT.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'BLVK STREETWEAR COLLECTION',
                                style: TextStyle(
                                  color: Colors.white70,
                                  letterSpacing: 2,
                                  fontSize: 11,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Everyday essentials. Distinct identity.',
                                style: TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            const Text(
                              'THE COLLECTION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: Color(0xFF111111),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${visibleProducts.length} ITEMS',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (visibleProducts.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('No products found.'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(18),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = visibleProducts[index];

                              return ProductCard(
                                product: product,
                                onTap: () => openProduct(product),
                              );
                            },
                            childCount: visibleProducts.length,
                          ),
                          // 2 columns on phones, more columns on wide screens.
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.68,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 10, 18, 28),
                        child: BlvkFooter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}