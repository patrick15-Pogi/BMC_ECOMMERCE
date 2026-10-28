
class OrderItem {
  final String name;
  final int price;
  final int quantity;
  final String size;

  const OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.size,
  });

  int get subtotal => price * quantity;
}

class ShopOrder {
  final String reference;
  final DateTime createdAt;
  final List<OrderItem> items;
  final int total;
  final String status;

  const ShopOrder({
    required this.reference,
    required this.createdAt,
    required this.items,
    required this.total,
    this.status = 'PENDING',
  });
}
