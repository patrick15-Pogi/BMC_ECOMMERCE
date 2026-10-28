
class Product {
  final int id;
  final String name;
  final String category;
  final int price;
  final String imageAsset;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageAsset,
    required this.description,
  });
}

String peso(int amount) => '₱${amount.toStringAsFixed(2)}';
