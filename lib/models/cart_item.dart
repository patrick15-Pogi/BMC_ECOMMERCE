
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String size;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.size = 'Medium',
  });

  int get subtotal => product.price * quantity;
}
